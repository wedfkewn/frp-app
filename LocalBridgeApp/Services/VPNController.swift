import Foundation
import Combine
import NetworkExtension

@MainActor
final class VPNController: ObservableObject {
    @Published private(set) var status: NEVPNStatus = .invalid
    @Published var profile: VPNProfile = VPNProfile() { didSet { saveProfile() } }
    @Published var errorMessage: String?

    private let manager = NEVPNManager.shared()
    private let profileKey = "localbridge.vpn.profile.v1"
    private var observer: NSObjectProtocol?

    init() {
        if let data = UserDefaults.standard.data(forKey: profileKey),
           let saved = try? JSONDecoder().decode(VPNProfile.self, from: data) {
            profile = saved
        }
        observer = NotificationCenter.default.addObserver(
            forName: .NEVPNStatusDidChange, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.refreshStatus() }
        }
    }

    deinit {
        if let observer { NotificationCenter.default.removeObserver(observer) }
    }

    var statusText: String {
        switch status {
        case .connected: "已连接"
        case .connecting: "连接中"
        case .reasserting: "重新连接中"
        case .disconnecting: "断开中"
        case .disconnected: "未连接"
        case .invalid: "未配置"
        @unknown default: "未知"
        }
    }
    var connected: Bool { status == .connected }

    func reloadStatus() async {
        do {
            try await load()
            refreshStatus()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func configureAndConnect(password: String) async {
        do {
            try profile.validate()
            let passwordRef: Data
            if !password.isEmpty {
                passwordRef = try KeychainSecret.saveVPNPassword(password)
            } else if let saved = KeychainSecret.existingVPNPasswordReference() {
                passwordRef = saved
            } else {
                throw LocalBridgeError.invalidConfiguration("首次配置必须输入 VPN 密码")
            }
            try await load()
            let proto = NEVPNProtocolIKEv2()
            proto.serverAddress = profile.server
            proto.remoteIdentifier = profile.remoteIdentifier
            proto.username = profile.username
            proto.passwordReference = passwordRef
            proto.authenticationMethod = .none
            proto.useExtendedAuthentication = true
            proto.disconnectOnSleep = false
            manager.protocolConfiguration = proto
            manager.localizedDescription = "LocalBridge IKEv2"
            manager.isEnabled = true
            try await save()
            try await load()
            try manager.connection.startVPNTunnel()
            refreshStatus()
        } catch {
            errorMessage = error.localizedDescription
            refreshStatus()
        }
    }

    func disconnect() {
        manager.connection.stopVPNTunnel()
        refreshStatus()
    }

    private func refreshStatus() { status = manager.connection.status }

    private func saveProfile() {
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: profileKey)
        }
    }

    private func load() async throws {
        try await withCheckedThrowingContinuation { (c: CheckedContinuation<Void, Error>) in
            manager.loadFromPreferences { error in
                if let error { c.resume(throwing: error) } else { c.resume() }
            }
        }
    }

    private func save() async throws {
        try await withCheckedThrowingContinuation { (c: CheckedContinuation<Void, Error>) in
            manager.saveToPreferences { error in
                if let error { c.resume(throwing: error) } else { c.resume() }
            }
        }
    }
}
