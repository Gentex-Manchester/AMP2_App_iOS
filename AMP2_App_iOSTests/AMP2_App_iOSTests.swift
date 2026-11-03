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
@testable import AMP_2_0_App

// MARK: - Region Rules

@Suite("Region Rules")
struct RegionRulesTests {

    @Test("init(from:) is case-insensitive for raw values and display names")
    func caseInsensitiveInit() {
        #expect(Region(from: "Americas") == .americas)
        #expect(Region(from: "AMERICAS") == .americas)
        #expect(Region(from: "americas") == .americas)
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
        #expect(Region.americas.displayName == "Americas")
        #expect(Region.eurasia.displayName == "Eurasia")
    }
}

// MARK: - SecurityKey

@Suite("SecurityKey")
struct SecurityKeyTests {

    @Test("All 11 pkeys are present")
    func allKeysPresent() {
        #expect(SecurityKey.all.count == 11)
        let expected = ["Mike", "November", "Oscar", "Papa", "Quebec",
                        "Romeo", "Sierra", "Tango", "Uniform", "Victor",
                        "Custom"]
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
        #expect(String(data: data, encoding: .utf8) == "\"Tango\"")
        let decoded = try JSONDecoder().decode(SecurityKey.self, from: data)
        #expect(decoded == .TANGO)
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
        #expect(LTCPacket.read(.team) == Data([0x00, 0x1d, 0x40, 0x2c, 0x00, 0x00, 0x01]))
    }

