//
//  AMP2_App_iOSTests.swift
//  AMP2_App_iOSTests
//
//  Created by aaron stockdale on 6/18/26.
//

import Testing
import Foundation
import CryptoKit
import SwiftUI
import UIKit
import AppDependencies  // re-exports SQLite (Connection, Table, Expression, ...)
@testable import AMP2_App_iOS

// MARK: - Test Helpers

/// Fresh in-memory database with the teams schema applied.
private func makeInMemoryConnection() throws -> Connection {
    let db = try Connection(.inMemory)
    for ddl in TeamSchema.allDDL {
        try db.run(ddl)
    }
    return db
}

private func makeIsolatedStore() throws -> TeamStore {
    TeamStore(connection: try makeInMemoryConnection())
}

private func sampleTeam(
    name: String = "Alpha Team",
    region: String = "North America",
    rfChannel: Int = 3,
    securityKey: String = "Mike",
    networkId: Int = 42
) -> Team {
    Team(
        region: region,
        rfChannel: rfChannel,
        securityKey: securityKey,
        networkId: networkId,
        name: name
    )
}

// MARK: - Region Rules

@Suite("Region Rules")
struct RegionRulesTests {

    @Test("North America / Latin America expose channels 1...5")
    func naLaChannels() {
        #expect(Region.northAmerica.availableChannels == 1...5)
        #expect(Region.latinAmerica.availableChannels == 1...5)
    }

    @Test("Eurasia exposes channels 1...5 like every region")
    func eurasiaChannels() {
        #expect(Region.eurasia.availableChannels == 1...5)
    }

    @Test("Channels 1–5 are available in every region", arguments: 1...5)
    func sharedChannels(channel: Int) {
        #expect(Region.northAmerica.availableChannels.contains(channel) == true)
        #expect(Region.latinAmerica.availableChannels.contains(channel) == true)
        #expect(Region.eurasia.availableChannels.contains(channel) == true)
    }

    @Test("init(from:) is case-insensitive for raw values and display names")
    func caseInsensitiveInit() {
        #expect(Region(from: "northAmerica") == .northAmerica)
        #expect(Region(from: "NORTHAMERICA") == .northAmerica)
        #expect(Region(from: "North America") == .northAmerica)
        #expect(Region(from: "north america") == .northAmerica)
        #expect(Region(from: "Latin America") == .latinAmerica)
        #expect(Region(from: "eurasia") == .eurasia)
        #expect(Region(from: "Eurasia") == .eurasia)
    }

    @Test("init(from:) returns nil for unknown strings")
    func unknownRegionIsNil() {
        #expect(Region(from: "Antarctica") == nil)
        #expect(Region(from: "") == nil)
    }

    @Test("displayName maps to human-readable names")
    func displayNames() {
        #expect(Region.northAmerica.displayName == "North America")
        #expect(Region.latinAmerica.displayName == "Latin America")
        #expect(Region.eurasia.displayName == "Eurasia")
    }
}

// MARK: - SecurityKey

@Suite("SecurityKey")
struct SecurityKeyTests {

    @Test("All 10 predefined keys are present")
    func allKeysPresent() {
        #expect(SecurityKey.all.count == 10)
        let expected = ["MIKE", "NOVEMBER", "OSCAR", "PAPA", "QUEBEC",
                        "ROMEO", "SIERRA", "TANGO", "UNIFORM", "VICTOR"]
        #expect(SecurityKey.all.map(\.rawValue) == expected)
    }

    @Test("Case-insensitive lookup succeeds")
    func caseInsensitiveLookup() {
        #expect(SecurityKey(rawValue: "mike") == .MIKE)
        #expect(SecurityKey(rawValue: "MIKE") == .MIKE)
        #expect(SecurityKey(rawValue: "Victor") == .VICTOR)
        #expect(SecurityKey(rawValue: "nOvEmBeR") == .NOVEMBER)
    }

    @Test("Unknown key returns nil")
    func unknownKeyIsNil() {
        #expect(SecurityKey(rawValue: "ALPHA") == nil)
        #expect(SecurityKey(rawValue: "") == nil)
        #expect(SecurityKey(rawValue: "MIKE ") == nil)
    }

    @Test("Codable round-trip preserves the key")
    func codableRoundTrip() throws {
        let data = try JSONEncoder().encode(SecurityKey.TANGO)
        #expect(String(data: data, encoding: .utf8) == "\"TANGO\"")
        let decoded = try JSONDecoder().decode(SecurityKey.self, from: data)
        #expect(decoded == .TANGO)
    }
}

// MARK: - Team Validation

@Suite("Team Validation")
struct TeamValidationTests {

    /// One byte on the wire (LTC `0x04`), as on Android. 256 used to be accepted
    /// and could never reach the headset.
    @Test("Network ID boundaries: 0 valid, 255 valid, 256 invalid, -1 invalid")
    func networkIdBoundaries() {
        #expect(TeamValidation.validateNetworkId(0) == .valid)
        #expect(TeamValidation.validateNetworkId(1) == .valid)
        #expect(TeamValidation.validateNetworkId(128) == .valid)
        #expect(TeamValidation.validateNetworkId(255) == .valid)
        #expect(TeamValidation.validateNetworkId(256) != .valid)
        #expect(TeamValidation.validateNetworkId(-1) != .valid)
    }

    @Test("RF channel validation is uniform across regions (1...5)")
    func rfChannelUniform() {
        for region in Region.allCases {
            #expect(TeamValidation.validateRFChannel(5, in: region) == .valid)
            #expect(TeamValidation.validateRFChannel(6, in: region) != .valid)
            #expect(TeamValidation.validateRFChannel(11, in: region) != .valid)
            #expect(TeamValidation.validateRFChannel(0, in: region) != .valid)
        }
    }

    @Test("Security key validation accepts any casing, rejects unrecognized keys")
    func securityKeyValidation() {
        #expect(TeamValidation.validateSecurityKey("Mike") == .valid)
        #expect(TeamValidation.validateSecurityKey("Victor") == .valid)
        #expect(TeamValidation.validateSecurityKey("tango") == .valid)    // normalized → "Tango"
        #expect(TeamValidation.validateSecurityKey("MIKE") == .valid)     // normalized → "Mike"
        #expect(TeamValidation.validateSecurityKey("ALPHA") != .valid)
        #expect(TeamValidation.validateSecurityKey("") != .valid)
    }

    @Test("customSecurityKey must be rejected when non-nil")
    func customSecurityKeyRejected() {
        #expect(TeamValidation.validateCustomSecurityKey(nil) == .valid)
        #expect(TeamValidation.validateCustomSecurityKey("anything") == .customSecurityKeyNotSupported)
        #expect(TeamValidation.validateCustomSecurityKey("") == .customSecurityKeyNotSupported)
    }

    @Test("Team name validation trims whitespace and rejects empty")
    func teamNameValidation() {
        #expect(TeamValidation.validateTeamName("Alpha") == .valid)
        #expect(TeamValidation.validateTeamName("   Bravo  ") == .valid)
        #expect(TeamValidation.validateTeamName("") != .valid)
        #expect(TeamValidation.validateTeamName("     ") != .valid)
    }

    @Test("validateTeam happy path all pass")
    func validateTeamHappyPath() {
        let team = sampleTeam()
        let results = TeamValidation.validateTeam(team, in: .northAmerica)
        #expect(TeamValidation.allPassed(results) == true)
    }

    @Test("validateTeam sad path: bad channel + bad key + empty name + bad networkId")
    func validateTeamSadPath() {
        let team = Team(
            region: "North America",
            rfChannel: 9,        // invalid in every region (6–11 unsupported)
            securityKey: "ALPHA", // invalid key
            customSecurityKey: "x", // reserved, must be rejected
            networkId: 999,      // out of range
            name: "  "           // empty after trim
        )
        let results = TeamValidation.validateTeam(team, in: .northAmerica)
        #expect(TeamValidation.allPassed(results) == false)
        #expect(results.filter { $0 == .valid }.isEmpty)
    }
}

// MARK: - Team Model

@Suite("Team Model")
struct TeamModelTests {

    @Test("isDuplicate ignores id, favorite, and locked flags")
    func isDuplicateIgnoresMetadata() {
        let a = Team(id: 1, region: "North America", rfChannel: 3, securityKey: "MIKE",
                     networkId: 42, name: "Alpha", isFavorited: true, isLocked: false)
        let b = Team(id: 2, region: "North America", rfChannel: 3, securityKey: "MIKE",
                     networkId: 42, name: "Alpha", isFavorited: false, isLocked: true)
        #expect(a.isDuplicate(of: b) == true)
    }

    @Test("isDuplicate false when any meaningful field differs")
    func isDuplicateFalseOnDifference() {
        let base = sampleTeam()
        #expect(base.isDuplicate(of: sampleTeam(name: "Bravo")) == false)
        #expect(base.isDuplicate(of: sampleTeam(region: "Eurasia")) == false)
        #expect(base.isDuplicate(of: sampleTeam(rfChannel: 4)) == false)
        #expect(base.isDuplicate(of: sampleTeam(securityKey: "TANGO")) == false)
        #expect(base.isDuplicate(of: sampleTeam(networkId: 43)) == false)
    }

    @Test("Codable round-trip preserves all fields")
    func codableRoundTrip() throws {
        let original = Team(id: 7, region: "Eurasia", rfChannel: 4, securityKey: "VICTOR",
                            customSecurityKey: nil, networkId: 200, name: "Zeta",
                            isFavorited: true, isLocked: true)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Team.self, from: data)
        #expect(decoded == original)
    }
}

// MARK: - TeamStore CRUD (isolated in-memory connection)

@Suite("TeamStore CRUD")
struct TeamStoreTests {

    @Test("create + fetch round-trip assigns an id")
    func createFetchRoundTrip() throws {
        let store = try makeIsolatedStore()
        let created = try store.create(sampleTeam(), in: .northAmerica)
        #expect(created.id > 0)

        let fetched = try store.fetch(created.id)
        #expect(fetched == created)
    }

    @Test("fetch returns nil for a missing id")
    func fetchMissingIsNil() throws {
        let store = try makeIsolatedStore()
        #expect(try store.fetch(9999) == nil)
    }

    @Test("fetchAll returns rows ordered by name ascending")
    func fetchAllOrdered() throws {
        let store = try makeIsolatedStore()
        _ = try store.create(sampleTeam(name: "Charlie", networkId: 1), in: .northAmerica)
        _ = try store.create(sampleTeam(name: "Alpha", networkId: 2), in: .northAmerica)
        _ = try store.create(sampleTeam(name: "Bravo", networkId: 3), in: .northAmerica)

        let all = try store.fetchAll()
        #expect(all.map(\.name) == ["Alpha", "Bravo", "Charlie"])
    }

