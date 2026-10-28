import Foundation
import Combine
import Citadel
import NIO
import NIOSSH

/// Four local 127.0.0.1 listeners connected to the same authenticated SSH transport.
/// Local TCP forwarding is only reliable while iOS keeps this application running.
@MainActor
final class SSHTunnelManager: ObservableObject {
    enum Phase: Equatable {
        case disconnected, connecting, connected
    }

    @Published private(set) var phase: Phase = .disconnected
    @Published var profile: SSHProfile = .init() { didSet { persist() } }
    @Published var errorMessage: String?

    private let key = "localbridge.ssh.profile.v1"
    private var ssh: SSHClient?
    private var listeners: [Channel] = []

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let profile = try? JSONDecoder().decode(SSHProfile.self, from: data) {
            self.profile = profile
        }
    }

    var connected: Bool { phase == .connected }
    var connecting: Bool { phase == .connecting }
    var statusText: String {
        switch phase {
        case .disconnected: "SSH 未连接"
        case .connecting: "正在建立加密连接…"
        case .connected: "4 个网页转发已启动"
        }
    }

    func connect(password input: String) async {
        guard phase == .disconnected else { return }
        phase = .connecting
        errorMessage = nil
        do {
            try profile.validate()
            if !input.isEmpty { try SSHPasswordStore.save(input) }
            guard let password = SSHPasswordStore.load() else {
                throw LocalBridgeError.invalidConfiguration("请输入 SSH 登录密码")
            }
            let trustedKey = try NIOSSHPublicKey(openSSHPublicKey: profile.trustedHostKey.trimmingCharacters(in: .whitespacesAndNewlines))
            let username = profile.username
            let settings = SSHClientSettings(
                host: profile.host,
                port: profile.port,
                authenticationMethod: { .passwordBased(username: username, password: password) },
                hostKeyValidator: .trustedKeys(Set([trustedKey]))
            )
            let connection = try await SSHClient.connect(to: settings)
            ssh = connection

            // Close listener resources if any one of the four ports cannot be bound.
            var opened: [Channel] = []
            do {
                for shortcut in TunnelShortcut.presets {
                    let listener = try await ServerBootstrap(group: connection.eventLoop)
                        .serverChannelOption(ChannelOptions.backlog, value: 128)
                        .childChannelInitializer { inbound in
                            let result = inbound.eventLoop.makePromise(of: Void.self)
                            Task {
                                do {
                                    let address = try SocketAddress(ipAddress: "127.0.0.1", port: shortcut.port)
                                    let remote = try await connection.createDirectTCPIPChannel(
                                        using: .init(
                                            targetHost: "127.0.0.1",
                                            targetPort: shortcut.port,
                                            originatorAddress: address
                                        )
                                    ) { sshChannel in
                                        sshChannel.pipeline.addHandler(SSHForwardingRelay(peer: inbound))
                                    }
                                    try await inbound.pipeline.addHandler(SSHForwardingRelay(peer: remote)).get()
                                    result.succeed(())
                                } catch {
                                    result.fail(error)
                                }
                            }
                            return result.futureResult
                        }
                        .bind(host: "127.0.0.1", port: shortcut.port)
                        .get()
                    opened.append(listener)
                }
                listeners = opened
                phase = .connected
            } catch {
                for channel in opened { channel.close(promise: nil) }
                try? await connection.close()
                ssh = nil
                throw error
            }
        } catch {
            errorMessage = "SSH 连接失败：\(error.localizedDescription)"
            phase = .disconnected
        }
    }

    func disconnect() {
        let connection = ssh
        ssh = nil
        for listener in listeners { listener.close(promise: nil) }
        listeners = []
        phase = .disconnected
        if let connection {
            Task { try? await connection.close() }
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

/// Bidirectional ByteBuffer bridge between local sockets and SSH direct-tcpip channels.
private final class SSHForwardingRelay: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer
    private let peer: Channel

    init(peer: Channel) { self.peer = peer }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        peer.writeAndFlush(unwrapInboundIn(data), promise: nil)
    }

    func channelInactive(context: ChannelHandlerContext) {
        peer.close(promise: nil)
        context.fireChannelInactive()
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        context.close(promise: nil)
        peer.close(promise: nil)
    }
}