    @Test("Write command matches the documented example byte for byte")
    func writeCommandMatchesDoc() {
        // "00 1d 40 2c 01 00 01 00" — set the pre-defined team to Alpha.
        #expect(
            LTCPacket.write(.team, value: Team.alpha.rawValue)
                == Data([0x00, 0x1d, 0x40, 0x2c, 0x01, 0x00, 0x01, 0x00])
        )
    }

    @Test("Every documented poll command encodes exactly as published")
    func pollSequenceMatchesDoc() {
        let expected: [LTCSetting: [UInt8]] = [
            .team:              [0x00, 0x1d, 0x40, 0x2c, 0x00, 0x00, 0x01],
            .securityKey:       [0x00, 0x1d, 0x40, 0x2c, 0x00, 0x01, 0x01],
            .customSecurityKey: [0x00, 0x1d, 0x40, 0x2c, 0x00, 0x02, 0x20],
            .ltcMode:           [0x00, 0x1d, 0x40, 0x2c, 0x00, 0x05, 0x01],
            .vadThreshold:      [0x00, 0x1d, 0x40, 0x2c, 0x00, 0x06, 0x01],
            .txPower:           [0x00, 0x1d, 0x40, 0x2c, 0x00, 0x07, 0x01],
            .ltcVolume:         [0x00, 0x1d, 0x40, 0x2c, 0x00, 0x08, 0x01],
            .zone:              [0x00, 0x1d, 0x40, 0x2c, 0x00, 0x0a, 0x01]
        ]
        for (setting, bytes) in expected {
            if (setting == .customSecurityKey) {
                #expect(LTCPacket.read(setting, expectedLength: 32) == Data(bytes))
            }
            else {
                #expect(LTCPacket.read(setting) == Data(bytes))
            }
        }
        // customSecurityKey is unimplemented in firmware, so it is not polled.
        #expect(Set(LTCSetting.pollSequence) == Set(expected.keys))
        #expect(LTCSetting.pollSequence.count == 8)
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
        let packet = LTCPacket.write(.customSecurityKey, payload: [0xaa, 0xbb, 0xcc])
        #expect(packet == Data([0x00, 0x1d, 0x40, 0x2c, 0x01, 0x02, 0x03, 0xaa, 0xbb, 0xcc]))
    }

    // MARK: Response Decoding

    @Test("Read response yields the documented value")
    func readResponseMatchesDoc() throws {
        // "00 1d 41 2c 02" — the current team is Charlie.
        let response = try LTCResponse.parse(Data([0x00, 0x1d, 0x41, 0x2c, 0x02]))
        #expect(try response.readValue()[0] == 0x02)
        #expect(Team(rawValue: try response.readValue()[0]) == .charlie)
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

    @Test("Security keys map to bytes 0x00 through 0x0a and back")
    func securityKeyBytes() {
        #expect(SecurityKey.MIKE.ltcByte == 0x00)
        #expect(SecurityKey.CUSTOM.ltcByte == 0x0a)
        for key in SecurityKey.allCases {
            #expect(SecurityKey(ltcByte: key.ltcByte) == key)
        }
        #expect(SecurityKey(ltcByte: 0x0b) == nil)
    }

    @Test("Regions map to the headset's zone bytes and back")
    func zoneBytes() {
        #expect(Region.americas.ltcByte == 0x00)
        #expect(Region.eurasia.ltcByte == 0x01)
        for region in Region.allCases {
            #expect(Region(ltcByte: region.ltcByte) == region)
        }
        #expect(Region(ltcByte: 0x02) == nil)
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

    // MARK: Hex Formatting

    @Test("Hex formatting matches the Android logger's format")
    func hexFormatting() {
        #expect(Data([0x00, 0x1d, 0x40, 0x2c]).ltcHexString == "00 1D 40 2C")
        #expect(Data().ltcHexString == "")
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
        let names = ["Gentex_AMP2.0_PROTO-123456", "AMP 2.0", "amp2.0", "GENTEX AMP"]
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

    @Test("Completeness requires every setting")
    func completeness() {
        var state = HeadsetSettingsState(
            team: .alpha, securityKey: .MIKE, ltcMode: .pushToTalk,
            vadThreshold: 5, txPower: .zero, ltcVolume: 5
        )
        #expect(!state.isComplete)   // zone still missing
        state.zone = .americas
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
        let names = Team.allCases.map(\.displayName)
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
            .team: 0x00,   // Alpha
            .securityKey: 0x00,      // Mike
            .ltcMode: 0x01,          // PTT
            .vadThreshold: 0x05,
            .txPower: 0x02,          // -12 dBm
            .ltcVolume: 0x08,
            .zone: 0x01              // Eurasia
        ]
        let sync = HeadsetSettingsSync(transport: transport)

        sync.pollOnce()
        try? await Task.sleep(for: FakeHeadsetTransport.cycleSettleTime)

        #expect(sync.settings.team == .alpha)
        #expect(sync.settings.securityKey == .MIKE)
        #expect(sync.settings.ltcMode == .pushToTalk)
        #expect(sync.settings.vadThreshold == 5)
        #expect(sync.settings.txPower == .minus12)
        #expect(sync.settings.ltcVolume == 8)
        #expect(sync.settings.zone == .eurasia)
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
        #expect(sync.settings.unrecognized[.ltcMode] == [0x04])
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

        transport.values = [.ltcVolume: 0x05]
        sync.pollOnce()
        try? await Task.sleep(for: FakeHeadsetTransport.cycleSettleTime)
        #expect(sync.settings.ltcVolume != nil)

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
        transport.values[.zone] = Region.americas.ltcByte
        sync.pollOnce()
        try await Task.sleep(for: FakeHeadsetTransport.cycleSettleTime)
        #expect(sync.confirmed.zone == .americas)

        sync.write(.zone, value: Region.eurasia.ltcByte)
        #expect(sync.settings.zone == .eurasia)

        // The write's lull schedules the settling poll; starting a heartbeat here
        // would push that poll past the deadline.
        try await Task.sleep(for: Self.reconcileTime)

        #expect(sync.settings.zone == .americas, "the app kept a change the headset discarded")
        #expect(sync.confirmed.zone == .americas)
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
        #expect(sync.confirmed.unrecognized[.ltcMode] == [0x04], "the raw byte must survive for diagnostics")
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
        UIColor(Color.accent).getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        #expect(Int((red * 255).rounded()) == 0xE3)
        #expect(Int((green * 255).rounded()) == 0x1B)
        #expect(Int((blue * 255).rounded()) == 0x23)
        #expect(alpha == 1)
    }
}