    @Test("fetchFavorites returns only favorited teams")
    func fetchFavoritesFilter() throws {
        let store = try makeIsolatedStore()
        let a = try store.create(sampleTeam(name: "Alpha", networkId: 1), in: .northAmerica)
        _ = try store.create(sampleTeam(name: "Bravo", networkId: 2), in: .northAmerica)
        _ = try store.toggleFavorite(a.id)

        let favorites = try store.fetchFavorites()
        #expect(favorites.count == 1)
        #expect(favorites.first?.name == "Alpha")
        #expect(favorites.first?.isFavorited == true)
    }

    @Test("count reflects inserts and deletes")
    func countReflectsChanges() throws {
        let store = try makeIsolatedStore()
        #expect(try store.count() == 0)
        let a = try store.create(sampleTeam(name: "Alpha", networkId: 1), in: .northAmerica)
        _ = try store.create(sampleTeam(name: "Bravo", networkId: 2), in: .northAmerica)
        #expect(try store.count() == 2)
        try store.delete(a.id)
        #expect(try store.count() == 1)
    }

    @Test("update persists changed fields")
    func updatePersists() throws {
        let store = try makeIsolatedStore()
        var created = try store.create(sampleTeam(), in: .northAmerica)
        created.name = "Renamed"
        created.rfChannel = 5
        let updated = try store.update(created, in: .northAmerica)
        #expect(updated.name == "Renamed")

        let fetched = try store.fetch(created.id)
        #expect(fetched?.name == "Renamed")
        #expect(fetched?.rfChannel == 5)
    }

    @Test("update throws when the team does not exist")
    func updateMissingThrows() throws {
        let store = try makeIsolatedStore()
        let ghost = Team(id: 12345, region: "North America", rfChannel: 3,
                         securityKey: "MIKE", networkId: 1, name: "Ghost")
        #expect(throws: DatabaseError.self) {
            _ = try store.update(ghost, in: .northAmerica)
        }
    }

    @Test("delete removes a row; deleting a missing id is a no-op")
    func deleteBehavior() throws {
        let store = try makeIsolatedStore()
        let a = try store.create(sampleTeam(), in: .northAmerica)
        try store.delete(a.id)
        #expect(try store.fetch(a.id) == nil)
        try store.delete(a.id)
        #expect(try store.count() == 0)
    }

    @Test("deleteAll clears the table")
    func deleteAllClears() throws {
        let store = try makeIsolatedStore()
        _ = try store.create(sampleTeam(name: "Alpha", networkId: 1), in: .northAmerica)
        _ = try store.create(sampleTeam(name: "Bravo", networkId: 2), in: .northAmerica)
        try store.deleteAll()
        #expect(try store.count() == 0)
    }

    @Test("toggleFavorite flips the flag")
    func toggleFavoriteFlips() throws {
        let store = try makeIsolatedStore()
        let a = try store.create(sampleTeam(), in: .northAmerica)
        #expect(a.isFavorited == false)
        let toggledOn = try store.toggleFavorite(a.id)
        #expect(toggledOn.isFavorited == true)
        let toggledOff = try store.toggleFavorite(a.id)
        #expect(toggledOff.isFavorited == false)
    }

    @Test("toggleLocked flips the flag")
    func toggleLockedFlips() throws {
        let store = try makeIsolatedStore()
        let a = try store.create(sampleTeam(), in: .northAmerica)
        #expect(a.isLocked == false)
        let locked = try store.toggleLocked(a.id)
        #expect(locked.isLocked == true)
        let unlocked = try store.toggleLocked(a.id)
        #expect(unlocked.isLocked == false)
    }

    @Test("toggleFavorite throws for a missing id")
    func toggleMissingThrows() throws {
        let store = try makeIsolatedStore()
        #expect(throws: DatabaseError.self) {
            _ = try store.toggleFavorite(4242)
        }
    }

    @Test("create rejects a duplicate team")
    func createRejectsDuplicate() throws {
        let store = try makeIsolatedStore()
        _ = try store.create(sampleTeam(), in: .northAmerica)
        #expect(throws: DatabaseError.self) {
            _ = try store.create(sampleTeam(), in: .northAmerica)
        }
    }

    @Test("create rejects an invalid team (validation)")
    func createRejectsInvalid() throws {
        let store = try makeIsolatedStore()
        let bad = sampleTeam(rfChannel: 9) // invalid in every region (6–11 unsupported)
        #expect(throws: DatabaseError.self) {
            _ = try store.create(bad, in: .northAmerica)
        }
    }

    @Test("findDuplicate / isDuplicate detect matching settings")
    func duplicateDetection() throws {
        let store = try makeIsolatedStore()
        let created = try store.create(sampleTeam(), in: .northAmerica)

        #expect(try store.isDuplicate(sampleTeam()) == true)
        #expect(try store.findDuplicate(of: sampleTeam())?.id == created.id)

        #expect(try store.isDuplicate(created, excludingId: created.id) == false)

        #expect(try store.isDuplicate(sampleTeam(name: "Different")) == false)
    }

    @Test("update allows keeping the same settings on the same row")
    func updateSelfNotDuplicate() throws {
        let store = try makeIsolatedStore()
        var created = try store.create(sampleTeam(), in: .northAmerica)
        created.isFavorited = true // change only metadata; settings identical
        let updated = try store.update(created, in: .northAmerica)
        #expect(updated.isFavorited == true)
    }
}

// MARK: - QRCodeCrypto

@Suite("QRCodeCrypto")
struct QRCodeCryptoTests {

    @Test("encrypt → decrypt round-trips to the original plaintext")
    func roundTrip() throws {
        let plaintext = "{\"hello\":\"world\",\"n\":42}"
        let cipher = try QRCodeCrypto.encrypt(plaintext)
        let recovered = try QRCodeCrypto.decrypt(cipher)
        #expect(recovered == plaintext)
    }

    @Test("output uses URL-safe Base64 with no +, /, or = characters")
    func urlSafeBase64() throws {
        // Long enough that standard Base64 would emit + and /.
        let plaintext = String(repeating: "The quick brown fox 0123456789/+=", count: 8)
        let cipher = try QRCodeCrypto.encrypt(plaintext)
        #expect(!cipher.contains("+"))
        #expect(!cipher.contains("/"))
        #expect(!cipher.contains("="))
    }

    @Test("IV is prepended: decoded length == 12 (IV) + plaintext + 16 (tag)")
    func ivPrependedLength() throws {
        let plaintext = "abcdefghij" // 10 UTF-8 bytes
        let cipher = try QRCodeCrypto.encrypt(plaintext)
        let combined = try #require(Data(base64EncodedStringPadded: cipher))
        #expect(combined.count == 12 + plaintext.utf8.count + 16)
    }

    @Test("decrypt fails on malformed Base64")
    func decryptMalformedBase64() {
        #expect(throws: CryptoError.self) {
            _ = try QRCodeCrypto.decrypt("!!!not base64!!!")
        }
    }

    @Test("decrypt fails on too-short input")
    func decryptTooShort() throws {
        // Shorter than IV(12) + 1 + tag(16).
        let tiny = Data([0x01, 0x02, 0x03, 0x04, 0x05]).base64EncodedStringNoPadding()
        #expect(throws: CryptoError.self) {
            _ = try QRCodeCrypto.decrypt(tiny)
        }
    }

    @Test("decrypt fails on tampered ciphertext (GCM authentication)")
    func decryptTampered() throws {
        let cipher = try QRCodeCrypto.encrypt("sensitive payload")
        var combined = try #require(Data(base64EncodedStringPadded: cipher))
        // Past the 12-byte IV.
        combined[13] ^= 0xFF
        let tampered = combined.base64EncodedStringNoPadding()
        #expect(throws: (any Error).self) {
            _ = try QRCodeCrypto.decrypt(tampered)
        }
    }

    // MARK: Android compatibility fixture

    /// `OBFUSCATED_KEY` XOR `MASK` (repeating every 4 bytes), as Android's `Crypto`
    /// derives it. If this breaks, QR codes no longer cross platforms.
    static let expectedUnmaskedKey: [UInt8] = [
        0x47, 0x33, 0x4E, 0x6C, 0x33, 0x70, 0x5F, 0x43,
        0x30, 0x62, 0x33, 0x1F, 0x33, 0x6C, 0x31, 0x6C,
        0x33, 0x5F, 0x44, 0x33, 0x61, 0x75, 0x5F, 0x53,
        0x33, 0x63, 0x75, 0x6A, 0x31, 0x70, 0x79, 0x21
    ]

    @Test("MASK and OBFUSCATED_KEY match the Android Crypto contract")
    func androidConstantsMatch() {
        #expect(QRCodeCrypto.testMask == [0x42, 0x7A, 0x1C, 0x3F])
        #expect(QRCodeCrypto.testObfuscatedKey == [
            0x05, 0x49, 0x52, 0x53, 0x71, 0x0A, 0x43, 0x7C,
            0x72, 0x18, 0x2F, 0x20, 0x71, 0x16, 0x2D, 0x53,
            0x71, 0x25, 0x58, 0x0C, 0x23, 0x0F, 0x43, 0x6C,
            0x71, 0x19, 0x69, 0x55, 0x73, 0x0A, 0x65, 0x1E
        ])
    }

    @Test("Derived AES-256 key matches the deterministic cross-platform vector")
    func derivedKeyMatchesVector() {
        let keyBytes = QRCodeCrypto.testKey.withUnsafeBytes { Data($0) }
        #expect(keyBytes.count == 32)
        #expect(Array(keyBytes) == Self.expectedUnmaskedKey)

        // Pin Android's XOR, not just the resulting bytes.
        let mask = QRCodeCrypto.testMask
        let obfuscated = QRCodeCrypto.testObfuscatedKey
        let rederived = (0..<obfuscated.count).map { obfuscated[$0] ^ mask[$0 % mask.count] }
        #expect(rederived == Self.expectedUnmaskedKey)
    }

    @Test("Ciphertext produced with the shared key decrypts on this platform")
    func sharedKeyInteropRoundTrip() throws {
        // Random IV, so no fixed string to pin. Seal with raw CryptoKit as Android
        // would: IV(12) || ciphertext || tag(16), URL-safe Base64, unpadded.
        let key = QRCodeCrypto.testKey
        let json = "{\"name\":\"Interop\",\"region\":\"North America\",\"rfChannel\":3}"
        let nonce = AES.GCM.Nonce()
        let sealed = try AES.GCM.seal(Data(json.utf8), using: key, nonce: nonce)

        var combined = Data()
        combined.append(contentsOf: Array(nonce))
        combined.append(sealed.ciphertext)
        combined.append(sealed.tag)
        let wire = combined.base64EncodedStringNoPadding()

        let recovered = try QRCodeCrypto.decrypt(wire)
        #expect(recovered == json)
    }
}

