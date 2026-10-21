import Foundation
import AppDependencies

/// Typed CRUD for custom teams in the encrypted database.
final class TeamStore {

    // MARK: - Singleton

    static let shared = TeamStore()

    // MARK: - Properties

    private let db: Connection

    // MARK: - Init

    private init() {
        // `try!` on purpose: failing to open the encrypted DB is fatal.
        self.db = try! DatabaseManager.shared.getDatabase()
    }

    /// For tests. `connection` must already be open, keyed, and schema-ready.
    init(connection: Connection) {
        self.db = connection
    }

    // MARK: - CRUD

    /// Validates, rejects duplicates, and inserts. `team.id` is ignored; the
    /// returned copy carries the assigned one.
    func create(_ team: Team, in region: Region) throws -> Team {
        try validateOrThrow(team, in: region)

        if try isDuplicate(team) {
            throw DatabaseError.databaseOperationFailed(
                underlying: NSError(
                    domain: "TeamStore",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "A team with the same settings already exists."]
                )
            )
        }

        var teamToInsert = team
        teamToInsert.id = 0

        do {
            try db.run(TeamSchema.teams.insert(
                or: .fail,
                TeamSchema.region <- teamToInsert.region,
                TeamSchema.rfChannel <- teamToInsert.rfChannel,
                TeamSchema.securityKey <- teamToInsert.securityKey,
                TeamSchema.customSecurityKey <- teamToInsert.customSecurityKey,
                TeamSchema.networkId <- teamToInsert.networkId,
                TeamSchema.name <- teamToInsert.name,
                TeamSchema.isFavorited <- teamToInsert.isFavorited,
                TeamSchema.isLocked <- teamToInsert.isLocked
            ))
        } catch {
            throw DatabaseError.databaseOperationFailed(underlying: error)
        }

