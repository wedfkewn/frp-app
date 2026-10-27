import Foundation
import Security

enum KeychainSecret {
    private static let service = "com.localbridge.ios.vpn"
    private static let account = "ikev2.eap.password"

    static func saveVPNPassword(_ password: String) throws -> Data {
        guard let passwordData = password.data(using: .utf8), !passwordData.isEmpty else {
            throw LocalBridgeError.invalidConfiguration("VPN 密码不能为空")
        }
        let search: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let updated = SecItemUpdate(search as CFDictionary, [
            kSecValueData as String: passwordData
        ] as CFDictionary)
        if updated == errSecSuccess {
            guard let ref = existingVPNPasswordReference() else {
                throw LocalBridgeError.invalidConfiguration("无法读取密码引用")
            }
            return ref
        }
        guard updated == errSecItemNotFound else {
            throw LocalBridgeError.invalidConfiguration("Keychain 更新失败：\(updated)")
        }
        var data = search
        data[kSecValueData as String] = passwordData
        data[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        data[kSecReturnPersistentRef as String] = true
        var result: CFTypeRef?
        let status = SecItemAdd(data as CFDictionary, &result)
        guard status == errSecSuccess, let ref = result as? Data else {
            throw LocalBridgeError.invalidConfiguration("Keychain 写入失败：\(status)")
        }
        return ref
    }

    static func existingVPNPasswordReference() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnPersistentRef as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess else { return nil }
        return result as? Data
    }
}