// MARK: - QRPayload

@Suite("QRPayload")
struct QRPayloadTests {

    @Test("encode/decode JSON round-trip")
    func encodeDecodeRoundTrip() throws {
        let payload = QRPayload(team: sampleTeam())
        let json = try payload.encode()
        let decoded = try QRPayload.decode(from: json)
        #expect(decoded == payload)
    }

    @Test("version field is 1 for generated payloads")
    func versionIsOne() throws {
        let payload = QRPayload(team: sampleTeam())
        #expect(payload.version == 1)
        let json = try payload.encode()
        #expect(json.contains("\"version\":1"))
    }

    @Test("customSecurityKey is OMITTED from the generated payload JSON")
    func customSecurityKeyOmitted() throws {
        var team = sampleTeam()
        team.customSecurityKey = "should-not-appear"
        let json = try QRPayload(team: team).encode()
        #expect(!json.contains("customSecurityKey"))
        #expect(!json.contains("should-not-appear"))
    }

    @Test("Generated JSON contains the exact Android-contract field names")
    func androidFieldNames() throws {
        // Shared with Android; see Android util/Crypto.kt.
        let json = try QRPayload(team: sampleTeam()).encode()
        for key in ["\"version\"", "\"team\"", "\"region\"", "\"rfChannel\"",
                    "\"securityKey\"", "\"networkId\"", "\"name\""] {
            #expect(json.contains(key), "Expected JSON to contain \(key)")
        }
    }

    @Test("toTeam produces a valid, importable Team")
    func toTeamValid() throws {
        let payload = QRPayload(team: sampleTeam())
        let team = payload.toTeam()
        #expect(team.id == 0)
        #expect(team.customSecurityKey == nil)
        let results = TeamValidation.validateTeam(team, in: .northAmerica)
        #expect(TeamValidation.allPassed(results))
    }

    @Test("decode rejects an unsupported version")
    func decodeRejectsUnsupportedVersion() {
        let json = """
        {"version":2,"team":{"region":"North America","rfChannel":3,"securityKey":"MIKE","networkId":42,"name":"Alpha"}}
        """
        #expect(throws: QRPayloadError.self) {
            _ = try QRPayload.decode(from: json)
        }
    }

    @Test("decode fails when a required field is missing")
    func decodeMissingField() {
        // No networkId.
        let json = """
        {"version":1,"team":{"region":"North America","rfChannel":3,"securityKey":"MIKE","name":"Alpha"}}
        """
        #expect(throws: (any Error).self) {
            _ = try QRPayload.decode(from: json)
        }
    }

    @Test("decode fails on invalid JSON")
    func decodeInvalidJSON() {
        #expect(throws: (any Error).self) {
            _ = try QRPayload.decode(from: "not json at all")
        }
    }

    @Test("exportTeam → importTeam full pipeline round-trips")
    func exportImportPipeline() throws {
        let original = sampleTeam(name: "Pipeline", rfChannel: 4, securityKey: "Tango", networkId: 77)
        let base64 = try QRPayload.exportTeam(original)
        let imported = try QRPayload.importTeam(from: base64)

        #expect(imported.name == original.name)
        #expect(imported.region == original.region)
        #expect(imported.rfChannel == original.rfChannel)
        #expect(imported.securityKey == original.securityKey)
        #expect(imported.networkId == original.networkId)
        #expect(imported.id == 0)
        #expect(imported.customSecurityKey == nil)
    }

    @Test("importTeam validates the payload and rejects an invalid networkId")
    func importRejectsInvalidNetworkId() throws {
        let badJSON = """
        {"version":1,"team":{"region":"North America","rfChannel":3,"securityKey":"Mike","networkId":9999,"name":"Bad"}}
        """
        let cipher = try QRCodeCrypto.encrypt(badJSON)
        #expect(throws: QRPayloadError.self) {
            _ = try QRPayload.importTeam(from: cipher)
        }
    }

    @Test("importTeam rejects an unrecognized security key")
    func importRejectsBadSecurityKey() throws {
        let badJSON = """
        {"version":1,"team":{"region":"North America","rfChannel":3,"securityKey":"ALPHA","networkId":42,"name":"Bad"}}
        """
        let cipher = try QRCodeCrypto.encrypt(badJSON)
        #expect(throws: QRPayloadError.self) {
            _ = try QRPayload.importTeam(from: cipher)
        }
    }
}

// MARK: - LTC Protocol Codec

/// BLE wire format. Expected bytes come from
/// Gentex's "LTC Configuration Commands (BLE)" document (July 27, 2026)
@Suite("LTC protocol codec")
struct LTCProtocolTests {

    // MARK: Command Encoding

    @Test("Read command matches the documented example byte for byte")
    func readCommandMatchesDoc() {
        // "00 1d 40 2c 00 00 01" — read the pre-defined team setting.
        #expect(LTCPacket.read(.predefinedTeam) == Data([0x00, 0x1d, 0x40, 0x2c, 0x00, 0x00, 0x01]))
    }

