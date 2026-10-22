//
//  QRPayload.swift
//  AMP2_App_iOS
//
//  Versioned JSON payload for sharing a team by QR between iOS devices.
//  Android uses a different payload (docs/qr-contract.md §4).
//

import Foundation

// MARK: - QR Payload

/// Version-1 team-sharing payload. JSON shape and field contract are in
/// docs/qr-contract.md; `version` is always present and checked first.
struct QRPayload: Codable, Equatable {
    /// Must be 1 for this phase.
    let version: Int

    let team: QRTeamPayload

    // MARK: - Nested Team Payload

    /// `customSecurityKey` is reserved and omitted in version 1.
    struct QRTeamPayload: Codable, Equatable {
        let region: String
        let rfChannel: Int
        let securityKey: String
        let networkId: Int
        let name: String
    }

    // MARK: - Init

    init(version: Int, team: QRTeamPayload) {
        self.version = version
        self.team = team
    }

    init(team source: Team) {
        self.version = 1
        self.team = QRTeamPayload(
            region: source.region,
            rfChannel: source.rfChannel,
            securityKey: source.securityKey,
            networkId: source.networkId,
            name: source.name
        )
    }

    // MARK: - Encode / Decode

    /// Deterministic JSON (sorted keys).
    func encode() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(self)
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw QRPayloadError.encodingFailed
        }
        return jsonString
    }

    /// Throws `unsupportedVersion` for anything but version 1.
    static func decode(from jsonString: String) throws -> QRPayload {
        guard let data = jsonString.data(using: .utf8) else {
            throw QRPayloadError.invalidJSON
        }
        let decoder = JSONDecoder()
        let payload = try decoder.decode(QRPayload.self, from: data)

        guard payload.version == 1 else {
            throw QRPayloadError.unsupportedVersion(payload.version)
        }

        return payload
    }

    // MARK: - Conversion

    /// `id` 0 means unsaved.
    func toTeam(id: Int64 = 0) -> Team {
        Team(
            id: id,
            region: team.region,
            rfChannel: team.rfChannel,
            securityKey: team.securityKey,
            customSecurityKey: nil,
            networkId: team.networkId,
            name: team.name.trimmingCharacters(in: .whitespacesAndNewlines),
            isFavorited: false,
            isLocked: false
        )
    }

    // MARK: - Full Pipeline Convenience

    /// Team → JSON → AES-GCM → URL-safe Base64, ready to render as a QR.
    static func exportTeam(_ team: Team) throws -> String {
        let payload = QRPayload(team: team)
        let json = try payload.encode()
        return try QRCodeCrypto.encrypt(json)
    }

    /// Reverses `exportTeam(_:)`. Returns a validated, unsaved `Team` (`id` 0).
    static func importTeam(from base64String: String) throws -> Team {
        let json = try QRCodeCrypto.decrypt(base64String)
        let payload = try QRPayload.decode(from: json)
        let team = payload.toTeam()

        // Channels are 1–5 in every region, so any region validates the same.
        let results = TeamValidation.validateTeam(team, in: .northAmerica)
        if let firstError = results.first(where: { $0 != .valid }) {
            switch firstError {
            case .invalid(let msg):
                throw QRPayloadError.validationFailed(msg)
            case .customSecurityKeyNotSupported:
                throw QRPayloadError.validationFailed("Custom security key is not supported.")
            case .valid:
                break
            }
        }

        return team
    }
}

// MARK: - QR Payload Errors

enum QRPayloadError: Error, Equatable {
    case invalidJSON
    case unsupportedVersion(Int)
    case missingField(String)
    case encodingFailed
    case validationFailed(String)
}

extension QRPayloadError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidJSON:
            return "QR code contains invalid data."
        case .unsupportedVersion(let v):
            return "QR code version \(v) is not supported. Please update the app."
        case .missingField(let field):
            return "QR code is missing required field: \"\(field)\"."
        case .encodingFailed:
            return "Failed to encode team data for QR sharing."
        case .validationFailed(let reason):
            return "Imported team is invalid: \(reason)"
        }
    }
}
