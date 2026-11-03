//
//  LTCPacket.swift
//  AMP2_App_iOS
//
//  Encodes LTC configuration commands for the AMP 2.0 headset.
//  Wire format: Gentex's "LTC Configuration Commands (BLE)" document (July 27, 2026)
//
//  Not the Android format. Android frames each packet for SPP (`FF 03 01 <len>`
//  header, XOR checksum); over BLE GATT the headset wants the bare packet.
//  Do not port `PacketBuilder.kt`.
//

import Foundation

// MARK: - Settings

/// Headset configuration settings, addressed by byte.
///
/// `0x09` (frequency hopping) is used by Android but not in the Gentex BLE doc, so it is omitted.
enum LTCSetting: UInt8, CaseIterable, Sendable {
    case team              = 0x00
    case securityKey       = 0x01
    case customSecurityKey = 0x02
    case rfChannel         = 0x03
    case networkId         = 0x04
    case ltcMode           = 0x05
    case vadThreshold      = 0x06
    case txPower           = 0x07
    case ltcVolume         = 0x08
    case zone              = 0x0a

    /// Heartbeat poll order, per the doc. Skips `customSecurityKey` (not in firmware).
    static let pollSequence: [LTCSetting] = [
        .team, .securityKey, .customSecurityKey, .rfChannel, .networkId,
        .ltcMode, .vadThreshold, .txPower, .ltcVolume, .zone
    ]

    /// On-screen label, matching the Headset screen. Names the setting in failure messages.
    var displayName: String {
        switch self {
        case .team:    return "Team"
        case .securityKey:       return "Security Key"
        case .customSecurityKey: return "Custom Security Key"
        case .rfChannel:         return "RF Channel"
        case .networkId:         return "Network ID"
        case .ltcMode:           return "LTC Mode"
        case .vadThreshold:      return "VAD Threshold"
        case .txPower:           return "LTC Power"
        case .ltcVolume:         return "LTC Volume"
        case .zone:              return "Region"
        }
    }
}

// MARK: - Command Encoding

enum LTCPacket {

    static let commandHeader: [UInt8] = [0x00, 0x1d, 0x40, 0x2c]

    static let opRead: UInt8 = 0x00
    static let opWrite: UInt8 = 0x01

    /// `00 1d 40 2c 00 <setting> <expected length>` — e.g. read team: `00 1d 40 2c 00 00 01`
    static func read(_ setting: LTCSetting, expectedLength: UInt8 = 1) -> Data {
        Data(commandHeader + [opRead, setting.rawValue, expectedLength])
    }

    /// No setting is multi-byte yet; here for the custom security key if it lands.
    static func write(_ setting: LTCSetting, payload: [UInt8]) -> Data {
        Data(commandHeader + [opWrite, setting.rawValue, UInt8(payload.count)] + payload)
    }
    
    static func write(_ setting: LTCSetting, value: UInt8) -> Data {
        write(setting, payload: [value])
    }

    // MARK: - Headset Identity

    /// Part-number query. Separate command family (`0x0c`) with fixed trailing bytes.
    static let identityQuery = Data([0x00, 0x1d, 0x40, 0x0c, 0x00, 0x00, 0x00, 0x2f])
}