    @Test("Write command matches the documented example byte for byte")
    func writeCommandMatchesDoc() {
        // "00 1d 40 2c 01 00 01 00" — set the pre-defined team to Alpha.
        #expect(
            LTCPacket.write(.predefinedTeam, value: PredefinedTeam.alpha.rawValue)
                == Data([0x00, 0x1d, 0x40, 0x2c, 0x01, 0x00, 0x01, 0x00])
        )
    }

    @Test("Every documented poll command encodes exactly as published")
    func pollSequenceMatchesDoc() {
        let expected: [LTCSetting: [UInt8]] = [
            .predefinedTeam: [0x00, 0x1d, 0x40, 0x2c, 0x00, 0x00, 0x01],
            .securityKey:    [0x00, 0x1d, 0x40, 0x2c, 0x00, 0x01, 0x01],
            .rfChannel:      [0x00, 0x1d, 0x40, 0x2c, 0x00, 0x03, 0x01],
            .networkId:      [0x00, 0x1d, 0x40, 0x2c, 0x00, 0x04, 0x01],
            .ltcMode:        [0x00, 0x1d, 0x40, 0x2c, 0x00, 0x05, 0x01],
            .vadThreshold:   [0x00, 0x1d, 0x40, 0x2c, 0x00, 0x06, 0x01],
            .txPower:        [0x00, 0x1d, 0x40, 0x2c, 0x00, 0x07, 0x01],
            .ltcVolume:      [0x00, 0x1d, 0x40, 0x2c, 0x00, 0x08, 0x01],
            .zone:           [0x00, 0x1d, 0x40, 0x2c, 0x00, 0x0a, 0x01]
        ]
        for (setting, bytes) in expected {
            #expect(LTCPacket.read(setting) == Data(bytes))
        }
        // customSecurityKey is unimplemented in firmware, so it is not polled.
        #expect(Set(LTCSetting.pollSequence) == Set(expected.keys))
        #expect(LTCSetting.pollSequence.count == 9)
        #expect(!LTCSetting.pollSequence.contains(.customSecurityKey))
    }

    /// Android's SPP framing (`FF 03 01 <len> …` + XOR checksum) must not leak
    /// into BLE, which takes the bare packet.
    @Test("Packets carry no SPP framing and no checksum")
    func noSPPFraming() {
        let packet = LTCPacket.write(.ltcVolume, value: 5)
        #expect(packet.first != 0xFF)
        #expect(packet.prefix(4) == Data([0x00, 0x1d, 0x40, 0x2c]))
        // header(4) + op + setting + length + payload = 8 bytes, no checksum.
        #expect(packet.count == 8)
        #expect(LTCPacket.read(.ltcVolume).count == 7)
    }

    @Test("Identity query matches the documented example")
    func identityQueryMatchesDoc() {
        #expect(LTCPacket.identityQuery == Data([0x00, 0x1d, 0x40, 0x0c, 0x00, 0x00, 0x00, 0x2f]))
    }

    @Test("Multi-byte writes set the length byte from the payload")
    func multiByteWriteLength() {
        let packet = LTCPacket.write(.customSecurityKey, payload: Data([0xaa, 0xbb, 0xcc]))
        #expect(packet == Data([0x00, 0x1d, 0x40, 0x2c, 0x01, 0x02, 0x03, 0xaa, 0xbb, 0xcc]))
    }

    // MARK: Response Decoding

    @Test("Read response yields the documented value")
    func readResponseMatchesDoc() throws {
        // "00 1d 41 2c 02" — the current team is Charlie.
        let response = try LTCResponse.parse(Data([0x00, 0x1d, 0x41, 0x2c, 0x02]))
        #expect(try response.readValue() == 0x02)
        #expect(PredefinedTeam(rawValue: try response.readValue()) == .charlie)
    }

    @Test("Write response of 0x00 is success")
    func writeSuccess() throws {
        let response = try LTCResponse.parse(Data([0x00, 0x1d, 0x41, 0x2c, 0x00]))
        #expect(throws: Never.self) { try response.validateWriteSucceeded() }
    }

    @Test("Each documented error status maps to a thrown error")
    func writeErrorStatuses() throws {
        let cases: [(UInt8, LTCStatus)] = [
            (0x01, .lengthError), (0x02, .badValue), (0x03, .commFailure)
        ]
        for (raw, status) in cases {
            let response = try LTCResponse.parse(Data([0x00, 0x1d, 0x41, 0x2c, raw]))
            #expect(throws: LTCProtocolError.headsetReportedError(status)) {
                try response.validateWriteSucceeded()
            }
        }
    }

    @Test("Unrecognized status codes are rejected rather than assumed successful")
    func unknownStatusRejected() throws {
        let response = try LTCResponse.parse(Data([0x00, 0x1d, 0x41, 0x2c, 0x7f]))
        #expect(throws: LTCProtocolError.unknownStatus(0x7f)) {
            try response.validateWriteSucceeded()
        }
    }

    @Test("Responses without the response header are rejected")
    func malformedResponsesRejected() {
        // Command header (0x40), not response (0x41).
        #expect(throws: LTCProtocolError.self) {
            _ = try LTCResponse.parse(Data([0x00, 0x1d, 0x40, 0x2c, 0x02]))
        }
        // Truncated header.
        #expect(throws: LTCProtocolError.self) {
            _ = try LTCResponse.parse(Data([0x00, 0x1d, 0x41]))
        }
        #expect(throws: LTCProtocolError.self) {
            _ = try LTCResponse.parse(Data())
        }
    }

    @Test("A header-only response has no value")
    func emptyPayloadRejected() throws {
        let response = try LTCResponse.parse(Data([0x00, 0x1d, 0x41, 0x2c]))
        #expect(response.value == nil)
        #expect(throws: LTCProtocolError.emptyPayload) { _ = try response.readValue() }
    }

    // MARK: Headset Identity

    @Test("Identity response decodes the documented part number")
    func identityMatchesDoc() throws {
        // As printed in the doc.
        let raw = Data([
            0x00, 0x1d, 0x41, 0x0c, 0x00, 0x00, 0x00, 0x2f,
            0x31, 0x30, 0x30, 0x34, 0x32, 0x35, 0x37, 0x2d,
            0x31, 0x32, 0x30, 0x31, 0x2d, 0x31, 0x32, 0x30,
            0x31, 0x00
        ])
        let identity = try HeadsetIdentity.parse(raw)
        #expect(identity.partNumber == "1004257-1201-1201")
        // Kit digit 2 (from 12011201): unlocked.
        #expect(identity.regionLock == nil)
    }

    @Test("Kit digit drives the region lock")
    func regionLockFromKitDigit() {
        #expect(HeadsetIdentity(partNumber: "1004257-1201-1001").regionLock == .northAmerica)
        #expect(HeadsetIdentity(partNumber: "1004257-1201-1301").regionLock == .europe)
        #expect(HeadsetIdentity(partNumber: "1004257-1201-1101").regionLock == nil)
        #expect(HeadsetIdentity(partNumber: "1004257-1201-1201").regionLock == nil)
    }

    @Test("Malformed identity responses are rejected")
    func malformedIdentityRejected() {
        #expect(throws: LTCProtocolError.self) {
            _ = try HeadsetIdentity.parse(Data([0x00, 0x1d, 0x41, 0x2c, 0x00]))
        }
        // Header, no part number.
        #expect(throws: LTCProtocolError.self) {
            _ = try HeadsetIdentity.parse(Data([0x00, 0x1d, 0x41, 0x0c, 0x00, 0x00, 0x00, 0x2f, 0x00]))
        }
    }

    // MARK: Value Mappings

    @Test("Security keys map to bytes 0x00 through 0x09 and back")
    func securityKeyBytes() {
        #expect(SecurityKey.MIKE.ltcByte == 0x00)
        #expect(SecurityKey.VICTOR.ltcByte == 0x09)
        for key in SecurityKey.allCases {
            #expect(SecurityKey(ltcByte: key.ltcByte) == key)
        }
        #expect(SecurityKey(ltcByte: 0x0a) == nil)
    }

    @Test("Regions map to the headset's zone bytes and back")
    func zoneBytes() {
        #expect(Region.northAmerica.ltcByte == 0x00)
        #expect(Region.latinAmerica.ltcByte == 0x01)
        #expect(Region.eurasia.ltcByte == 0x02)
        for region in Region.allCases {
            #expect(Region(ltcByte: region.ltcByte) == region)
        }
        #expect(Region(ltcByte: 0x03) == nil)
    }

    /// The headset is 0-based, the UI is 1-based, and only 1–5 are supported.
    @Test("RF channels convert between display numbers and wire bytes")
    func rfChannelBytes() {
        #expect(LTCRFChannel.byte(forChannel: 1) == 0x00)
        #expect(LTCRFChannel.byte(forChannel: 5) == 0x04)
        #expect(LTCRFChannel.byte(forChannel: 6) == nil)
        #expect(LTCRFChannel.byte(forChannel: 0) == nil)
        for channel in 1...5 {
            #expect(LTCRFChannel.channel(forByte: LTCRFChannel.byte(forChannel: channel)!) == channel)
        }
        // Eurasia-only channel; nothing to display.
        #expect(LTCRFChannel.channel(forByte: 0x05) == nil)
    }

    @Test("LTC modes round-trip and All Hands stays unreachable")
    func ltcModeBytes() {
        #expect(LTCMode.off.rawValue == 0x00)
        #expect(LTCMode.pushToTalk.rawValue == 0x01)
        #expect(LTCMode.vad.rawValue == 0x02)
        #expect(LTCMode.allCases.count == 3)
        #expect(LTCMode(rawValue: 0x03) == nil)
    }

    /// BLE doc's 10-value table, not Android's 11 (plan decision 0.2). If the
    /// headset accepts 0x0a, that decision was wrong.
    @Test("Tx power uses the documented 10-value table")
    func txPowerBytes() {
        #expect(TxPower.allCases.count == 10)
        #expect(TxPower.minus18.rawValue == 0x00)
        #expect(TxPower.minus18.displayName == "-18dBm")
        #expect(TxPower.plus10.rawValue == 0x09)
        #expect(TxPower.plus10.displayName == "+10dBm")
        #expect(TxPower(rawValue: 0x0a) == nil)
    }

    @Test("VAD threshold and LTC volume accept levels 0 through 10")
    func levelBytes() {
        #expect(LTCLevel.byte(for: 0) == 0x00)
        #expect(LTCLevel.byte(for: 10) == 0x0a)
        #expect(LTCLevel.byte(for: 11) == nil)
        #expect(LTCLevel.byte(for: -1) == nil)
        #expect(LTCLevel.level(forByte: 0x0b) == nil)
    }

    @Test("Network ID accepts any single byte")
    func networkIdBytes() {
        #expect(LTCNetworkID.byte(for: 0) == 0x00)
        #expect(LTCNetworkID.byte(for: 255) == 0xff)
        #expect(LTCNetworkID.byte(for: 256) == nil)
    }

    // MARK: Predefined Teams

    @Test("Predefined teams carry the documented settings")
    func predefinedTeamSettings() {
        // From the doc's table. Every preset uses Mike.
        let expected: [(PredefinedTeam, Int, Int)] = [
            (.alpha, 2, 100), (.bravo, 3, 125), (.charlie, 4, 150),
            (.delta, 5, 175), (.jointOps, 1, 200)
        ]
        for (team, channel, networkId) in expected {
            #expect(team.securityKey == .MIKE)
            #expect(team.rfChannel == channel)
            #expect(team.networkId == networkId)
        }
    }

    /// A custom team is one whose settings match no preset.
    @Test("Preset matching identifies custom teams by their settings")
    func presetMatching() {
        #expect(PredefinedTeam.matching(securityKey: .MIKE, rfChannel: 2, networkId: 100) == .alpha)
        #expect(PredefinedTeam.matching(securityKey: .MIKE, rfChannel: 1, networkId: 200) == .jointOps)
        // Alpha's channel and network ID, different key.
        #expect(PredefinedTeam.matching(securityKey: .TANGO, rfChannel: 2, networkId: 100) == nil)
        #expect(PredefinedTeam.matching(securityKey: .MIKE, rfChannel: 2, networkId: 101) == nil)
    }

    // MARK: Hex Formatting

    @Test("Hex formatting matches the Android logger's format")
    func hexFormatting() {
        #expect(Data([0x00, 0x1d, 0x40, 0x2c]).ltcHexString == "00 1D 40 2C")
        #expect(Data().ltcHexString == "")
    }
}

// MARK: - Security Key Spelling

@Suite("Security key spelling")
struct SecurityKeySpellingTests {

    /// iOS shipped "Victory"; Android and the headset doc say "Victor", so those
    /// teams failed to cross platforms. Stored rows are fixed by migration v2.
    @Test("Victor is canonical and Victory is rejected")
    func victorCanonical() {
        #expect(TeamValidation.canonicalSecurityKey("Victor") == "Victor")
        #expect(TeamValidation.canonicalSecurityKey("victor") == "Victor")
        #expect(TeamValidation.canonicalSecurityKey("VICTOR") == "Victor")
        #expect(TeamValidation.canonicalSecurityKey("Victory") == nil)
        #expect(TeamValidation.validateSecurityKey("Victor") == .valid)
        #expect(TeamValidation.validateSecurityKey("Victory") != .valid)
    }

    @Test("Victor resolves to the enum case and byte 0x09")
    func victorResolves() {
        #expect(SecurityKey(rawValue: "Victor") == .VICTOR)
        #expect(SecurityKey(rawValue: "Victory") == nil)
        #expect(SecurityKey(rawValue: "Victor")?.ltcByte == 0x09)
    }

    @Test("Unrelated keys are still rejected")
    func rejectsUnknown() {
        #expect(TeamValidation.canonicalSecurityKey("Vector") == nil)
        #expect(TeamValidation.canonicalSecurityKey("Alpha") == nil)
        #expect(SecurityKey(rawValue: "Vector") == nil)
    }
}

// MARK: - Schema Migrations

@Suite("Schema migrations")
struct SchemaMigrationTests {

    /// Fixing only the validator would leave "Victory" in stored rows and in
    /// every QR code exported from them.
    @Test("Migration v2 rewrites Victory to Victor in stored teams")
    func migrationRewritesVictory() throws {
        let db = try Connection(.inMemory)
        for ddl in TeamSchema.allDDL { try db.run(ddl) }

        // Rows as an earlier build would have written them.
        try db.run("""
            INSERT INTO teams (region, rf_channel, security_key, network_id, name)
            VALUES ('North America', 3, 'Victory', 42, 'Old Spelling'),
                   ('North America', 4, 'victory', 43, 'Old Lowercase'),
                   ('North America', 5, 'Mike', 44, 'Untouched')
            """)

        for statement in TeamSchema.migrations[2] ?? [] {
            try db.run(statement)
        }

        let keys = try db.prepare("SELECT name, security_key FROM teams ORDER BY name")
            .map { ($0[0] as? String ?? "", $0[1] as? String ?? "") }

        #expect(keys.first(where: { $0.0 == "Old Spelling" })?.1 == "Victor")
        #expect(keys.first(where: { $0.0 == "Old Lowercase" })?.1 == "Victor")
        #expect(keys.first(where: { $0.0 == "Untouched" })?.1 == "Mike")
    }

    @Test("Migrated values pass validation, unlike the spelling they replace")
    func migratedValuesValidate() {
        #expect(TeamValidation.validateSecurityKey("Victor") == .valid)
        #expect(TeamValidation.validateSecurityKey("Victory") != .valid)
    }

    @Test("Schema version covers the migrations that exist")
    func versionCoversMigrations() {
        #expect(TeamSchema.currentVersion == 2)
        #expect(TeamSchema.migrations.keys.max() == TeamSchema.currentVersion)
    }

    // MARK: - The migration runner

    /// Schema applied, no version recorded: a pre-versioning install.
    private func unversionedDatabase() throws -> Connection {
        let db = try Connection(.inMemory)
        for ddl in TeamSchema.allDDL { try db.run(ddl) }
        return db
    }

