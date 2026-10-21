//
//  LTCResponse.swift
//  Gentex_iOS
//
//  Decodes responses from the AMP 2.0 headset.
//
//  Config responses are `00 1d 41 2c` + payload: a value for a read, a status
//  for a write. The bytes don't say which; the caller knows.
//

import Foundation

// MARK: - Status Codes

/// Write status.
enum LTCStatus: UInt8, Sendable {
    case noError     = 0x00  // LTC_NO_ERR
    case lengthError = 0x01  // LTC_ERR_LEN
    case badValue    = 0x02  // LTC_BAD_VALUE
    case commFailure = 0x03  // LTC_ERR_COMM_FAIL

    var isSuccess: Bool { self == .noError }
}

// MARK: - Errors

/// Undecodable responses, or a non-success status from the headset.
enum LTCProtocolError: LocalizedError, Equatable {
    case malformedResponse(hex: String)
    case emptyPayload
    case headsetReportedError(LTCStatus)
    case unknownStatus(UInt8)
    case unreadablePartNumber(hex: String)

    var errorDescription: String? {
        switch self {
        case .malformedResponse(let hex):
            return "The headset sent an unrecognized response (\(hex))."
        case .emptyPayload:
            return "The headset sent a response with no value."
        case .headsetReportedError(let status):
            switch status {
            case .noError:
                return "The headset reported success."
            case .lengthError:
                return "The headset rejected the command's length."
            case .badValue:
                return "The headset rejected the value as out of range."
            case .commFailure:
                return "The headset reported an internal communication failure."
            }
        case .unknownStatus(let raw):
            return String(format: "The headset returned an unrecognized status code (0x%02X).", raw)
        case .unreadablePartNumber(let hex):
            return "The headset's part number could not be read (\(hex))."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .malformedResponse, .unknownStatus, .emptyPayload:
            return "Disconnect and reconnect the headset. If this continues, the headset may be running unsupported firmware."
        case .headsetReportedError(let status):
            switch status {
            case .badValue:
                return "This setting may not be available on your headset in its current region."
            case .lengthError, .commFailure, .noError:
                return "Try again. If this continues, disconnect and reconnect the headset."
            }
        case .unreadablePartNumber:
            return "Disconnect and reconnect the headset."
        }
    }
}

// MARK: - Configuration Response

struct LTCResponse: Equatable, Sendable {

    static let responseHeader: [UInt8] = [0x00, 0x1d, 0x41, 0x2c]

    /// Bytes after the header. One byte for every setting the app uses.
    let payload: Data

    /// Setting value for a read, status code for a write.
    var value: UInt8? { payload.first }

    /// Throws on a missing header so a truncated notification isn't misread as a value.
    static func parse(_ data: Data) throws -> LTCResponse {
        let bytes = [UInt8](data)
        guard bytes.count >= responseHeader.count,
              Array(bytes.prefix(responseHeader.count)) == responseHeader else {
            throw LTCProtocolError.malformedResponse(hex: data.ltcHexString)
        }
        return LTCResponse(payload: Data(bytes.dropFirst(responseHeader.count)))
    }

    func validateWriteSucceeded() throws {
        guard let raw = value else { throw LTCProtocolError.emptyPayload }
        guard let status = LTCStatus(rawValue: raw) else {
            throw LTCProtocolError.unknownStatus(raw)
        }
        guard status.isSuccess else {
            throw LTCProtocolError.headsetReportedError(status)
        }
    }

    func readValue() throws -> UInt8 {
        guard let value else { throw LTCProtocolError.emptyPayload }
        return value
    }
}

// MARK: - Headset Identity

/// Part number, parsed for region lock. Variant (`1004257` Flagship, `1004058` Base)
/// is not branched on — custom teams work on every headset.
struct HeadsetIdentity: Equatable, Sendable {

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
    static func parse(_ data: Data) throws -> HeadsetIdentity {
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

        return HeadsetIdentity(partNumber: partNumber)
    }
}

// MARK: - Hex Formatting

extension Data {
    /// Space-separated uppercase hex, matching the Android logger's format.
    var ltcHexString: String {
        map { String(format: "%02X", $0) }.joined(separator: " ")
    }
}
