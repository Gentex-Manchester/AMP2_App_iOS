//
//  DiscoveredHeadset.swift
//  AMP2_App_iOS
//
//  Created by Peter Sargent on 11/3/26.
//

import CoreBluetooth
import Foundation

// MARK: - Supporting Types

struct DiscoveredHeadset: Identifiable, Equatable {
    /// CoreBluetooth per-app UUID, not a MAC (iOS hides those), so the Gentex
    /// `80:3B:70` prefix check is impossible. Verified after connecting instead.
    let id: UUID

    /// Advertised or system-reported name, e.g. "AMP 2.0". May be generic.
    let name: String

    /// Diagnostic only; every source connects the same way.
    let source: Source

    /// Empty for system-connected peripherals, and usually for scans too.
    var advertisedServices: [CBUUID] = []

    /// `nil` for system-connected peripherals.
    var rssi: Int?

    /// The AMP 2.0 sends none (checked on hardware, Aug 2026). With no service
    /// UUIDs either, that rules out AccessorySetupKit; re-check before revisiting
    /// in-app pairing. See docs/ble-protocol.md §10.
    var manufacturerData: Data?

    /// Bluetooth SIG company ID: first two bytes of manufacturer data, little-endian.
    var companyIdentifier: UInt16? {
        guard let manufacturerData, manufacturerData.count >= 2 else { return nil }
        return UInt16(manufacturerData[manufacturerData.startIndex])
            | (UInt16(manufacturerData[manufacturerData.startIndex + 1]) << 8)
    }

    /// `nil` only for preview/test instances, which can't connect.
    let peripheral: CBPeripheral?

    /// Previews and tests only.
    init(id: UUID, name: String, source: Source) {
        self.id = id
        self.name = name
        self.source = source
        self.peripheral = nil
    }

    enum DiscoveryMode {
        /// Production path.
        case headsetsOnly
        /// Every BLE device in range. Diagnostic: tells "not advertising" apart
        /// from "not there".
        case unfiltered
    }

    enum Source: Equatable {
        /// Retrieved by identifier from a previous connection.
        case remembered
        /// Retrieved by GAIA service. iOS only knows the service after some app
        /// has connected over BLE once; Classic pairing alone isn't enough.
        case systemConnected
        /// From an unfiltered scan, shortlisted by name.
        case advertised
    }

    /// With no advertised service UUIDs this is the
    /// only pre-connect filter, so a nameless headset is missed (the packet console's
    /// unfiltered scan is the fallback). The GAIA service check verifies after connect.
    var looksLikeGentexHeadset: Bool {
        let lowercased = name.lowercased()
        return lowercased.contains("amp2.0")
    }

    static func == (lhs: DiscoveredHeadset, rhs: DiscoveredHeadset) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - DiscoveredHeadset Construction

extension DiscoveredHeadset {
    init(peripheral: CBPeripheral, source: Source) {
        self.id = peripheral.identifier
        self.name = peripheral.name ?? String(localized: "Unnamed device")
        self.source = source
        self.peripheral = peripheral
    }

    init(
        id: UUID, name: String, source: Source,
        advertisedServices: [CBUUID], rssi: Int?, peripheral: CBPeripheral
    ) {
        self.id = id
        self.name = name
        self.source = source
        self.advertisedServices = advertisedServices
        self.rssi = rssi
        self.peripheral = peripheral
    }
}

