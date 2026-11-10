//
//  PartNumber.swift
//  AMP2_App_iOS
//
//  Created by Peter Sargent on 11/10/26.
//

import Foundation

/// Part number, parsed for region lock. Variant (`1004257` Flagship, `1004058` Base)
/// is not branched on — custom teams work on every headset.
struct PartNumber: Equatable, Sendable {

    /// Echoes the query's trailing bytes.
    static let responseHeader: [UInt8] = [0x00, 0x1d, 0x41, 0x0c, 0x00, 0x00, 0x00, 0x2f]

    /// e.g. `1004257-1201-1201`
    let partNumber: String

    enum RegionLock: Equatable, Sendable {
        case northAmerica
        case europe
    }

    /// Kit digit: third-from-last of the final eight digits (`12011201` → `2`, unlocked).
    ///
    /// Zone writes failing on the dev unit are a firmware bug (Gentex, Aug 25 2026), not a lock.
    /// Never checked against a known-locked unit; a wrong rule hides Region on unlocked
    /// headsets, so confirm with Gentex first. See `docs/ble-protocol.md` §8.
    var regionLock: RegionLock? {
        let digits = partNumber.filter(\.isNumber)
        guard digits.count >= 8 else { return nil }
        let lastEight = Array(digits.suffix(8))
        switch lastEight[lastEight.count - 3] {
        case "0": return .northAmerica
        case "3": return .europe
        default: return nil  // 1 and 2 are unlocked
        }
    }

    /// Fixed header, then a NUL-terminated ASCII part number.
    static func parse(_ data: Data) throws -> PartNumber {
        let bytes = [UInt8](data)
        guard bytes.count > responseHeader.count,
              Array(bytes.prefix(responseHeader.count)) == responseHeader else {
            throw LTCProtocolError.malformedResponse(hex: data.ltcHexString)
        }

        let ascii = bytes
            .dropFirst(responseHeader.count)
            .prefix { $0 != 0x00 }

        guard !ascii.isEmpty,
              let partNumber = String(bytes: ascii, encoding: .ascii),
              partNumber.contains(where: \.isNumber) else {
            throw LTCProtocolError.unreadablePartNumber(hex: data.ltcHexString)
        }

        return PartNumber(partNumber: partNumber)
    }
}
