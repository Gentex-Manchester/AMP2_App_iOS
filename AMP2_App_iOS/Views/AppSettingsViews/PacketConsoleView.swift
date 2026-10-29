//
//  PacketConsoleView.swift
//  AMP2_App_iOS
//
//  Debug-only BLE diagnostics, like Android's Developer Options console.
//  Not in Release builds. Monospaced on purpose, for hex.
//

#if DEBUG

import CoreBluetooth
import SwiftUI

struct PacketConsoleView: View {
    // The shared session; a second CBCentralManager would open a separate link.
    @Environment(HeadsetSession.self) private var session
    @Environment(HeadsetSettingsSync.self) private var sync

    @State private var lastError: String?
    @State private var selectedSetting: LTCSetting = .team
    @State private var zoneWatch: Task<Void, Never>?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                statusSection
                discoverySection
                if session.state.isConnected {
                    identitySection
                    settingsSection
                    writeTestSection
                    readSection
                }
                logSection
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .navigationTitle("Packet Console")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Packet Console")
                    .font(.ibmPlexSans(size: 28, weight: .bold))
            }
        }
    }

    // MARK: - Status

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            row("State", statusText)
            if let headset = session.connectedHeadset {
                row("Headset", headset.name)
                row("Found via", headset.source == .systemConnected ? "system connection" : "scan")
            }
            if let identity = session.identity {
                row("Part number", identity.partNumber)
                row("Region lock", regionLockText(identity.regionLock))
            }
            if let lastError {
                Text(lastError)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.opsCoreRed)
            }

            // The usual failure is no Bluetooth Classic connection; only the
            // recovery text says so.
            if case .failed(let error) = session.state,
               let suggestion = error.recoverySuggestion {
                Text(suggestion)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.top, 16)
    }

    private var statusText: String {
        switch session.state {
        case .disconnected: return session.isDiscovering ? "scanning…" : "disconnected"
        case .connecting: return "connecting…"
        case .connected: return "connected"
        case .failed(let error): return "failed — \(error.localizedDescription)"
        }
    }

    private func regionLockText(_ lock: HeadsetIdentity.RegionLock?) -> String {
        switch lock {
        case .northAmerica: return "North America (selector hidden)"
        case .europe: return "Europe (selector hidden)"
        case nil: return "none (selector shown)"
        }
    }

    // MARK: - Discovery

    private var discoverySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                consoleButton("Discover") {
                    lastError = nil
                    session.startDiscovery()
                }
                consoleButton("Disconnect") { session.disconnect() }
            }

            // Every BLE device in range. Seen here but not under Discover means
            // the headsets-only filter excludes it.
            consoleButton("Scan everything (unfiltered)") {
                lastError = nil
                session.startDiscovery(mode: .unfiltered)
            }

            ForEach(session.discoveredHeadsets) { headset in
                Button {
                    lastError = nil
                    session.connect(headset)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(headset.name)
                                .font(.system(size: 14, design: .monospaced))
                            Text(headset.id.uuidString)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                            if let rssi = headset.rssi {
                                Text("RSSI \(rssi) dBm")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }

                            // AccessorySetupKit needs a company ID or service
                            // UUID. No manufacturer data means ASK can't find it.
                            Text(manufacturerText(headset))
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(headset.companyIdentifier == nil ? .opsCoreRed : .green)
                            Text(headset.advertisedServices.isEmpty
                                 ? "advertises: (none)"
                                 : "advertises: " + headset.advertisedServices
                                     .map(\.uuidString).joined(separator: ", "))
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(
                                    headset.advertisedServices.contains(HeadsetSession.serviceUUID)
                                        ? .green : .secondary
                                )
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .foregroundColor(.primary)
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray5))
                    .cornerRadius(16)
                }
            }
        }
    }

    // MARK: - Identity

    private var identitySection: some View {
        consoleButton("Query part number") {
            Task {
                do {
                    _ = try await session.requestIdentity()
                    lastError = nil
                } catch {
                    lastError = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Live Settings

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Live settings")
                    .font(.ibmPlexSans(size: 18, weight: .bold))
                Spacer()
                Text(sync.isPolling ? "polling" : "idle")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(sync.isPolling ? .green : .secondary)
            }

            // `confirmed`, not `settings`: show only what the headset reported.
            let settings = sync.confirmed
            row("Team", value(settings.team?.displayName, .team))
            row("Security key", value(settings.securityKey?.rawValue, .securityKey))
            row("RF channel", value(settings.rfChannel.map(String.init), .rfChannel))
            row("Network ID", value(settings.networkId.map(String.init), .networkId))
            row("LTC mode", value(settings.ltcMode?.displayName, .ltcMode))
            row("VAD threshold", value(settings.vadThreshold.map(String.init), .vadThreshold))
            row("Tx power", value(settings.txPower?.displayName, .txPower))
            row("LTC volume", value(settings.ltcVolume.map(String.init), .ltcVolume))
            row("Zone", value(settings.zone?.displayName, .zone))

            row("Active team", activeTeamText)

            if let failure = sync.lastFailure {
                Text("\(failure.setting.displayName): \(String(describing: failure.reason))")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.opsCoreRed)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 10) {
                consoleButton(sync.isPolling ? "Stop polling" : "Start polling") {
                    sync.isPolling ? sync.stopPolling() : sync.startPolling()
                }
                consoleButton("Poll once") { sync.pollOnce() }
            }
            .padding(.top, 6)
        }
    }

    /// Advertised company ID (what AccessorySetupKit matches on) and raw bytes.
    private func manufacturerText(_ headset: DiscoveredHeadset) -> String {
        guard let data = headset.manufacturerData, !data.isEmpty else {
            return "mfr data: (none) — ASK cannot match"
        }
        guard let company = headset.companyIdentifier else {
            return "mfr data: \(data.ltcHexString) (too short for a company ID)"
        }
        return String(format: "company 0x%04X — %@", company, data.ltcHexString)
    }

    /// Distinguishes "not read yet" from an undocumented byte, which the headset does send.
    private func value(_ known: String?, _ setting: LTCSetting) -> String {
        if let known { return known }
        if let raw = sync.confirmed.unrecognized[setting] {
            return String(format: "undocumented (0x%02X)", raw)
        }
        return "—"
    }

    private var activeTeamText: String {
        sync.confirmed.team?.displayName ?? "—"
    }

    // MARK: - Isolated Writes

    /// Raw writes with polling stopped. If a write works here but not on the
    /// Headset screen, the post-write lull is too short.
    private var writeTestSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Isolated write test")
                .font(.ibmPlexSans(size: 18, weight: .bold))

            Text(sync.isPolling
                 ? "Stop polling first, then write."
                 : "Polling stopped — writes go out alone.")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(sync.isPolling ? .opsCoreRed : .green)

            HStack(spacing: 10) {
                ForEach(LTCMode.allCases, id: \.self) { mode in
                    consoleButton(mode.displayName) {
                        writeRaw(LTCPacket.write(.ltcMode, value: mode.rawValue))
                    }
                }
            }

            // Zone (0x0a) is ACKed but not applied. Bypassing the queue, lull,
            // and cooldown separates a bad write from a refusal. See docs/ble-protocol.md §8.
            Text("Zone")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.secondary)

            HStack(spacing: 10) {
                ForEach(Region.allCases, id: \.self) { region in
                    consoleButton(region.displayName) {
                        writeRaw(LTCPacket.write(.zone, value: region.ltcByte))
                    }
                }
            }

            consoleButton("Read zone back") {
                writeRaw(LTCPacket.read(.zone))
            }

            // The headset ignores all three documented values (Android's old map
            // had 0x02 Brazil, 0x04 Japan). Logs which of 0x00–0x07 it accepts.
            consoleButton("Sweep zone 0x00–0x07") {
                Task { await sweepZone() }
            }

            // Polls zone at 2Hz to catch a change from the headset's own menu,
            // even one that reverts. The 5s heartbeat is too coarse.
            consoleButton(zoneWatch == nil ? "Watch zone (2/sec)" : "Stop watching zone") {
                if let running = zoneWatch {
                    running.cancel()
                    zoneWatch = nil
                } else {
                    zoneWatch = Task {
                        while !Task.isCancelled {
                            writeRaw(LTCPacket.read(.zone))
                            try? await Task.sleep(for: .milliseconds(500))
                        }
                    }
                }
            }

            // Control for the sweep: 0x50 is out of LTC volume's 0x00–0x0a range.
            // LTC_BAD_VALUE means the headset validates; LTC_NO_ERR means the sweep proves little.
            consoleButton("Control: bad LTC volume (0x50)") {
                Task {
                    writeRaw(LTCPacket.write(.ltcVolume, value: 0x50))
                    try? await Task.sleep(for: .milliseconds(400))
                    writeRaw(LTCPacket.read(.ltcVolume))
                }
            }
        }
    }

    /// Writes zone `0x00`–`0x07`, reading back after each.
    /// Spaced out because the headset drops packets closer than 200ms.
    private func sweepZone() async {
        for value in UInt8(0x00)...UInt8(0x07) {
            writeRaw(LTCPacket.write(.zone, value: value))
            try? await Task.sleep(for: .milliseconds(400))
            writeRaw(LTCPacket.read(.zone))
            try? await Task.sleep(for: .milliseconds(400))
        }
        // Restore the starting value.
        writeRaw(LTCPacket.write(.zone, value: 0x00))
    }

    /// Sends outside the write queue.
    private func writeRaw(_ packet: Data) {
        do {
            try session.send(packet)
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    // MARK: - Reads

    private var readSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("Setting", selection: $selectedSetting) {
                ForEach(LTCSetting.pollSequence, id: \.self) { setting in
                    Text(String(format: "0x%02X", setting.rawValue)).tag(setting)
                }
            }
            .pickerStyle(.segmented)

            consoleButton("Read selected setting") {
                do {
                    try session.send(LTCPacket.read(selectedSetting))
                    lastError = nil
                } catch {
                    lastError = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Log

    private var logSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Packets (\(session.packetLog.count))")
                .font(.ibmPlexSans(size: 18, weight: .bold))

            if session.packetLog.isEmpty {
                Text("No traffic yet.")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            // Newest first.
            ForEach(session.packetLog.reversed()) { entry in
                HStack(alignment: .top, spacing: 8) {
                    Text(entry.direction.rawValue)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(entry.direction == .sent ? .opsCoreRed : .green)
                    Text(entry.hex)
                        .font(.system(size: 12, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    // MARK: - Helpers

    private func row(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, design: .monospaced))
                .multilineTextAlignment(.trailing)
        }
    }

    private func consoleButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.ibmPlexSans(size: 18))
                .foregroundColor(.white)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Color.opsCoreRed)
                .cornerRadius(16)
        }
    }
}

#Preview {
    let session = HeadsetSession()
    NavigationStack {
        PacketConsoleView()
            .environment(session)
            .environment(HeadsetSettingsSync(transport: session))
    }
}

#endif
