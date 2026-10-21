//
//  LTCValues.swift
//  Gentex_iOS
//
//  Byte mappings for every LTC setting value, per
//  Gentex's "LTC Configuration Commands (BLE)" document (July 27, 2026)
//
//  Existing models (Region, SecurityKey) get extensions rather than duplicate types.
//

import Foundation

// MARK: - LTC Mode

/// Setting `0x05`.
enum LTCMode: UInt8, CaseIterable, Sendable {
    case off = 0x00
    case pushToTalk = 0x01
    case vad = 0x02

    // 0x03 All Hands: not in the Gentex BLE doc and disabled on Android
    // (`models/HeadsetSettings.kt`). Keep it out of the UI.
    // case allHands = 0x03

    var displayName: String {
        switch self {
        case .off: return "LTC Off"
        case .pushToTalk: return "Push-to-talk"
        case .vad: return "VOX/VAD"
        }
    }
}

// MARK: - Tx Power

/// Setting `0x07`, per the Gentex BLE doc. Android's 11-value table (−40…+10 dBm) is
/// likely older firmware; the doc wins (plan decision 0.2). Unverified on hardware:
/// writing `0x0a` should return `LTC_BAD_VALUE`; `LTC_NO_ERR` means Android was closer.
enum TxPower: UInt8, CaseIterable, Sendable {
    case minus18 = 0x00
    case minus15 = 0x01
    case minus12 = 0x02
    case minus9  = 0x03
    case minus6  = 0x04
    case minus3  = 0x05
    case zero    = 0x06
    case plus3   = 0x07
    case plus6   = 0x08
    case plus10  = 0x09

    /// +6 → +10 is a 4 dBm step. Matches the doc; not a typo.
    var displayName: String {
        switch self {
        case .minus18: return "-18dBm"
        case .minus15: return "-15dBm"
        case .minus12: return "-12dBm"
        case .minus9:  return "-9dBm"
        case .minus6:  return "-6dBm"
        case .minus3:  return "-3dBm"
        case .zero:    return "0dBm"
        case .plus3:   return "+3dBm"
        case .plus6:   return "+6dBm"
        case .plus10:  return "+10dBm"
        }
    }
}

// MARK: - Predefined Teams

/// Setting `0x00`. Each team fixes key, channel, and network ID; if the reported
/// three don't match the reported team, a custom team is in use.
enum PredefinedTeam: UInt8, CaseIterable, Sendable {
    case alpha    = 0x00
    case bravo    = 0x01
    case charlie  = 0x02
    case delta    = 0x03
    case jointOps = 0x04

    var displayName: String {
        switch self {
        case .alpha: return "Alpha"
        case .bravo: return "Bravo"
        case .charlie: return "Charlie"
        case .delta: return "Delta"
        case .jointOps: return "Joint Ops"
        }
    }

    var securityKey: SecurityKey { .MIKE }

    /// RF channel as displayed (1-based), not the wire byte.
    var rfChannel: Int {
        switch self {
        case .alpha: return 2
        case .bravo: return 3
        case .charlie: return 4
        case .delta: return 5
        case .jointOps: return 1
        }
    }

    var networkId: Int {
        switch self {
        case .alpha: return 100
        case .bravo: return 125
        case .charlie: return 150
        case .delta: return 175
        case .jointOps: return 200
        }
    }

    /// `nil` means a custom team.
    static func matching(securityKey: SecurityKey, rfChannel: Int, networkId: Int) -> PredefinedTeam? {
        allCases.first {
            $0.securityKey == securityKey && $0.rfChannel == rfChannel && $0.networkId == networkId
        }
    }
}

// MARK: - RF Channel

/// Wire is 0-based, UI is 1-based. Channels 1–5 only: Gentex dropped Eurasia's 6–11
/// (July 28, 2026), though firmware still accepts them.
enum LTCRFChannel {
    static let supportedRange = 1...5

    static func byte(forChannel channel: Int) -> UInt8? {
        guard supportedRange.contains(channel) else { return nil }
        return UInt8(channel - 1)
    }

    /// `nil` for channels 6–11 set elsewhere, rather than showing a wrong value.
    static func channel(forByte byte: UInt8) -> Int? {
        let channel = Int(byte) + 1
        return supportedRange.contains(channel) ? channel : nil
    }
}

// MARK: - Region ↔ Zone

extension Region {
    /// Zone setting (`0x0a`). The headset says "zone"; the app says "region".
    var ltcByte: UInt8 {
        switch self {
        case .northAmerica: return 0x00
        case .latinAmerica: return 0x01
        case .eurasia:      return 0x02
        }
    }

    init?(ltcByte: UInt8) {
        switch ltcByte {
        case 0x00: self = .northAmerica
        case 0x01: self = .latinAmerica
        case 0x02: self = .eurasia
        default: return nil
        }
    }
}

// MARK: - Security Key

extension SecurityKey {
    /// Setting `0x01`.
    var ltcByte: UInt8 {
        switch self {
        case .MIKE:     return 0x00
        case .NOVEMBER: return 0x01
        case .OSCAR:    return 0x02
        case .PAPA:     return 0x03
        case .QUEBEC:   return 0x04
        case .ROMEO:    return 0x05
        case .SIERRA:   return 0x06
        case .TANGO:    return 0x07
        case .UNIFORM:  return 0x08
        case .VICTOR:   return 0x09
        }
    }

    init?(ltcByte: UInt8) {
        guard let match = Self.allCases.first(where: { $0.ltcByte == ltcByte }) else {
            return nil
        }
        self = match
    }
}

// MARK: - Bounded Scalar Settings

/// VAD threshold (`0x06`) and LTC volume (`0x08`).
enum LTCLevel {
    static let range = 0...10

    static func byte(for level: Int) -> UInt8? {
        guard range.contains(level) else { return nil }
        return UInt8(level)
    }

    static func level(forByte byte: UInt8) -> Int? {
        let level = Int(byte)
        return range.contains(level) ? level : nil
    }
}

/// Network ID (`0x04`).
enum LTCNetworkID {
    static let range = 0...255

    static func byte(for networkId: Int) -> UInt8? {
        guard range.contains(networkId) else { return nil }
        return UInt8(networkId)
    }
}
