//
//  HeadsetPacketLogEntry.swift
//  AMP2_App_iOS
//
//  Created by Peter Sargent on 11/3/26.
//

import Foundation

/// One packet on the link, kept in a bounded buffer for the packet console.
struct HeadsetPacketLogEntry: Identifiable {
    enum Direction: String { case sent = "TX", received = "RX" }

    let id = UUID()
    let direction: Direction
    let bytes: Data
    let timestamp: Date

    var hex: String { bytes.ltcHexString }
}
