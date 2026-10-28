//
//  Route.swift
//  AMP2_App_iOS
//
//  Created by Peter Sargent on 10/22/26.
//

enum Route: Hashable {
    case teams
    case settings
    case appearance
    case orientation
    case regions
    case vadThreshold
    case ltcVolume
    case txPower
    case ltcKey
    case customKey
    #if DEBUG
    /// Bluetooth bring-up diagnostics. Debug builds only.
    case packetConsole
    #endif

    /// Screens that should stop working when the headset disconnects.
    var requiresHeadset: Bool {
        switch self {
        case .appearance, .orientation, .teams, .settings:
            return false
        case .regions, .vadThreshold, .ltcVolume, .txPower, .ltcKey, .customKey:
            return true
        #if DEBUG
        // Survives a disconnect; it's where disconnects get diagnosed.
        case .packetConsole:
            return false
        #endif
        }
    }
}

extension Array where Element == Route {

    /// Pops the first headset-only screen and everything above it.
    mutating func popHeadsetOnlyScreens() {
        guard let first = firstIndex(where: \.requiresHeadset) else { return }
        removeSubrange(first...)
    }
}