    @Test("An unversioned database is treated as version 0")
    func unversionedReadsAsZero() throws {
        #expect(try DatabaseManager.currentSchemaVersion(db: unversionedDatabase()) == 0)
    }

    @Test("A database without the metadata table is treated as version 0")
    func missingMetadataTableReadsAsZero() throws {
        // No DDL: the version query fails, and that must not throw.
        let db = try Connection(.inMemory)
        #expect(try DatabaseManager.currentSchemaVersion(db: db) == 0)
    }

    @Test("Migrating from scratch reaches the current version")
    func migratesToCurrent() throws {
        let db = try unversionedDatabase()
        try DatabaseManager.runMigrations(db: db)
        #expect(try DatabaseManager.currentSchemaVersion(db: db) == TeamSchema.currentVersion)
    }

    /// v1 has no statements. A runner that only recorded versions it had SQL for
    /// would re-run later migrations forever.
    @Test("Versions without statements still advance the recorded version")
    func versionsWithoutStatementsAdvance() throws {
        let db = try unversionedDatabase()
        #expect(TeamSchema.migrations[1] == nil)
        try DatabaseManager.runMigrations(db: db)
        #expect(try DatabaseManager.currentSchemaVersion(db: db) == TeamSchema.currentVersion)
    }

    @Test("Migrating twice is a no-op, not an error")
    func migrationIsIdempotent() throws {
        let db = try unversionedDatabase()
        try db.run("""
            INSERT INTO teams (region, rf_channel, security_key, network_id, name)
            VALUES ('North America', 3, 'Victory', 42, 'Old Spelling')
            """)

        try DatabaseManager.runMigrations(db: db)
        try DatabaseManager.runMigrations(db: db)
        try DatabaseManager.runMigrations(db: db)

        #expect(try DatabaseManager.currentSchemaVersion(db: db) == TeamSchema.currentVersion)
        let keys = try db.prepare("SELECT security_key FROM teams").map { $0[0] as? String ?? "" }
        #expect(keys == ["Victor"])
    }

    @Test("An already-current database is left alone")
    func alreadyCurrentIsUntouched() throws {
        let db = try unversionedDatabase()
        try DatabaseManager.setSchemaVersion(TeamSchema.currentVersion, db: db)

        // v2 must not run: this row postdates it, so "Victory" is not legacy.
        try db.run("""
            INSERT INTO teams (region, rf_channel, security_key, network_id, name)
            VALUES ('North America', 3, 'Victory', 42, 'Not Legacy')
            """)
        try DatabaseManager.runMigrations(db: db)

        let keys = try db.prepare("SELECT security_key FROM teams").map { $0[0] as? String ?? "" }
        #expect(keys == ["Victory"])
    }

    @Test("Writing a version round-trips")
    func versionRoundTrips() throws {
        let db = try unversionedDatabase()
        try DatabaseManager.setSchemaVersion(7, db: db)
        #expect(try DatabaseManager.currentSchemaVersion(db: db) == 7)
        // Rewriting replaces rather than duplicating.
        try DatabaseManager.setSchemaVersion(8, db: db)
        #expect(try DatabaseManager.currentSchemaVersion(db: db) == 8)
        let rows = try db.scalar("SELECT COUNT(*) FROM _schema_metadata WHERE key = 'schema_version'") as? Int64
        #expect(rows == 1)
    }

    @Test("A fresh database ends up with the expected schema")
    func freshSchemaShape() throws {
        let db = try unversionedDatabase()
        try DatabaseManager.runMigrations(db: db)

        let columns = try db.prepare("PRAGMA table_info(teams)").map { $0[1] as? String ?? "" }
        #expect(Set(columns) == [
            "id", "region", "rf_channel", "security_key", "custom_security_key",
            "network_id", "name", "is_favorited", "is_locked"
        ])
    }
}

// MARK: - Headset Discovery

@Suite("Headset discovery")
struct HeadsetDiscoveryTests {

    /// The AMP 2.0 advertises no service UUIDs (hardware, Aug 3 2026), so the name
    /// is the only way to shortlist it before connecting.
    @Test("The real headset's advertised name is recognized")
    func recognizesRealHeadsetName() {
        let headset = DiscoveredHeadset(
            id: UUID(), name: "Gentex_AMP2.0_PROTO-123456", source: .advertised
        )
        #expect(headset.looksLikeGentexHeadset)
    }

    @Test("Either brand token is enough, in any casing")
    func recognizesBrandTokens() {
        let names = ["Gentex_AMP2.0_PROTO-123456", "gentex", "AMP 2.0", "amp2.0", "GENTEX AMP"]
        for name in names {
            let headset = DiscoveredHeadset(id: UUID(), name: name, source: .advertised)
            #expect(headset.looksLikeGentexHeadset, "expected \(name) to match")
        }
    }

    @Test("Unrelated devices are not shortlisted")
    func rejectsUnrelatedNames() {
        let names = ["AirPods Pro", "Unnamed device", "", "Tile Tracker"]
        for name in names {
            let headset = DiscoveredHeadset(id: UUID(), name: name, source: .advertised)
            #expect(!headset.looksLikeGentexHeadset, "expected \(name) not to match")
        }
    }

    /// Not by name: one headset can report several, and two can share one.
    @Test("Headsets compare by identifier")
    func comparesByIdentifier() {
        let id = UUID()
        let a = DiscoveredHeadset(id: id, name: "Gentex A", source: .advertised)
        let b = DiscoveredHeadset(id: id, name: "Gentex B", source: .systemConnected)
        let c = DiscoveredHeadset(id: UUID(), name: "Gentex A", source: .advertised)
        #expect(a == b)
        #expect(a != c)
    }
}

// MARK: - Headset Settings State

@Suite("Headset settings state")
struct HeadsetSettingsStateTests {

    private func preset(_ team: PredefinedTeam) -> HeadsetSettingsState {
        HeadsetSettingsState(
            securityKey: team.securityKey,
            rfChannel: team.rfChannel,
            networkId: team.networkId
        )
    }

    @Test("Nothing is known before the headset answers")
    func startsEmpty() {
        let state = HeadsetSettingsState()
        #expect(!state.isComplete)
        #expect(state.isCustomTeamActive == nil)
        #expect(state.activePredefinedTeam == nil)
    }

    @Test("Settings matching a preset identify that preset", arguments: PredefinedTeam.allCases)
    func recognizesPresets(team: PredefinedTeam) {
        let state = preset(team)
        #expect(state.activePredefinedTeam == team)
        #expect(state.isCustomTeamActive == false)
    }

    /// Not from the team byte, which goes stale when a custom team is written.
    @Test("Settings matching no preset mean a custom team is active")
    func detectsCustomTeam() {
        var state = preset(.alpha)
        state.networkId = 101          // Alpha is 100
        #expect(state.activePredefinedTeam == nil)
        #expect(state.isCustomTeamActive == true)

        var keyChanged = preset(.bravo)
        keyChanged.securityKey = .TANGO   // every preset uses Mike
        #expect(keyChanged.isCustomTeamActive == true)
    }

    /// The headset keeps reporting the last preset's byte after a custom write.
    @Test("A stale team byte does not override the live settings")
    func staleTeamByteIgnored() {
        var state = preset(.alpha)
        state.networkId = 77
        state.predefinedTeam = .alpha    // headset still claims Alpha
        #expect(state.isCustomTeamActive == true)
        #expect(state.activePredefinedTeam == nil)
    }

    @Test("Completeness requires every setting")
    func completeness() {
        var state = HeadsetSettingsState(
            predefinedTeam: .alpha, securityKey: .MIKE, rfChannel: 2, networkId: 100,
            ltcMode: .pushToTalk, vadThreshold: 5, txPower: .zero, ltcVolume: 5
        )
        #expect(!state.isComplete)   // zone still missing
        state.zone = .northAmerica
        #expect(state.isComplete)
    }

    @Test("Timings match the Android implementation they were ported from")
    func timingsMatchAndroid() {
        #expect(HeadsetSettingsSync.interPacketDelay == .milliseconds(200))
        #expect(HeadsetSettingsSync.heartbeatInterval == .seconds(5))
        #expect(HeadsetSettingsSync.writeCooldown == .seconds(3))
    }
}

// MARK: - Settings Sync Behaviour

@Suite("Settings sync behaviour")
struct HeadsetSettingsSyncTests {

    @Test("Halting clears cached settings so nothing stale is shown")
    func haltClearsState() {
        let sync = HeadsetSettingsSync(transport: HeadsetSession())
        sync.haltAndDrain()
        #expect(sync.settings == HeadsetSettingsState())
        #expect(!sync.isPolling)
    }
}

// MARK: - Preset Favorites

@Suite("Preset favorites encoding")
struct PresetFavoritesTests {

    /// Presets have no DB row, so favorites are stored by name in @AppStorage,
    /// as in Android's PresetFavoritesRepository.
    @Test("Every preset name survives the newline-delimited encoding")
    func namesRoundTrip() {
        let names = PredefinedTeam.allCases.map(\.displayName)
        let encoded = names.sorted().joined(separator: "\n")
        let decoded = Set(encoded.split(separator: "\n").map(String.init))
        #expect(decoded == Set(names))
    }

    /// "Joint Ops" has a space, hence newline delimiters.
    @Test("A preset name containing a space is not split")
    func spacedNameSurvives() {
        let encoded = ["Joint Ops", "Alpha"].sorted().joined(separator: "\n")
        let decoded = Set(encoded.split(separator: "\n").map(String.init))
        #expect(decoded.contains("Joint Ops"))
        #expect(decoded.count == 2)
    }

    @Test("An empty store decodes to no favorites")
    func emptyStore() {
        #expect(Set("".split(separator: "\n").map(String.init)).isEmpty)
    }
}

// MARK: - Settings Sync Against a Fake Transport

/// Fake BLE link. Records sent packets and replies per request (or not, with
/// `autoRespond = false`), so queue ordering and response matching are testable.
@MainActor
final class FakeHeadsetTransport: HeadsetTransport {
    var connectionState: HeadsetConnectionState = .connected
    var onPacketReceived: ((Data) -> Void)?
    var onConnectionStateChanged: ((HeadsetConnectionState) -> Void)?

    private(set) var sent: [Data] = []
    /// Makes `send` throw, like a dropped link.
    var failSends = false

    var autoRespond = true
    /// Read replies per setting; unset ones read `0x00`.
    var values: [LTCSetting: UInt8] = [:]
    /// Status returned for writes. `0x00` is LTC_NO_ERR.
    var writeStatus: UInt8 = 0x00

