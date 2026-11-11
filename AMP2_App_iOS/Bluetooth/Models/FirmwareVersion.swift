//
//  FirmwareVersion.swift
//  AMP2_App_iOS
//
//  Created by Peter Sargent on 11/10/26.
//

import Foundation

struct FirmwareVersion: Equatable, Sendable {

    /// Echoes the query's trailing bytes.
    static let responseHeader: [UInt8] = [0x00, 0x1d, 0x41, 0x01]

    /// e.g. `00.47.02`
    let versionNumber: String

    /// Fixed header, then a NUL-terminated ASCII part number.
    static func parse(_ data: Data) throws -> FirmwareVersion {
        let bytes = [UInt8](data)
        guard bytes.count > responseHeader.count,
              Array(bytes.prefix(responseHeader.count)) == responseHeader else {
            throw LTCProtocolError.malformedResponse(hex: data.ltcHexString)
        }

        let ascii = bytes
            .dropFirst(responseHeader.count)
            .prefix { $0 != 0x00 }

        guard !ascii.isEmpty,
              let versionNumber = String(bytes: ascii, encoding: .ascii),
              versionNumber.contains(where: \.isNumber) else {
            throw LTCProtocolError.unreadablePartNumber(hex: data.ltcHexString)
        }

        return FirmwareVersion(versionNumber: versionNumber)
    }
}
