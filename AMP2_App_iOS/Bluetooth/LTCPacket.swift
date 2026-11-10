//
//  LTCPacket.swift
//  AMP2_App_iOS
//
//  Encodes LTC configuration commands for the AMP 2.0 headset.
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
    case ltcMode           = 0x05
    case vadThreshold      = 0x06
    case txPower           = 0x07
    case ltcVolume         = 0x08
    case zone              = 0x0a

    /// Heartbeat poll order, per the doc. Skips `customSecurityKey` (not in firmware).
    static let pollSequence: [LTCSetting] = [
        .team, .securityKey, .customSecurityKey,
        .ltcMode, .vadThreshold, .txPower, .ltcVolume, .zone
    ]

    /// On-screen label, matching the Headset screen. Names the setting in failure messages.
    var displayName: String {
        switch self {
        case .team:              return String(localized: "Team")
        case .securityKey:       return String(localized: "Security Key")
        case .customSecurityKey: return String(localized: "Custom Security Key")
        case .ltcMode:           return String(localized: "LTC Mode")
        case .vadThreshold:      return String(localized: "VAD Threshold")
        case .txPower:           return String(localized: "LTC Power")
        case .ltcVolume:         return String(localized: "LTC Volume")
        case .zone:              return String(localized: "Region")
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

    /// Part number query. Separate command family (`0x0c`) with fixed trailing bytes.
    /// Response will be a set of bytes to translate into ASCII.
    static let partNumberQuery = Data([0x00, 0x1d, 0x40, 0x0c, 0x00, 0x00, 0x00, 0x2f])
    
    /// Firmware version query.
    /// Response will be a set of bytes to translate into ASCII.
    static let firmwareVersionQuery = Data([0x00, 0x1d, 0x40, 0x01])
    
    /// LTC version query. Only returns a valid value when LTC is enabled.
    /// Response will be a set of four bytes, representing the version 01.02.03.04.
    /// HeadsetSession is currently not capable of supporting this query, so it remains unused.
    static let ltcVersionQuery = Data([0x00, 0x1d, 0x40, 0x2c, 0x00, 0x0d, 0x04])
}
