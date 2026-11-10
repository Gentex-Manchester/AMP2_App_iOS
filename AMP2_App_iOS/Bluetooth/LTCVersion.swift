//
//  FirmwareVersion.swift
//  AMP2_App_iOS
//
//  Created by Peter Sargent on 11/10/26.
//

// Currently unused as HeadsetSession is not capable of supporting it.
// This is because it is incorrectly detected as an LTC polling command.

import Foundation

struct LTCVersion: Equatable, Sendable {

    /// Echoes the query's trailing bytes.
    static let responseHeader: [UInt8] = [0x00, 0x1d, 0x41, 0x2c]

    /// e.g. `2.1.14.139`
    let versionNumber: String

    /// Fixed header, then a version number.
    static func parse(_ data: Data) throws -> LTCVersion {
        let bytes = [UInt8](data)

        guard bytes.count >= responseHeader.count + 4,
              Array(bytes.prefix(responseHeader.count)) == responseHeader else {
            throw LTCProtocolError.malformedResponse(hex: data.ltcHexString)
        }

        let versionNumber = bytes
            .dropFirst(responseHeader.count)
            .prefix(4)
            .map { String($0) }
            .joined(separator: ".")

        return LTCVersion(versionNumber: versionNumber)
    }
}
