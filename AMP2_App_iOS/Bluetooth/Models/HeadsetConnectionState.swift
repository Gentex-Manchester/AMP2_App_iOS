//
//  HeadsetConnectionState.swift
//  AMP2_App_iOS
//
//  Created by Peter Sargent on 11/3/26.
//

/// Mirrors Android's `ConnectionState`.
enum HeadsetConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case failed(HeadsetError)

    var isConnected: Bool { self == .connected }

    /// Only an attempt already under way blocks another; a failure is when to retry.
    var allowsNewConnection: Bool {
        switch self {
        case .connected, .connecting: return false
        case .disconnected, .failed: return true
        }
    }
}
