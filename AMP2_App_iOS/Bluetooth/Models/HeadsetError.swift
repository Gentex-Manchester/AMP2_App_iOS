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
    case partNumberTimeout
    case partNumberRequestInFlight
    case firmwareVersionTimeout
    case firmwareVersionRequestInFlight

    var errorDescription: String? {
        switch self {
        case .bluetoothUnauthorized:
            return String(localized: "Bluetooth access is not allowed.")
        case .bluetoothPoweredOff:
            return String(localized: "Bluetooth is turned off.")
        case .bluetoothUnsupported:
            return String(localized: "This device does not support Bluetooth LE.")
        case .noHeadsetFound:
            return String(localized: "No AMP 2.0 headset was found.")
        case .connectionFailed(let detail):
            return String(localized: "Could not connect to the headset: \(detail)")
        case .disconnected(let detail):
            return String(localized: "The headset disconnected: \(detail)")
        case .serviceNotFound:
            return String(localized: "The headset did not report the expected Bluetooth service.")
        case .characteristicsNotFound:
            return String(localized: "The headset's Bluetooth service is missing its command channels.")
        case .notConnected:
            return String(localized: "No headset is connected.")
        case .writeFailed(let detail):
            return String(localized: "Could not send the command to the headset: \(detail)")
        case .partNumberTimeout:
            return String(localized: "The headset did not report its model.")
        case .partNumberRequestInFlight:
            return String(localized: "The headset's model is already being requested.")
        case .firmwareVersionTimeout:
            return String(localized: "The headset did not report its firmware version.")
        case .firmwareVersionRequestInFlight:
            return String(localized: "The headset's firmware version is already being requested.")
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .bluetoothUnauthorized:
            return String(localized: "Enable Bluetooth for this app in Settings ▸ Privacy & Security ▸ Bluetooth.")
        case .bluetoothPoweredOff:
            return String(localized: "Turn on Bluetooth in Settings or Control Center.")
        case .bluetoothUnsupported:
            return nil
        case .noHeadsetFound, .serviceNotFound:
            // No BLE service until the headset is Connected over Bluetooth
            // Classic, which only the user can do, from the Settings app.
            return String(localized: "Pair the headset in Settings ▸ Bluetooth first, then return to this app.")
        case .characteristicsNotFound:
            return String(localized: "Disconnect and reconnect the headset. If this continues, the headset may need a firmware update.")
        case .connectionFailed, .disconnected:
            return String(localized: "Make sure the headset is powered on and within range, then try again.")
        case .notConnected:
            return String(localized: "Connect a headset before changing its settings.")
        case .writeFailed:
            return String(localized: "Check that the headset is still connected, then try again.")
        case .partNumberTimeout, .partNumberRequestInFlight,
                .firmwareVersionTimeout, .firmwareVersionRequestInFlight:
            return String(localized: "Disconnect and reconnect the headset, then try again.")
        }
    }
}
