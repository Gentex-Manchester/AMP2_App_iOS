import Foundation
import Security

/// Keychain storage for the SQLCipher key: `WhenUnlockedThisDeviceOnly`, so it
/// never syncs to iCloud or leaves the device in a backup.
enum KeychainManager {
    private static let service = "com.gentex.ios.db.v2"
    private static let account = "sqlcipher_key"

    /// Replaces any stored key with a new random passphrase and returns it.
    static func generateAndStoreKey() throws -> String {
        let passphrase = try generatePassphrase()
        guard let data = passphrase.data(using: .utf8) else {
            throw DatabaseError.keychainError(
                underlying: NSError(domain: "KeychainManager", code: -1,
                                    userInfo: [NSLocalizedDescriptionKey: "Failed to encode passphrase as UTF-8"])
            )
        }

        deleteKey()

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw DatabaseError.keychainError(
                underlying: NSError(domain: NSOSStatusErrorDomain, code: Int(status),
                                    userInfo: [NSLocalizedDescriptionKey: "SecItemAdd failed with status \(status)"])
            )
        }

        return passphrase
    }

    static func retrieveKey() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return data
    }

    /// Safe to call when no key is stored.
    static func deleteKey() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Private

    private static func generatePassphrase() throws -> String {
        let byteCount = 48 // 64 Base64 characters
        var bytes = [UInt8](repeating: 0, count: byteCount)
        let status = SecRandomCopyBytes(kSecRandomDefault, byteCount, &bytes)
        guard status == errSecSuccess else {
            throw DatabaseError.keychainError(
                underlying: NSError(domain: NSOSStatusErrorDomain, code: Int(status),
                                    userInfo: [NSLocalizedDescriptionKey: "SecRandomCopyBytes failed with status \(status)"])
            )
        }
        // Drops +, / and = so the passphrase is alphanumeric.
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "")
            .replacingOccurrences(of: "/", with: "")
            .replacingOccurrences(of: "=", with: "")
    }
}
