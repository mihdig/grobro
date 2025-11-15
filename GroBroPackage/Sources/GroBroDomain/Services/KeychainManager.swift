import Foundation
import Security

/// Lightweight wrapper around Keychain for storing sensitive credentials.
public struct KeychainManager {

    public enum KeychainError: Error {
        case unexpectedStatus(OSStatus)
        case invalidData
    }

    private let service: String

    public init(service: String) {
        self.service = service
    }

    public func store(password: String, account: String) throws {
        let data = Data(password.utf8)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]

        let status: OSStatus
        if try retrievePassword(account: account) != nil {
            status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        } else {
            var fullQuery = query
            attributes.forEach { fullQuery[$0.key] = $0.value }
            status = SecItemAdd(fullQuery as CFDictionary, nil)
        }

        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    public func retrievePassword(account: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.unexpectedStatus(status)
        }

        return string
    }

    public func deletePassword(account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
}

