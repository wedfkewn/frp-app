import Foundation

struct ServiceEndpoint: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String
    var host: String
    var port: Int
    var localPort: Int

    var remoteURL: URL? { URL(string: "http://\(host):\(port)") }
    var loopbackURL: URL? { URL(string: "http://127.0.0.1:\(localPort)") }

    func validate() throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw LocalBridgeError.invalidConfiguration("服务名称不能为空")
        }
        guard !host.isEmpty, host.count <= 253,
              host.range(of: "^[A-Za-z0-9][A-Za-z0-9.\\-]*$", options: .regularExpression) != nil,
              !host.contains("..") else {
            throw LocalBridgeError.invalidConfiguration("请输入合法 IP 或主机名（不包含协议与路径）")
        }
        guard (1...65535).contains(port), (1024...65535).contains(localPort) else {
            throw LocalBridgeError.invalidConfiguration("目标端口需为 1–65535，本地端口需为 1024–65535")
        }
    }
}

enum LocalBridgeError: LocalizedError {
    case invalidConfiguration(String)

    var errorDescription: String? {
        switch self {
        case .invalidConfiguration(let message): message
        }
    }
}
