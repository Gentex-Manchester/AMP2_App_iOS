//
//  LTCResponse.swift
//  AMP2_App_iOS
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
            return String(localized: "The headset sent an unrecognized response (\(hex)).")
        case .emptyPayload:
            return String(localized: "The headset sent a response with no value.")
        case .headsetReportedError(let status):
            switch status {
            case .noError:
                return String(localized: "The headset reported success.")
            case .lengthError:
                return String(localized: "The headset rejected the command's length.")
            case .badValue:
                return String(localized: "The headset rejected the value as out of range.")
            case .commFailure:
                return String(localized: "The headset reported an internal communication failure.")
            }
        case .unknownStatus(let raw):
            return String(format: String(localized: "The device returned an unrecognized status code (0x%02X)."), raw)
        case .unreadablePartNumber(let hex):
            return String(localized: "The headset's part number could not be read (\(hex)).")
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .malformedResponse, .unknownStatus, .emptyPayload:
            return String(localized: "Disconnect and reconnect the headset. If this continues, the headset may be running unsupported firmware.")
        case .headsetReportedError(let status):
            switch status {
            case .badValue:
                return String(localized: "This setting may not be available on your headset in its current region.")
            case .lengthError, .commFailure, .noError:
                return String(localized: "Try again. If this continues, disconnect and reconnect the headset.")
            }
        case .unreadablePartNumber:
            return String(localized: "Disconnect and reconnect the headset.")
        }
    }
}

// MARK: - Configuration Response

struct LTCResponse: Equatable, Sendable {

    static let responseHeader: [UInt8] = [0x00, 0x1d, 0x41, 0x2c]

    /// Bytes after the header. One byte for every setting the app uses.
    let payload: [UInt8]

    /// Setting value for a read, status code for a write.
    var value: [UInt8]? { payload }

    /// Throws on a missing header so a truncated notification isn't misread as a value.
    static func parse(_ data: Data) throws -> LTCResponse {
        
        guard data.count >= responseHeader.count, Array(data.prefix(responseHeader.count)) == responseHeader else {
            throw LTCProtocolError.malformedResponse(hex: data.ltcHexString)
        }
        return LTCResponse(payload: Array(data.dropFirst(responseHeader.count)))
    }

    func validateWriteSucceeded() throws {
        guard let raw = value?.first else { throw LTCProtocolError.emptyPayload }
        guard let status = LTCStatus(rawValue: raw) else {
            throw LTCProtocolError.unknownStatus(raw)
        }
        guard status.isSuccess else {
            throw LTCProtocolError.headsetReportedError(status)
        }
    }

    func readValue() throws -> [UInt8] {
        guard let value else { throw LTCProtocolError.emptyPayload }
        return value
    }
}

// MARK: - Hex Formatting

extension Data {
    /// Space-separated uppercase hex, matching the Android logger's format.
    var ltcHexString: String {
        map { String(format: "%02X", $0) }.joined(separator: " ")
    }
}
