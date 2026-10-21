import AppDependencies  // never `import SQLite`: that skips the SQLCipher trait (plaintext DB)

/// Typed columns plus the only raw SQL allowed in the app (DDL, migrations, versioning).
enum TeamSchema {
    // MARK: - Teams Table

    static let teams = Table("teams")
    static let id = Expression<Int64>("id")
    static let region = Expression<String>("region")
    static let rfChannel = Expression<Int>("rf_channel")
    static let securityKey = Expression<String>("security_key")
    static let customSecurityKey = Expression<String?>("custom_security_key")
    static let networkId = Expression<Int>("network_id")
    static let name = Expression<String>("name")
    static let isFavorited = Expression<Bool>("is_favorited")
    static let isLocked = Expression<Bool>("is_locked")

    // MARK: - Schema Versioning

    /// Bump with each new migration.
    static let currentVersion: Int = 2

    static let allDDL: [String] = [
        """
        CREATE TABLE IF NOT EXISTS teams (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            region TEXT NOT NULL,
            rf_channel INTEGER NOT NULL,
            security_key TEXT NOT NULL,
            custom_security_key TEXT,
            network_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            is_favorited INTEGER NOT NULL DEFAULT 0,
            is_locked INTEGER NOT NULL DEFAULT 0
        )
        """,
        """
        CREATE TABLE IF NOT EXISTS _schema_metadata (
            key TEXT PRIMARY KEY NOT NULL,
            value TEXT NOT NULL
        )
        """
    ]

    /// Keyed by target version. Version 1 is the initial schema.
    static let migrations: [Int: [String]] = [
        // v2: old builds stored "Victory"; Android and the headset docs say
        // "Victor".
        // NOCASE because the column has held several casings.
        2: [
            """
            UPDATE teams
            SET security_key = 'Victor'
            WHERE security_key COLLATE NOCASE = 'Victory'
            """
        ]
    ]

    static let selectVersionSQL: String =
        "SELECT value FROM _schema_metadata WHERE key = 'schema_version'"

    static func insertVersionSQL(for version: Int) -> String {
        "INSERT OR REPLACE INTO _schema_metadata (key, value) VALUES ('schema_version', '\(version)')"
    }
}
