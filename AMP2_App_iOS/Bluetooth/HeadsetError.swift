//
//  HeadsetError.swift
//  AMP2_App_iOS
//
//  Errors surfaced by the Bluetooth LE transport layer.
//

import Foundation

enum HeadsetError: LocalizedError, Equatable {
    case bluetoothUnauthorized
    case bluetoothPoweredOff
    case bluetoothUnsupported
    case noHeadsetFound
    case connectionFailed(detail: String)
    case disconnected(detail: String)
    case serviceNotFound
    case characteristicsNotFound
    case notConnected
    case writeFailed(detail: String)
    case identityTimedOut
    case identityRequestInFlight

    var errorDescription: String? {
        switch self {
        case .bluetoothUnauthorized:
            return "Bluetooth access is not allowed."
        case .bluetoothPoweredOff:
            return "Bluetooth is turned off."
        case .bluetoothUnsupported:
            return "This device does not support Bluetooth LE."
        case .noHeadsetFound:
            return "No AMP 2.0 headset was found."
        case .connectionFailed(let detail):
            return "Could not connect to the headset: \(detail)"
        case .disconnected(let detail):
            return "The headset disconnected: \(detail)"
        case .serviceNotFound:
            return "The headset did not report the expected Bluetooth service."
        case .characteristicsNotFound:
            return "The headset's Bluetooth service is missing its command channels."
        case .notConnected:
            return "No headset is connected."
        case .writeFailed(let detail):
            return "Could not send the command to the headset: \(detail)"
        case .identityTimedOut:
            return "The headset did not report its model."
        case .identityRequestInFlight:
            return "The headset's model is already being requested."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .bluetoothUnauthorized:
            return "Enable Bluetooth for this app in Settings ▸ Privacy & Security ▸ Bluetooth."
        case .bluetoothPoweredOff:
            return "Turn on Bluetooth in Settings or Control Center."
        case .bluetoothUnsupported:
            return nil
        case .noHeadsetFound, .serviceNotFound:
            // No BLE service until the headset is Connected over Bluetooth
            // Classic, which only the user can do, from the Settings app.
            return "Pair the headset in Settings ▸ Bluetooth first, then return to this app."
        case .characteristicsNotFound:
            return "Disconnect and reconnect the headset. If this continues, the headset may need a firmware update."
        case .connectionFailed, .disconnected:
            return "Make sure the headset is powered on and within range, then try again."
        case .notConnected:
            return "Connect a headset before changing its settings."
        case .writeFailed:
            return "Check that the headset is still connected, then try again."
        case .identityTimedOut, .identityRequestInFlight:
            return "Disconnect and reconnect the headset, then try again."
        }
    }
}
