import Foundation
import Combine
import Network

enum LoopbackPhase: Equatable {
    case stopped
    case starting
    case ready
}

/// Foreground-only TCP relay. Binds to 127.0.0.1 and reports actual listener readiness.
@MainActor
final class LoopbackProxy: ObservableObject {
    @Published private(set) var activeServiceID: UUID?
    @Published private(set) var phase: LoopbackPhase = .stopped
    @Published var errorMessage: String?

    private let queue = DispatchQueue(label: "localbridge.loopback", qos: .userInitiated)
    private var listener: NWListener?
    private var sessions: [UUID: RelaySession] = [:]

    func start(_ service: ServiceEndpoint) {
        stop()
        do {
            try service.validate()
            guard let local = NWEndpoint.Port(rawValue: UInt16(service.localPort)),
                  let bindIP = IPv4Address("127.0.0.1") else {
                throw LocalBridgeError.invalidConfiguration("本地端口无效")
            }

            let parameters = NWParameters.tcp
            parameters.requiredLocalEndpoint = .hostPort(host: .ipv4(bindIP), port: local)
            let nextListener = try NWListener(using: parameters)
            listener = nextListener
            activeServiceID = service.id
            phase = .starting

            nextListener.stateUpdateHandler = { [weak self, weak nextListener] state in
                Task { @MainActor [weak self, weak nextListener] in
                    guard let self, let nextListener, self.listener === nextListener else { return }
                    switch state {
                    case .ready:
                        self.phase = .ready
                    case .failed(let error):
                        self.errorMessage = "本地监听失败：\(error.localizedDescription)"
                        self.stop()
                    case .cancelled:
                        self.stop()
                    default:
                        break
                    }
                }
            }
            nextListener.newConnectionHandler = { [weak self, weak nextListener] inbound in
                Task { @MainActor [weak self, weak nextListener] in
                    guard let self, self.listener === nextListener, self.phase == .ready else {
                        inbound.cancel()
                        return
                    }
                    self.accept(inbound, service: service)
                }
            }
            nextListener.start(queue: queue)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func stop() {
        let old = listener
        listener = nil
        activeServiceID = nil
        phase = .stopped
        old?.cancel()
        for session in sessions.values { session.cancel() }
        sessions.removeAll()
    }

    private func accept(_ inbound: NWConnection, service: ServiceEndpoint) {
        guard activeServiceID == service.id,
              let port = NWEndpoint.Port(rawValue: UInt16(service.port)) else {
            inbound.cancel()
            return
        }
        let session = RelaySession(
            inbound: inbound,
            outbound: NWConnection(host: .init(service.host), port: port, using: .tcp),
            queue: queue
        )
        let id = UUID()
        sessions[id] = session
        session.onClosed = { [weak self] in
            Task { @MainActor [weak self] in self?.sessions.removeValue(forKey: id) }
        }
        session.start()
    }
}

private final class RelaySession {
    private let inbound: NWConnection
    private let outbound: NWConnection
    private let queue: DispatchQueue
    private var closed = false
    var onClosed: (() -> Void)?

    init(inbound: NWConnection, outbound: NWConnection, queue: DispatchQueue) {
        self.inbound = inbound
        self.outbound = outbound
        self.queue = queue
    }

    func start() {
        inbound.stateUpdateHandler = { [weak self] state in
            if case .failed = state { self?.cancel() }
        }
        outbound.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            switch state {
            case .ready:
                self.pipe(from: self.inbound, to: self.outbound)
                self.pipe(from: self.outbound, to: self.inbound)
            case .failed, .cancelled:
                self.cancel()
            default: break
            }
        }
        inbound.start(queue: queue)
        outbound.start(queue: queue)
    }

    private func pipe(from source: NWConnection, to destination: NWConnection) {
        source.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, complete, error in
            guard let self, !self.closed else { return }
            if error != nil || complete { self.cancel(); return }
            guard let data, !data.isEmpty else {
                self.pipe(from: source, to: destination)
                return
            }
            destination.send(content: data, completion: .contentProcessed { [weak self] error in
                guard let self, !self.closed else { return }
                if error != nil { self.cancel() }
                else { self.pipe(from: source, to: destination) }
            })
        }
    }

    func cancel() {
        guard !closed else { return }
        closed = true
        inbound.cancel()
        outbound.cancel()
        onClosed?()
        onClosed = nil
    }
}
