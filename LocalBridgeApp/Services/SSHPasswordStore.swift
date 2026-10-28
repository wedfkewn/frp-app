import Foundation
import Security

enum SSHPasswordStore {
    private static let service = "com.localbridge.ssh.password"
    private static let account = "ssh.login"

    static func save(_ password: String) throws {
        guard let bytes = password.data(using: .utf8), !bytes.isEmpty else {
            throw LocalBridgeError.invalidConfiguration("SSH 密码不能为空")
        }
        let match: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let updated = SecItemUpdate(match as CFDictionary, [kSecValueData as String: bytes] as CFDictionary)
        if updated == errSecSuccess { return }
        guard updated == errSecItemNotFound else {
            throw LocalBridgeError.invalidConfiguration("保存 SSH 密码失败：\(updated)")
        }
        var request = match
        request[kSecValueData as String] = bytes
        request[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let added = SecItemAdd(request as CFDictionary, nil)
        guard added == errSecSuccess else {
            throw LocalBridgeError.invalidConfiguration("写入 SSH 密码失败：\(added)")
        }
    }

    static func load() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let bytes = result as? Data else { return nil }
        return String(data: bytes, encoding: .utf8)
    }
}