        let newId = db.lastInsertRowid
        var created = teamToInsert
        created.id = newId
        return created
    }

    func fetch(_ id: Int64) throws -> Team? {
        do {
            guard let row = try db.pluck(TeamSchema.teams.filter(TeamSchema.id == id)) else {
                return nil
            }
            return try mapRow(row)
        } catch {
            throw DatabaseError.databaseOperationFailed(underlying: error)
        }
    }

    /// Ordered by name.
    func fetchAll() throws -> [Team] {
        do {
            let rows = try db.prepare(TeamSchema.teams.order(TeamSchema.name.asc))
            return try rows.map { try mapRow($0) }
        } catch {
            throw DatabaseError.databaseOperationFailed(underlying: error)
        }
    }

    /// Ordered by name.
    func fetchFavorites() throws -> [Team] {
        do {
            let rows = try db.prepare(
                TeamSchema.teams
                    .filter(TeamSchema.isFavorited == true)
                    .order(TeamSchema.name.asc)
            )
            return try rows.map { try mapRow($0) }
        } catch {
            throw DatabaseError.databaseOperationFailed(underlying: error)
        }
    }

    func count() throws -> Int {
        do {
            return try db.scalar(TeamSchema.teams.count)
        } catch {
            throw DatabaseError.databaseOperationFailed(underlying: error)
        }
    }

    /// Validates, rejects duplicates, and updates the row matching `team.id`.
    /// Throws if that row does not exist.
    func update(_ team: Team, in region: Region) throws -> Team {
        try validateOrThrow(team, in: region)

        if try isDuplicate(team, excludingId: team.id) {
            throw DatabaseError.databaseOperationFailed(
                underlying: NSError(
                    domain: "TeamStore",
                    code: 2,
                    userInfo: [NSLocalizedDescriptionKey: "Another team with the same settings already exists."]
                )
            )
        }

        guard try db.pluck(TeamSchema.teams.filter(TeamSchema.id == team.id)) != nil else {
            throw DatabaseError.databaseOperationFailed(
                underlying: NSError(
                    domain: "TeamStore",
                    code: 3,
                    userInfo: [NSLocalizedDescriptionKey: "Team with id \(team.id) not found."]
                )
            )
        }

        do {
            try db.run(
                TeamSchema.teams
                    .filter(TeamSchema.id == team.id)
                    .update(
                        TeamSchema.region <- team.region,
                        TeamSchema.rfChannel <- team.rfChannel,
                        TeamSchema.securityKey <- team.securityKey,
                        TeamSchema.customSecurityKey <- team.customSecurityKey,
                        TeamSchema.networkId <- team.networkId,
                        TeamSchema.name <- team.name,
                        TeamSchema.isFavorited <- team.isFavorited,
                        TeamSchema.isLocked <- team.isLocked
                    )
            )
        } catch {
            throw DatabaseError.databaseOperationFailed(underlying: error)
        }

        return team
    }

    /// No-op if `id` does not exist.
    func delete(_ id: Int64) throws {
        do {
            try db.run(TeamSchema.teams.filter(TeamSchema.id == id).delete())
        } catch {
            throw DatabaseError.databaseOperationFailed(underlying: error)
        }
    }

    func deleteAll() throws {
        do {
            try db.run(TeamSchema.teams.delete())
        } catch {
            throw DatabaseError.databaseOperationFailed(underlying: error)
        }
    }

    // MARK: - Toggles

    /// Throws if the team does not exist.
    func toggleFavorite(_ id: Int64) throws -> Team {
        guard var team = try fetch(id) else {
            throw DatabaseError.databaseOperationFailed(
                underlying: NSError(
                    domain: "TeamStore",
                    code: 4,
                    userInfo: [NSLocalizedDescriptionKey: "Team with id \(id) not found."]
                )
            )
        }
        team.isFavorited.toggle()

        do {
            try db.run(
                TeamSchema.teams
                    .filter(TeamSchema.id == id)
                    .update(TeamSchema.isFavorited <- team.isFavorited)
            )
        } catch {
            throw DatabaseError.databaseOperationFailed(underlying: error)
        }

        return team
    }

    /// Throws if the team does not exist.
    func toggleLocked(_ id: Int64) throws -> Team {
        guard var team = try fetch(id) else {
            throw DatabaseError.databaseOperationFailed(
                underlying: NSError(
                    domain: "TeamStore",
                    code: 5,
                    userInfo: [NSLocalizedDescriptionKey: "Team with id \(id) not found."]
                )
            )
        }
        team.isLocked.toggle()

        do {
            try db.run(
                TeamSchema.teams
                    .filter(TeamSchema.id == id)
                    .update(TeamSchema.isLocked <- team.isLocked)
            )
        } catch {
            throw DatabaseError.databaseOperationFailed(underlying: error)
        }

        return team
    }

    // MARK: - Duplicate Detection

    /// Matches on region, channel, security key, network ID, and name.
    func findDuplicate(of team: Team, excludingId: Int64? = nil) throws -> Team? {
        do {
            var query = TeamSchema.teams.filter(
                TeamSchema.region == team.region
                    && TeamSchema.rfChannel == team.rfChannel
                    && TeamSchema.securityKey == team.securityKey
                    && TeamSchema.networkId == team.networkId
                    && TeamSchema.name == team.name
            )
            if let excludeId = excludingId {
                query = query.filter(TeamSchema.id != excludeId)
            }
            guard let row = try db.pluck(query) else {
                return nil
            }
            return try mapRow(row)
        } catch {
            throw DatabaseError.databaseOperationFailed(underlying: error)
        }
    }

    func isDuplicate(_ team: Team, excludingId: Int64? = nil) throws -> Bool {
        return try findDuplicate(of: team, excludingId: excludingId) != nil
    }

    // MARK: - Row Mapping

    private func mapRow(_ row: Row) throws -> Team {
        return Team(
            id: row[TeamSchema.id],
            region: row[TeamSchema.region],
            rfChannel: row[TeamSchema.rfChannel],
            securityKey: row[TeamSchema.securityKey],
            customSecurityKey: row[TeamSchema.customSecurityKey],
            networkId: row[TeamSchema.networkId],
            name: row[TeamSchema.name],
            isFavorited: row[TeamSchema.isFavorited],
            isLocked: row[TeamSchema.isLocked]
        )
    }

    // MARK: - Helpers

    /// Throws every failure message, joined.
    private func validateOrThrow(_ team: Team, in region: Region) throws {
        let results = TeamValidation.validateTeam(team, in: region)
        guard TeamValidation.allPassed(results) else {
            let message = results
                .compactMap { result -> String? in
                    switch result {
                    case .valid: return nil
                    case .invalid(let msg): return msg
                    case .customSecurityKeyNotSupported:
                        return "Custom security key is not supported in this phase."
                    }
                }
                .joined(separator: " ")
            throw DatabaseError.databaseOperationFailed(
                underlying: NSError(
                    domain: "TeamStore.Validation",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: message]
                )
            )
        }
    }
}
