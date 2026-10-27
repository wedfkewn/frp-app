import Foundation

struct VPNProfile: Codable {
    var server = ""
    var remoteIdentifier = ""
    var username = ""

    func validate() throws {
        guard [server, remoteIdentifier, username].allSatisfy({
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }) else {
            throw LocalBridgeError.invalidConfiguration("请填写 VPN 服务器、证书标识及用户名")
        }
        guard !server.contains("://"), !server.contains("/"),
              !remoteIdentifier.contains("://") else {
            throw LocalBridgeError.invalidConfiguration("VPN 服务器与证书标识不能包含协议或路径")
        }
    }
}