    func send(_ packet: Data) throws {
        if failSends { throw HeadsetError.notConnected }
        sent.append(packet)

        guard autoRespond else { return }

        // Answer what was asked, not a scripted position, as the headset does.
        let isWrite = packet[4] == 0x01
        let setting = LTCSetting(rawValue: packet[5])
        let value = isWrite ? writeStatus : (setting.flatMap { values[$0] } ?? 0x00)

        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(5))
            self?.reply(value)
        }
    }

    // MARK: Test helpers

    /// Replies to the most recent request with a one-byte payload.
    func reply(_ value: UInt8) {
        onPacketReceived?(Data([0x00, 0x1d, 0x41, 0x2c, value]))
    }

    var sentSettings: [UInt8] { sent.map { $0[5] } }

    var sentWasWrite: [Bool] { sent.map { $0[4] == 0x01 } }

    func disconnect() {
        connectionState = .disconnected
        onConnectionStateChanged?(.disconnected)
    }

    func reconnect() {
        connectionState = .connected
        onConnectionStateChanged?(.connected)
    }

    /// Time for a full poll cycle to drain, with slack.
    static var cycleSettleTime: Duration {
        HeadsetSettingsSync.interPacketDelay * (LTCSetting.pollSequence.count + 3)
    }
}

@MainActor
@Suite("Settings sync against a fake transport")
struct HeadsetSettingsSyncBehaviourTests {

    @Test("A poll cycle reads all nine documented settings, in order")
    func pollCycleCoversEverySetting() async {
        let transport = FakeHeadsetTransport()
        let sync = HeadsetSettingsSync(transport: transport)

        sync.pollOnce()
        try? await Task.sleep(for: FakeHeadsetTransport.cycleSettleTime)

        #expect(transport.sentSettings == LTCSetting.pollSequence.map(\.rawValue))
        #expect(transport.sentWasWrite.allSatisfy { $0 == false })
    }

    /// Regression: a second write inside the lull cancelled `beginLull`'s pending
    /// restart, and polling never resumed. Found on hardware.
    @Test("Repeated writes leave polling running")
    func repeatedWritesKeepPolling() async throws {
        let transport = FakeHeadsetTransport()
        let sync = HeadsetSettingsSync(transport: transport)
        sync.startPolling()

        sync.write(.ltcMode, value: LTCMode.pushToTalk.rawValue)
        sync.write(.ltcMode, value: LTCMode.vad.rawValue)
        sync.write(.ltcMode, value: LTCMode.off.rawValue)
        try? await Task.sleep(for: FakeHeadsetTransport.cycleSettleTime)

        // Assert on traffic: an earlier version checked only the flag and passed
        // against the bug.
        let beforeLull = transport.sent.count
        try await Task.sleep(for: HeadsetSettingsSync.writeCooldown + .milliseconds(1200))

        #expect(transport.sent.count > beforeLull, "polling never resumed after the lull")
        #expect(sync.isPolling)
    }

    @Test("A write preempts queued polls")
    func writePreemptsPolls() async {
        let transport = FakeHeadsetTransport()
        let sync = HeadsetSettingsSync(transport: transport)

        sync.pollOnce()
        sync.write(.ltcVolume, value: 7)
        try? await Task.sleep(for: FakeHeadsetTransport.cycleSettleTime)

        let firstWrite = transport.sentWasWrite.firstIndex(of: true)
        #expect(firstWrite != nil)
        #expect(firstWrite == 0)
        // Queued reads are dropped, not deferred; they would report the old value.
        #expect(transport.sent.count < LTCSetting.pollSequence.count)
    }

    /// Regression: sending on a fixed 200ms timer credited slow replies to the
    /// next request, swapping values between fields.
    @Test("Only one request is outstanding at a time")
    func oneRequestInFlight() async throws {
        let transport = FakeHeadsetTransport()
        transport.autoRespond = false
        let sync = HeadsetSettingsSync(transport: transport)

        sync.pollOnce()
        // No reply, so nothing else may go out.
        try await Task.sleep(for: HeadsetSettingsSync.interPacketDelay * 3)
        #expect(transport.sent.count == 1)
    }

    @Test("An unanswered request times out instead of stalling the queue")
    func timeoutReleasesTheQueue() async throws {
        let transport = FakeHeadsetTransport()
        transport.autoRespond = false
        let sync = HeadsetSettingsSync(transport: transport)

        sync.pollOnce()
        try await Task.sleep(for: HeadsetSettingsSync.responseTimeout + .milliseconds(500))
        #expect(transport.sent.count > 1)
    }

    @Test("Values land on the setting that was actually requested")
    func responsesMapToTheirRequest() async {
        let transport = FakeHeadsetTransport()
        // Varied values, so a misattributed reply shows up in the wrong field.
        transport.values = [
            .predefinedTeam: 0x00,   // Alpha
            .securityKey: 0x00,      // Mike
            .rfChannel: 0x01,        // channel 2
            .networkId: 0x2a,        // 42
            .ltcMode: 0x01,          // PTT
            .vadThreshold: 0x05,
            .txPower: 0x02,          // -12 dBm
            .ltcVolume: 0x08,
            .zone: 0x01              // Latin America
        ]
        let sync = HeadsetSettingsSync(transport: transport)

        sync.pollOnce()
        try? await Task.sleep(for: FakeHeadsetTransport.cycleSettleTime)

        #expect(sync.settings.predefinedTeam == .alpha)
        #expect(sync.settings.securityKey == .MIKE)
        #expect(sync.settings.rfChannel == 2)
        #expect(sync.settings.networkId == 42)
        #expect(sync.settings.ltcMode == .pushToTalk)
        #expect(sync.settings.vadThreshold == 5)
        #expect(sync.settings.txPower == .minus12)
        #expect(sync.settings.ltcVolume == 8)
        #expect(sync.settings.zone == .latinAmerica)
    }

    @Test("Undocumented values are kept as raw bytes, not discarded")
    func undocumentedValuesRetained() async {
        let transport = FakeHeadsetTransport()
        let sync = HeadsetSettingsSync(transport: transport)

        // Undocumented 0x04: what the headset reports when its radio fails to start.
        transport.values = [.ltcMode: 0x04]
        sync.pollOnce()
        try? await Task.sleep(for: FakeHeadsetTransport.cycleSettleTime)

        #expect(sync.settings.ltcMode == nil)
        #expect(sync.settings.unrecognized[.ltcMode] == 0x04)
    }

    @Test("A custom team writes key, channel, then network ID in that order")
    func applyCustomTeamOrder() async throws {
        let transport = FakeHeadsetTransport()
        let sync = HeadsetSettingsSync(transport: transport)

        // TANGO matches no preset, so there is no team byte; it takes three writes.
        try sync.applyTeam(securityKey: .TANGO, rfChannel: 4, networkId: 200)
        try? await Task.sleep(for: FakeHeadsetTransport.cycleSettleTime)

        let writes = zip(transport.sentSettings, transport.sentWasWrite)
            .filter { $0.1 }.map { $0.0 }
        #expect(writes.prefix(3) == [
            LTCSetting.securityKey.rawValue,
            LTCSetting.rfChannel.rawValue,
            LTCSetting.networkId.rawValue
        ])
    }

    @Test("A preset team goes out as the single team command")
    func applyPresetTeamUsesTeamCommand() async throws {
        let transport = FakeHeadsetTransport()
        let sync = HeadsetSettingsSync(transport: transport)

        // Bravo. Three separate writes set the same values, but the headset plays
        // no confirmation and its team byte goes stale (Gentex, on hardware).
        try sync.applyTeam(securityKey: .MIKE, rfChannel: 3, networkId: 125)
        try? await Task.sleep(for: FakeHeadsetTransport.cycleSettleTime)

        let writes = zip(transport.sentSettings, transport.sentWasWrite)
            .filter { $0.1 }.map { $0.0 }
        #expect(writes == [LTCSetting.predefinedTeam.rawValue])
        #expect(transport.sent.first == Data([0x00, 0x1d, 0x40, 0x2c, 0x01, 0x00, 0x01, 0x01]))
    }

    @Test("An out-of-range team is rejected before anything is sent")
    func applyTeamRejectsBadValues() {
        let transport = FakeHeadsetTransport()
        let sync = HeadsetSettingsSync(transport: transport)

        #expect(throws: LTCProtocolError.self) {
            try sync.applyTeam(securityKey: .MIKE, rfChannel: 9, networkId: 100)
        }
        #expect(throws: LTCProtocolError.self) {
            try sync.applyTeam(securityKey: .MIKE, rfChannel: 1, networkId: 999)
        }
        #expect(transport.sent.isEmpty)
    }

    @Test("A rejected write is surfaced rather than silently swallowed")
    func writeFailureSurfaces() async {
        let transport = FakeHeadsetTransport()
        let sync = HeadsetSettingsSync(transport: transport)

        transport.writeStatus = 0x02   // LTC_BAD_VALUE
        sync.write(.txPower, value: 0x0a)
        try? await Task.sleep(for: .milliseconds(400))

        #expect(sync.lastFailure?.setting == .txPower)
        #expect(sync.lastFailure?.reason == .rejected)
    }

    @Test("Disconnecting halts traffic and clears cached settings")
    func disconnectClearsState() async {
        let transport = FakeHeadsetTransport()
        let sync = HeadsetSettingsSync(transport: transport)

        transport.values = [.networkId: 0x2a]
        sync.pollOnce()
        try? await Task.sleep(for: FakeHeadsetTransport.cycleSettleTime)
        #expect(sync.settings.networkId != nil)

        transport.disconnect()
        try? await Task.sleep(for: .milliseconds(100))

        // Stale values on screen are worse than none.
        #expect(sync.settings == HeadsetSettingsState())
        #expect(!sync.isPolling)
    }
}

// MARK: - Optimistic Writes

/// Confirmation takes 3–5s (lull + next poll), so changes show at once and roll
/// back when the headset disagrees. A missed rollback leaves a value on screen
/// the headset never accepted.
@MainActor
@Suite("Optimistic writes")
struct OptimisticWriteTests {

    /// Lull + heartbeat restart + one full poll cycle.
    private static var reconcileTime: Duration {
        HeadsetSettingsSync.writeCooldown + FakeHeadsetTransport.cycleSettleTime + .milliseconds(600)
    }

    /// Poll once so `confirmed` has a rollback target.
    private func seed(_ sync: HeadsetSettingsSync) async {
        sync.pollOnce()
        try? await Task.sleep(for: FakeHeadsetTransport.cycleSettleTime)
    }

    // MARK: Immediate feedback

    @Test("A change is on screen before the headset has said anything")
    func writeShowsImmediately() {
        let transport = FakeHeadsetTransport()
        let sync = HeadsetSettingsSync(transport: transport)

        sync.write(.ltcVolume, value: 7)

        // No await: the value must be visible on the same tick as the tap.
        #expect(sync.settings.ltcVolume == 7)
        #expect(sync.confirmed.ltcVolume == nil, "the headset has not reported anything yet")
    }

