import Foundation

enum DatabaseError: LocalizedError {
    case keychainError(underlying: Error)
    case databaseOpenError(underlying: Error)
    case encryptionNotActive(detail: String)
    case keyNotFound
    case databaseOperationFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .keychainError(let error):
            return "Keychain operation failed: \(error.localizedDescription)"
        case .databaseOpenError(let error):
            return "Unable to open database: \(error.localizedDescription)"
        case .encryptionNotActive(let detail):
            return "Database encryption is not active: \(detail)"
        case .keyNotFound:
            return "Database encryption key not found in Keychain."
        case .databaseOperationFailed(let error):
            return "Database operation failed: \(error.localizedDescription)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .keychainError:
            return "Verify Keychain entitlements are properly configured."
        case .databaseOpenError:
            return "The database file may be corrupt. Try deleting and re-launching the app."
        case .encryptionNotActive:
            return "The database was opened without SQLCipher encryption. Check that the SQLCipher trait is enabled in the AppDependencies package."
        case .keyNotFound:
            return "Re-launch the app to regenerate the database key."
        case .databaseOperationFailed:
            return nil
        }
    }
}
