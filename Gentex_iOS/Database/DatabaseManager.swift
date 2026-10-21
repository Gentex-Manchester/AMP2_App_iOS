import Foundation
import AppDependencies

/// Opens the SQLCipher database lazily, keyed from the Keychain.
final class DatabaseManager {

    // MARK: - Singleton

    static let shared = DatabaseManager()

    // MARK: - Properties

    private var connection: Connection?
    private let dbDirectory: URL
    private let dbURL: URL

    // MARK: - Init

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        dbDirectory = appSupport.appendingPathComponent("Gentex", isDirectory: true)
        dbURL = dbDirectory.appendingPathComponent("gentex.db")
    }

    // MARK: - Public API

    func getDatabase() throws -> Connection {
        if let existing = connection {
            return existing
        }
        let db = try openDatabase()
        connection = db
        return db
    }

    func close() {
        connection = nil
    }

    // MARK: - Database Lifecycle

    /// If encryption can't be verified, wipes the DB and key and retries once.
    private func openDatabase() throws -> Connection {
        do {
            return try openDatabaseAttempt()
        } catch let error as DatabaseError {
            if case .encryptionNotActive = error {
                return try openDatabaseClean()
            }
            throw error
        }
    }

    private func openDatabaseAttempt() throws -> Connection {
        try FileManager.default.createDirectory(at: dbDirectory, withIntermediateDirectories: true)

        let passphrase: String
        if let existingKeyData = KeychainManager.retrieveKey(),
           let existingPassphrase = String(data: existingKeyData, encoding: .utf8) {
            passphrase = existingPassphrase
        } else {
            passphrase = try KeychainManager.generateAndStoreKey()
        }

        #if DEBUG
        // For opening the DB in DB Browser for SQLite (SQLCipher). Debug only.
        print("🔓 [DEBUG] SQLCipher DB path: \(dbURL.path)")
        print("🔓 [DEBUG] SQLCipher passphrase: \(passphrase)")
        #endif

        let db: Connection
        do {
            db = try Connection(dbURL.absoluteString)
        } catch {
            throw DatabaseError.databaseOpenError(underlying: error)
        }

        // SQLCipher requires the key before any other statement.
        do {
            try db.key(passphrase)
        } catch {
            throw DatabaseError.databaseOpenError(underlying: error)
        }

        try verifyEncryption(db: db)

        try createSchema(db: db)

        try Self.runMigrations(db: db)

        return db
    }

    /// Deletes the DB files and Keychain key, then reopens with a fresh key.
    private func openDatabaseClean() throws -> Connection {
        connection = nil

        let walURL = dbURL.appendingPathExtension("wal")
        let shmURL = dbURL.appendingPathExtension("shm")
        for url in [dbURL, walURL, shmURL] {
            try? FileManager.default.removeItem(at: url)
        }

        KeychainManager.deleteKey()
        _ = try KeychainManager.generateAndStoreKey()

        return try openDatabaseAttempt()
    }

    // MARK: - Encryption Verification

    /// Fails if `cipher_version` is empty (plain SQLite) or a write/read-back
    /// round trip fails. The pragma returns e.g. `"4.16.0 community"`, with no
    /// "sqlcipher" in it, so non-empty is the check.
    private func verifyEncryption(db: Connection) throws {
        let cipherVersion: String? = try? db.scalar("PRAGMA cipher_version") as? String
        guard let version = cipherVersion, !version.isEmpty else {
            throw DatabaseError.encryptionNotActive(
                detail: "PRAGMA cipher_version returned empty or nil. " +
                         "SQLCipher is not active. Verify the SQLCipher trait is enabled in AppDependencies."
            )
        }

        do {
            try db.run("CREATE TABLE IF NOT EXISTS _encryption_check (value TEXT)")
            try db.run("DELETE FROM _encryption_check")
            try db.run("INSERT INTO _encryption_check (value) VALUES ('sqlcipher_ok')")
            let result: String? = try db.scalar("SELECT value FROM _encryption_check LIMIT 1") as? String
            guard result == "sqlcipher_ok" else {
                throw DatabaseError.encryptionNotActive(
                    detail: "Write/read-back sanity check failed. " +
                             "Expected 'sqlcipher_ok', got '\(result ?? "nil")'."
                )
            }
            try db.run("DROP TABLE _encryption_check")
        } catch let error as DatabaseError {
            throw error
        } catch {
            throw DatabaseError.encryptionNotActive(
                detail: "Write/read-back sanity check threw: \(error.localizedDescription)"
            )
        }
    }

    // MARK: - Schema

    /// Idempotent.
    private func createSchema(db: Connection) throws {
        do {
            for ddl in TeamSchema.allDDL {
                try db.run(ddl)
            }
        } catch {
            throw DatabaseError.databaseOperationFailed(underlying: error)
        }
    }

    /// Migrates from the stored version up to `TeamSchema.currentVersion`.
    /// Static so tests can run it on an in-memory DB; the singleton opens the real file.
    static func runMigrations(db: Connection) throws {
        let storedVersion = try currentSchemaVersion(db: db)

        guard storedVersion < TeamSchema.currentVersion else { return }

        for version in (storedVersion + 1)...TeamSchema.currentVersion {
            if let statements = TeamSchema.migrations[version] {
                for sql in statements {
                    do {
                        try db.run(sql)
                    } catch {
                        throw DatabaseError.databaseOperationFailed(underlying: error)
                    }
                }
            }
            try setSchemaVersion(version, db: db)
        }
    }

    /// 0 when no version has been written yet.
    static func currentSchemaVersion(db: Connection) throws -> Int {
        do {
            if let raw: String = try db.scalar(TeamSchema.selectVersionSQL) as? String,
               let version = Int(raw) {
                return version
            }
            return 0
        } catch {
            // Table may not exist yet.
            return 0
        }
    }

    static func setSchemaVersion(_ version: Int, db: Connection) throws {
        do {
            try db.run(TeamSchema.insertVersionSQL(for: version))
        } catch {
            throw DatabaseError.databaseOperationFailed(underlying: error)
        }
    }
}
