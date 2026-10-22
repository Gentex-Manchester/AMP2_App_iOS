//
//  HeadsetTransport.swift
//  AMP2_App_iOS
//
//  Seam between `HeadsetSettingsSync` and CoreBluetooth, so the sync logic
//  (queue, lull, cooldown, response matching) can be tested without hardware.
//

import Foundation

/// The LTC packet link. `HeadsetSession` in the app, a fake in tests.
protocol HeadsetTransport: AnyObject {
    var connectionState: HeadsetConnectionState { get }

    /// Every inbound packet except identity responses.
    var onPacketReceived: ((Data) -> Void)? { get set }

    var onConnectionStateChanged: ((HeadsetConnectionState) -> Void)? { get set }

    /// Throws when not connected.
    func send(_ packet: Data) throws
}

extension HeadsetSession: HeadsetTransport {
    var connectionState: HeadsetConnectionState { state }
}
