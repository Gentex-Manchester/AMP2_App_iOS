//
//  SettingsRoute.swift
//  AMP2_App_iOS
//
//  Created by Peter Sargent on 10/22/26.
//

enum SettingsRoute: Hashable {
    case appearance
    case orientation
    case regions
    case vadThreshold
    case ltcVolume
    case txPower
    #if DEBUG
    /// Bluetooth bring-up diagnostics. Debug builds only.
    case packetConsole
    #endif

    /// Screens popped when the headset disconnects.
    var requiresHeadset: Bool {
        switch self {
        case .appearance, .orientation:
            return false
        case .regions, .vadThreshold, .ltcVolume, .txPower:
            return true
        #if DEBUG
        // Survives a disconnect; it's where disconnects get diagnosed.
        case .packetConsole:
            return false
        #endif
        }
    }
}

extension Array where Element == SettingsRoute {

    /// Pops the first headset-only screen and everything above it.
    mutating func popHeadsetOnlyScreens() {
        guard let first = firstIndex(where: \.requiresHeadset) else { return }
        removeSubrange(first...)
    }
}