    @Test("Joining a team moves every setting it touches at once")
    func applyTeamShowsImmediately() throws {
        let transport = FakeHeadsetTransport()
        let sync = HeadsetSettingsSync(transport: transport)

        try sync.applyTeam(securityKey: .MIKE, rfChannel: 3, networkId: 125)

        #expect(sync.settings.securityKey == .MIKE)
        #expect(sync.settings.rfChannel == 3)
        #expect(sync.settings.networkId == 125)
        // Drives the Active badge.
        #expect(sync.settings.activePredefinedTeam == .bravo)
        // Team byte is predicted too, so it agrees with the three settings.
        #expect(sync.settings.predefinedTeam == .bravo)
    }

    @Test("A team the headset refuses takes its predicted settings back with it")
    func refusedTeamRevertsEverything() async throws {
        let transport = FakeHeadsetTransport()
        transport.values = [.predefinedTeam: 0x00, .securityKey: 0x00,
                            .rfChannel: 0x01, .networkId: 100]
        let sync = HeadsetSettingsSync(transport: transport)
        await seed(sync)
        #expect(sync.settings.activePredefinedTeam == .alpha)

        transport.writeStatus = 0x02   // LTC_BAD_VALUE
        try sync.applyTeam(securityKey: .MIKE, rfChannel: 3, networkId: 125)
        #expect(sync.settings.activePredefinedTeam == .bravo, "optimistic, before the reply")

        try? await Task.sleep(for: FakeHeadsetTransport.cycleSettleTime)

        // All four revert together, not three waiting on a poll.
        #expect(sync.settings.activePredefinedTeam == .alpha)
        #expect(sync.settings.securityKey == .MIKE)
        #expect(sync.settings.rfChannel == 2)
        #expect(sync.settings.networkId == 100)
    }

    // MARK: Confirmation

    @Test("A change the headset agrees with survives reconciliation")
    func agreedChangeSticks() async throws {
        let transport = FakeHeadsetTransport()
        transport.values[.ltcVolume] = 4
        let sync = HeadsetSettingsSync(transport: transport)
        await seed(sync)
        #expect(sync.confirmed.ltcVolume == 4)

        transport.values[.ltcVolume] = 7    // the headset will report the new value
        sync.write(.ltcVolume, value: 7)
        try await Task.sleep(for: Self.reconcileTime)

        #expect(sync.confirmed.ltcVolume == 7, "the poll should have caught up")
        #expect(sync.settings.ltcVolume == 7)
        #expect(sync.lastFailure == nil)
    }

    // MARK: Rollback

    /// PTT is ACKed with LTC_NO_ERR, then reads back as undocumented `0x04`.
    /// An ACK is not proof.
    @Test("An acknowledged change that never takes effect is rolled back")
    func acknowledgedButNotAppliedReverts() async throws {
        let transport = FakeHeadsetTransport()
        transport.values[.ltcMode] = LTCMode.off.rawValue
        let sync = HeadsetSettingsSync(transport: transport)
        await seed(sync)
        #expect(sync.confirmed.ltcMode == .off)

        transport.values[.ltcMode] = 0x04
        sync.write(.ltcMode, value: LTCMode.pushToTalk.rawValue)
        #expect(sync.settings.ltcMode == .pushToTalk, "shown optimistically first")

        try await Task.sleep(for: Self.reconcileTime)

        #expect(sync.settings.ltcMode != .pushToTalk, "must not claim a mode the headset refused")
        #expect(sync.lastFailure?.setting == .ltcMode)
        #expect(sync.lastFailure?.reason == .notApplied)
    }

    @Test("A rejected change falls back to the value the headset reported")
    func rejectedChangeRevertsToConfirmedValue() async throws {
        let transport = FakeHeadsetTransport()
        transport.values[.ltcVolume] = 4
        let sync = HeadsetSettingsSync(transport: transport)
        await seed(sync)

        transport.writeStatus = 0x02    // LTC_BAD_VALUE
        sync.write(.ltcVolume, value: 9)
        #expect(sync.settings.ltcVolume == 9)

        try await Task.sleep(for: .milliseconds(400))

        #expect(sync.settings.ltcVolume == 4, "reverted to what the headset last reported")
        #expect(sync.lastFailure?.reason == .rejected)
        #expect(sync.lastFailure?.revertedTo == "4")
    }

    @Test("A change that cannot be sent is rolled back at once")
    func unsendableChangeReverts() async throws {
        let transport = FakeHeadsetTransport()
        transport.values[.ltcVolume] = 4
        let sync = HeadsetSettingsSync(transport: transport)
        await seed(sync)

        transport.failSends = true
        sync.write(.ltcVolume, value: 9)
        try await Task.sleep(for: .milliseconds(400))

        #expect(sync.settings.ltcVolume == 4)
        #expect(sync.lastFailure?.reason == .couldNotSend)
    }

    /// An unanswered write cannot be assumed to have landed.
    @Test("A change the headset never answers is rolled back after the timeout")
    func unansweredChangeReverts() async throws {
        let transport = FakeHeadsetTransport()
        transport.values[.ltcVolume] = 4
        let sync = HeadsetSettingsSync(transport: transport)
        await seed(sync)

        transport.autoRespond = false
        sync.write(.ltcVolume, value: 9)
        #expect(sync.settings.ltcVolume == 9)

        try await Task.sleep(for: HeadsetSettingsSync.responseTimeout + .milliseconds(400))

        #expect(sync.settings.ltcVolume == 4)
        #expect(sync.lastFailure?.reason == .noResponse)
    }

    @Test("Disconnecting drops pending changes without blaming the headset")
    func disconnectClearsPendingChanges() async throws {
        let transport = FakeHeadsetTransport()
        let sync = HeadsetSettingsSync(transport: transport)

        sync.write(.ltcVolume, value: 7)
        #expect(sync.settings.ltcVolume == 7)

        transport.disconnect()
        try await Task.sleep(for: .milliseconds(100))

        #expect(sync.settings == HeadsetSettingsState())
        // A dropped link is not a refusal.
        #expect(sync.lastFailure == nil)
    }
}

// MARK: - Losing the headset

@Suite("Navigation when the headset drops")
struct HeadsetOnlyRouteTests {

    @Test("Screens that need a headset are the ones that talk to it")
    func routeClassification() {
        #expect(SettingsRoute.regions.requiresHeadset)
        #expect(SettingsRoute.vadThreshold.requiresHeadset)
        #expect(SettingsRoute.ltcVolume.requiresHeadset)
        #expect(SettingsRoute.txPower.requiresHeadset)

        #expect(!SettingsRoute.appearance.requiresHeadset)
        #expect(!SettingsRoute.orientation.requiresHeadset)
        #expect(!SettingsRoute.permissions.requiresHeadset)
        #expect(!SettingsRoute.userManuals.requiresHeadset)
    }

    @Test("Popping leaves the deepest screen that still works")
    func popsToNearestUsableScreen() {
        var path: [SettingsRoute] = [.appearance, .ltcVolume]
        path.popHeadsetOnlyScreens()
        #expect(path == [.appearance])
    }

    @Test("Everything above a headset-only screen goes with it")
    func popsRoutesPushedFromADeadScreen() {
        // `.permissions` needs no headset, but backing out of it lands on
        // `.regions`, which does.
        var path: [SettingsRoute] = [.appearance, .regions, .permissions]
        path.popHeadsetOnlyScreens()
        #expect(path == [.appearance])
    }

    @Test("A path that needs no headset is left alone")
    func leavesUsablePathsUntouched() {
        var path: [SettingsRoute] = [.appearance, .orientation, .userManuals]
        path.popHeadsetOnlyScreens()
        #expect(path == [.appearance, .orientation, .userManuals])
    }

    @Test("Popping the root is a no-op")
    func handlesEmptyPath() {
        var path: [SettingsRoute] = []
        path.popHeadsetOnlyScreens()
        #expect(path.isEmpty)
    }

    @Test("A headset-only screen at the root pops all the way back")
    func popsToRoot() {
        var path: [SettingsRoute] = [.txPower]
        path.popHeadsetOnlyScreens()
        #expect(path.isEmpty)
    }
}

@Suite("Permission status")
struct PermissionStatusTests {

    @Test("Only an allowed permission is usable")
    func onlyAllowedIsUsable() {
        #expect(PermissionStatus.allowed.isUsable)
        #expect(!PermissionStatus.denied.isUsable)
        #expect(!PermissionStatus.restricted.isUsable)
        #expect(!PermissionStatus.notRequested.isUsable)
    }

    @Test("Every status says something the user can read")
    func everyStatusIsLabelled() {
        let statuses: [PermissionStatus] = [.allowed, .denied, .restricted, .notRequested]
        #expect(Set(statuses.map(\.label)).count == statuses.count)
        #expect(statuses.allSatisfy { !$0.label.isEmpty })
    }
}

@Suite("Reconnecting after a drop")
struct ConnectionRetryTests {

    @Test("A failed connection is a reason to retry, not a reason to stop")
    func failureAllowsAnotherAttempt() {
        // Power-off leaves `.failed(.disconnected)`. Treating it as final stranded
        // the app on the no-headset screen after the headset came back.
        #expect(HeadsetConnectionState.failed(.disconnected(detail: "off")).allowsNewConnection)
        #expect(HeadsetConnectionState.failed(.noHeadsetFound).allowsNewConnection)
        #expect(HeadsetConnectionState.failed(.connectionFailed(detail: "x")).allowsNewConnection)
        #expect(HeadsetConnectionState.failed(.serviceNotFound).allowsNewConnection)
        #expect(HeadsetConnectionState.disconnected.allowsNewConnection)
    }

    @Test("An attempt already under way is left to finish")
    func inFlightAttemptsBlockAnother() {
        #expect(!HeadsetConnectionState.connecting.allowsNewConnection)
        #expect(!HeadsetConnectionState.connected.allowsNewConnection)
    }

    @Test("Only a live link counts as connected")
    func isConnectedIsNarrow() {
        #expect(HeadsetConnectionState.connected.isConnected)
        #expect(!HeadsetConnectionState.connecting.isConnected)
        #expect(!HeadsetConnectionState.disconnected.isConnected)
        #expect(!HeadsetConnectionState.failed(.noHeadsetFound).isConnected)
    }
}

// MARK: - Integration: the whole stack against known hardware behavior

/// Rev 3 C2. Multi-step sequences across the transport seam, each reproducing
/// something the hardware actually did.
@MainActor
@Suite("Integration: settings sync over the transport")
struct BluetoothSettingsIntegrationTests {

