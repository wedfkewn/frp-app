import Foundation

struct SSHProfile: Codable {
    var host: String = ""
    var port: Int = 22
    var username: String = "ubuntu"
    // OpenSSH-formatted SERVER public host key, never a private key.
    var trustedHostKey: String = ""

    func validate() throws {
        guard host.range(of: #"^[A-Za-z0-9][A-Za-z0-9.-]{0,252}$"#, options: .regularExpression) != nil else {
            throw LocalBridgeError.invalidConfiguration("请输入正确的服务器 IP 或域名")
        }
        guard (1...65535).contains(port), !username.isEmpty else {
            throw LocalBridgeError.invalidConfiguration("检查 SSH 用户名与端口")
        }
        guard trustedHostKey.hasPrefix("ssh-ed25519 ") || trustedHostKey.hasPrefix("ecdsa-sha2-") else {
            throw LocalBridgeError.invalidConfiguration("首次连接需要粘贴服务器 SSH 主机公钥并核对来源，不能跳过身份验证")
        }
    }
}

struct TunnelShortcut: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let symbol: String
    let port: Int

    var url: URL { URL(string: "http://127.0.0.1:\(port)")! }

    static let presets: [TunnelShortcut] = [
        .init(id: "qq", title: "QQ 扫码桌面", subtitle: "远程扫码页面", symbol: "qrcode.viewfinder", port: 6081),
        .init(id: "snow", title: "SnowLuma WebUI", subtitle: "机器人控制界面", symbol: "snowflake", port: 5099),
        .init(id: "dsh", title: "DSH 网页", subtitle: "智能助手网页", symbol: "message", port: 3080),
        .init(id: "bili", title: "Bili 代理 UI", subtitle: "代理服务管理", symbol: "play.rectangle", port: 18787)
    ]
}