    /// Lull + heartbeat restart + one full poll cycle. Reconciliation happens on
    /// the first poll after the cooldown; anything shorter asserts too early.
    private static var reconcileTime: Duration {
        HeadsetSettingsSync.writeCooldown + FakeHeadsetTransport.cycleSettleTime + .milliseconds(600)
    }

    /// Time for the priority queue to hand its first packet to the transport.
    private static let dispatchTime: Duration = .milliseconds(300)

    /// Zone (`0x0a`) is ACKed and never applied, over BLE, Classic, and the
    /// headset's own menu (Gentex, Aug 25 2026). The app must not claim it worked.
    @Test("A zone the headset acknowledges but ignores does not stay on screen")
    func zoneWriteRollsBackWhenTheHeadsetIgnoresIt() async throws {
        let transport = FakeHeadsetTransport()
        let sync = HeadsetSettingsSync(transport: transport)

        // Stuck in North America.
        transport.values[.zone] = Region.northAmerica.ltcByte
        sync.pollOnce()
        try await Task.sleep(for: FakeHeadsetTransport.cycleSettleTime)
        #expect(sync.confirmed.zone == .northAmerica)

        sync.write(.zone, value: Region.eurasia.ltcByte)
        #expect(sync.settings.zone == .eurasia)

        // The write's lull schedules the settling poll; starting a heartbeat here
        // would push that poll past the deadline.
        try await Task.sleep(for: Self.reconcileTime)

        #expect(sync.settings.zone == .northAmerica, "the app kept a change the headset discarded")
        #expect(sync.confirmed.zone == .northAmerica)
        #expect(sync.lastFailure?.setting == .zone)
        #expect(sync.lastFailure?.reason == .notApplied)
    }

    /// The `0x04` latch, docs/ble-protocol.md §7. Only a battery pull cleared it.
    @Test("An LTC mode that latches to an undocumented value is rolled back and kept visible")
    func ltcModeLatchIsReportedRatherThanHidden() async throws {
        let transport = FakeHeadsetTransport()
        let sync = HeadsetSettingsSync(transport: transport)

        transport.values[.ltcMode] = LTCMode.off.rawValue
        sync.pollOnce()
        try await Task.sleep(for: FakeHeadsetTransport.cycleSettleTime)

        // ACKed, then reads back 0x04.
        transport.values[.ltcMode] = 0x04
        sync.write(.ltcMode, value: LTCMode.pushToTalk.rawValue)
        #expect(sync.settings.ltcMode == .pushToTalk)

        try await Task.sleep(for: Self.reconcileTime)

        #expect(sync.settings.ltcMode == nil, "0x04 is not a mode the app may pretend to understand")
        #expect(sync.confirmed.unrecognized[.ltcMode] == 0x04, "the raw byte must survive for diagnostics")
        #expect(sync.lastFailure?.setting == .ltcMode)
    }

    /// Diagnostics read `confirmed`, never the optimistic overlay: the packet
    /// console is the proof of what the headset said.
    @Test("Diagnostics show what the headset reported, not what the user asked for")
    func confirmedAndSettingsDivergeWhileAWriteIsPending() async throws {
        let transport = FakeHeadsetTransport()
        let sync = HeadsetSettingsSync(transport: transport)

        transport.values[.ltcVolume] = 3
        sync.pollOnce()
        try await Task.sleep(for: FakeHeadsetTransport.cycleSettleTime)

        transport.autoRespond = false
        sync.write(.ltcVolume, value: 9)

        #expect(sync.settings.ltcVolume == 9, "the UI answers the tap at once")
        #expect(sync.confirmed.ltcVolume == 3, "the headset has not said anything yet")
    }

    /// Headset power-cycled mid-session (Aug 25 2026). Pending changes must not
    /// survive the gap.
    @Test("A drop clears pending changes, and reconnecting reads the headset afresh")
    func pendingChangesDoNotSurviveADrop() async throws {
        let transport = FakeHeadsetTransport()
        let sync = HeadsetSettingsSync(transport: transport)

        transport.values[.ltcVolume] = 2
        sync.pollOnce()
        try await Task.sleep(for: FakeHeadsetTransport.cycleSettleTime)

        transport.autoRespond = false
        sync.write(.ltcVolume, value: 8)
        #expect(sync.settings.ltcVolume == 8)

        transport.disconnect()
        try await Task.sleep(for: .milliseconds(100))
        #expect(sync.settings == HeadsetSettingsState(), "a dropped link leaves nothing behind")
        #expect(sync.lastFailure == nil, "the link going away is not the headset refusing")

        // The headset comes back on a different volume than it left.
        transport.autoRespond = true
        transport.values[.ltcVolume] = 5
        transport.reconnect()
        sync.pollOnce()
        try await Task.sleep(for: FakeHeadsetTransport.cycleSettleTime)

        #expect(sync.confirmed.ltcVolume == 5, "state after a reconnect comes from the headset")
    }

    /// Peter's bug: a preset is one team command, and its implied settings come
    /// back from the headset, not from the app's prediction.
    @Test("A preset join is one command, and the headset supplies what follows")
    func presetJoinIsOneCommandAndReconcilesFromHardware() async throws {
        let preset = PredefinedTeam.allCases[0]
        let transport = FakeHeadsetTransport()
        let sync = HeadsetSettingsSync(transport: transport)

        // What the headset reports after adopting the team.
        transport.values[.predefinedTeam] = preset.rawValue
        transport.values[.securityKey] = preset.securityKey.ltcByte
        transport.values[.rfChannel] = LTCRFChannel.byte(forChannel: preset.rfChannel) ?? 0
        transport.values[.networkId] = LTCNetworkID.byte(for: preset.networkId) ?? 0

        try sync.applyTeam(
            securityKey: preset.securityKey,
            rfChannel: preset.rfChannel,
            networkId: preset.networkId
        )

        try await Task.sleep(for: Self.dispatchTime)

        #expect(transport.sentWasWrite.first == true)
        #expect(transport.sentSettings.first == LTCSetting.predefinedTeam.rawValue)
        #expect(transport.sentWasWrite.filter { $0 }.count == 1, "a preset is one command, not three")

        try await Task.sleep(for: Self.reconcileTime)

        #expect(sync.confirmed.predefinedTeam == preset)
        #expect(sync.confirmed.securityKey == preset.securityKey)
        #expect(sync.lastFailure == nil)
    }

    /// One refused write must not roll back a neighbor the headset accepted.
    @Test("Two changes in flight resolve independently")
    func concurrentWritesResolveSeparately() async throws {
        let transport = FakeHeadsetTransport()
        let sync = HeadsetSettingsSync(transport: transport)

        transport.values[.ltcVolume] = 1
        transport.values[.vadThreshold] = 1
        sync.pollOnce()
        try await Task.sleep(for: FakeHeadsetTransport.cycleSettleTime)

        // Volume takes; VAD threshold is ignored by the headset.
        transport.values[.ltcVolume] = 7
        sync.write(.ltcVolume, value: 7)
        sync.write(.vadThreshold, value: 9)

        try await Task.sleep(for: Self.reconcileTime)

        #expect(sync.settings.ltcVolume == 7, "an accepted change must survive a neighbour's failure")
        #expect(sync.settings.vadThreshold == 1, "a refused change must roll back")
    }

    /// Replies match requests, not queue positions; mismatching them was a real bug.
    @Test("Replies are matched to the setting that was asked about")
    func repliesAreNotMisattributed() async throws {
        let transport = FakeHeadsetTransport()
        let sync = HeadsetSettingsSync(transport: transport)

        transport.values = [
            .ltcVolume: 4,
            .vadThreshold: 6,
            .txPower: TxPower.allCases[0].rawValue
        ]

        sync.pollOnce()
        try await Task.sleep(for: FakeHeadsetTransport.cycleSettleTime)

        #expect(sync.confirmed.ltcVolume == 4)
        #expect(sync.confirmed.vadThreshold == 6)
        #expect(sync.confirmed.txPower == TxPower.allCases[0])
    }

    /// The lull keeps an in-flight poll from contradicting a write, but it must
    /// end or the UI freezes on stale values.
    @Test("Polling stops for a write and starts again on its own")
    func theLullEndsWithoutHelp() async throws {
        let transport = FakeHeadsetTransport()
        let sync = HeadsetSettingsSync(transport: transport)
        sync.startPolling()
        try await Task.sleep(for: FakeHeadsetTransport.cycleSettleTime)

        sync.write(.ltcVolume, value: 6)
        let duringLull = transport.sent.count

        try await Task.sleep(for: Self.reconcileTime)

        #expect(transport.sent.count > duringLull, "polling never came back after the write")
        #expect(sync.isPolling)
    }
}

// MARK: - Branding

@Suite("Typography")
struct TypographyTests {

    /// `Font.custom` silently falls back to the system font on an unknown name.
    /// Four of eight raw values, `.regular` included, were wrong for months.
    /// A nil from `UIFont(name:size:)` means the text will not be IBM Plex Sans.
    @Test("every weight resolves to a registered face", arguments: [
        IBMPlexSansWeight.thin,
        .extraLight,
        .light,
        .regular,
        .text,
        .medium,
        .semiBold,
        .bold
    ])
    func weightResolves(_ weight: IBMPlexSansWeight) {
        let font = UIFont(name: weight.rawValue, size: 18)
        #expect(
            font != nil,
            """
            No registered font named "\(weight.rawValue)". Either the face is \
            missing from UIAppFonts in Info.plist, or the raw value does not \
            match the PostScript name the .ttf declares. Dump the real name \
            with name-table ID 6 and use that verbatim.
            """
        )
        #expect(font?.fontName == weight.rawValue)
    }

    /// Guards against a name that resolves to some other installed face.
    @Test("resolved faces belong to the IBM Plex Sans family", arguments: [
        IBMPlexSansWeight.thin,
        .extraLight,
        .light,
        .regular,
        .text,
        .medium,
        .semiBold,
        .bold
    ])
    func weightBelongsToFamily(_ weight: IBMPlexSansWeight) throws {
        let font = try #require(UIFont(name: weight.rawValue, size: 18))
        #expect(font.familyName.hasPrefix("IBM Plex Sans"))
    }
}

@Suite("Brand colour")
struct BrandColourTests {

    /// Must match Android's `OpsCoreRed`. `Color.red` is the system red, not this.
    @Test("opsCoreRed is #E31B23")
    func opsCoreRedMatchesBrand() throws {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        UIColor(Color.opsCoreRed).getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        #expect(Int((red * 255).rounded()) == 0xE3)
        #expect(Int((green * 255).rounded()) == 0x1B)
        #expect(Int((blue * 255).rounded()) == 0x23)
        #expect(alpha == 1)
    }
}
