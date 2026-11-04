//
//  HeadsetSession.swift
//  AMP2_App_iOS
//
//  BLE transport for the AMP 2.0: discovery, connection, GATT, raw bytes in/out.
//  Knows nothing about LTC; see LTCPacket, LTCResponse, HeadsetSettingsSync.
//
//  One of the app's two observable objects (requirements/ble-parity-plan.md 0.4).
//  Not a precedent for ViewModels elsewhere.
//

import CoreBluetooth
import Foundation

// MARK: - HeadsetSession

/// Owns the `CBCentralManager` and the connection to one headset.
@Observable
final class HeadsetSession: NSObject {

    // MARK: - GATT Identifiers

    /// GAIA. Exposed only while the headset is Connected over Bluetooth Classic.
    static let serviceUUID = CBUUID(string: "00001100-d102-11e1-9b23-00025b00a5a5")
    static let writeCharacteristicUUID = CBUUID(string: "00001101-d102-11e1-9b23-00025b00a5a5")
    /// Responses arrive as notifications.
    static let notifyCharacteristicUUID = CBUUID(string: "00001102-d102-11e1-9b23-00025b00a5a5")

    private static let scanTimeout: Duration = .seconds(10)

    /// Retry interval after an empty pass or a drop. iOS has no equivalent of
    /// Android's `ACTION_ACL_CONNECTED`, so Classic connects must be polled for.
    /// Each pass tries the cheap `retrieveConnectedPeripherals` before scanning.
    private static let rediscoveryDelay: Duration = .seconds(5)

    /// `connect` never times out itself, and remembered headsets are returned even
    /// when powered off. Covers service and characteristic discovery too.
    private static let connectTimeout: Duration = .seconds(10)

    private static let packetLogLimit = 500

    // MARK: - Observable State

    /// Results of the last pass.
    private(set) var discoveredHeadsets: [DiscoveredHeadset] = []

    private(set) var connectedHeadset: DiscoveredHeadset?

    private(set) var isDiscovering = false

    /// Part number, requested once GATT resolves. `nil` until it answers.
    private(set) var identity: HeadsetIdentity?

    /// Non-nil means hide the region selector; the headset rejects zone changes.
    var regionLock: HeadsetIdentity.RegionLock? { identity?.regionLock }

    /// Bounded, newest-last. Cleared on each new connection.
    private(set) var packetLog: [HeadsetPacketLogEntry] = []

    /// Main actor. Every inbound packet except identity responses.
    var onPacketReceived: ((Data) -> Void)?

    /// Main actor. Lets the settings layer halt and clear on a drop.
    var onConnectionStateChanged: ((HeadsetConnectionState) -> Void)?

    private(set) var state: HeadsetConnectionState = .disconnected {
        didSet {
            guard state != oldValue else { return }
            onConnectionStateChanged?(state)
        }
    }

    // MARK: - Private State

    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var writeCharacteristic: CBCharacteristic?
    private var notifyCharacteristic: CBCharacteristic?
    private var scanTimeoutTask: Task<Void, Never>?
    private var connectTimeoutTask: Task<Void, Never>?
    private var rediscoveryTask: Task<Void, Never>?
    private var identityContinuation: CheckedContinuation<HeadsetIdentity, Error>?
    private var identityTimeoutTask: Task<Void, Never>?

    /// Discovery requested before power-on; replayed once Bluetooth is ready.
    private var discoveryPending = false

    private var discoveryMode: DiscoveredHeadset.DiscoveryMode = .headsetsOnly

    /// Last successful headset, so launches skip scanning. A per-app UUID, not a
    /// hardware address, so plain UserDefaults is fine.
    private static let rememberedHeadsetKey = "lastConnectedHeadsetIdentifier"

    private var rememberedIdentifier: UUID? {
        get {
            UserDefaults.standard.string(forKey: Self.rememberedHeadsetKey).flatMap(UUID.init(uuidString:))
        }
        set {
            UserDefaults.standard.set(newValue?.uuidString, forKey: Self.rememberedHeadsetKey)
        }
    }

    // MARK: - Init

    override init() {
        super.init()
        // Main-queue callbacks let the delegate methods use MainActor.assumeIsolated.
        centralManager = CBCentralManager(
            delegate: self,
            queue: nil,
            options: [CBCentralManagerOptionShowPowerAlertKey: true]
        )
        startDiscovery()
    }

    // MARK: - Discovery

    /// Cheapest first: remembered identifier, then system-connected by GAIA
    /// service, then an unfiltered scan shortlisted by name. The AMP 2.0 advertises
    /// no service UUIDs, so a filtered scan never finds it; non-GAIA devices fail
    /// after connecting with `.serviceNotFound`.
    func startDiscovery(mode: DiscoveredHeadset.DiscoveryMode = .headsetsOnly) {
        guard centralManager.state == .poweredOn else {
            discoveryPending = true
            if let error = Self.error(for: centralManager.state) {
                state = .failed(error)
            }
            return
        }

        discoveryPending = false
        cancelRediscovery()

        // Asking to discover overrides an earlier Disconnect; otherwise the flag
        // blocked rediscovery for the rest of the session.
        isIntentionallyDisconnected = false

        isDiscovering = true
        discoveryMode = mode

        var known: [DiscoveredHeadset] = []

        if mode == .headsetsOnly, let remembered = rememberedIdentifier {
            known += centralManager
                .retrievePeripherals(withIdentifiers: [remembered])
                .map { DiscoveredHeadset(peripheral: $0, source: .remembered) }
        }

        known += centralManager
            .retrieveConnectedPeripherals(withServices: [Self.serviceUUID])
            .filter { peripheral in !known.contains { $0.id == peripheral.identifier } }
            .map { DiscoveredHeadset(peripheral: $0, source: .systemConnected) }

        discoveredHeadsets = known

        if !known.isEmpty, mode == .headsetsOnly {
            isDiscovering = false
            autoConnectIfUnambiguous()
            // Keep the loop alive, or one unusable candidate ends discovery
            // for the session.
            scheduleRediscovery()
            return
        }

        // Unfiltered: the headset advertises no services.
        centralManager.scanForPeripherals(
            withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )

        scanTimeoutTask?.cancel()
        scanTimeoutTask = Task { [weak self] in
            try? await Task.sleep(for: Self.scanTimeout)
            guard !Task.isCancelled else { return }
            self?.scanDidTimeOut()
        }
    }

    /// Doesn't auto-connect, so `connect` can call it without re-entering.
    func stopDiscovery() {
        scanTimeoutTask?.cancel()
        scanTimeoutTask = nil
        guard isDiscovering else { return }
        centralManager.stopScan()
        isDiscovering = false
    }

    // MARK: - Rediscovery

    /// Keep retrying while unconnected; otherwise one empty scan or drop left the
    /// connection screen idle until relaunch.
    private func scheduleRediscovery() {
        guard shouldKeepLooking else { return }

        rediscoveryTask?.cancel()
        rediscoveryTask = Task { [weak self] in
            try? await Task.sleep(for: Self.rediscoveryDelay)
            guard !Task.isCancelled else { return }
            guard let self, self.shouldKeepLooking else { return }
            self.startDiscovery()
        }
    }

    /// Checked before scheduling and again on waking; state can change in 5s.
    private var shouldKeepLooking: Bool {
        // Retrying would make Disconnect look broken.
        guard !isIntentionallyDisconnected else { return false }
        // The unfiltered scan is driven by hand from the packet console.
        guard discoveryMode == .headsetsOnly else { return false }
        guard !isDiscovering else { return false }
        // User is choosing; rescanning would replace their list.
        guard discoveredHeadsets.count < 2 else { return false }

        switch state {
        case .connected, .connecting:
            return false
        case .failed(.bluetoothUnauthorized), .failed(.bluetoothUnsupported):
            return false
        case .failed(.bluetoothPoweredOff):
            // Replayed via `discoveryPending` when the radio comes back.
            return false
        case .disconnected, .failed:
            return true
        }
    }

    private func cancelRediscovery() {
        rediscoveryTask?.cancel()
        rediscoveryTask = nil
    }

    private func scanDidTimeOut() {
        stopDiscovery()

        guard !discoveredHeadsets.isEmpty else {
            if case .disconnected = state { state = .failed(.noHeadsetFound) }
            scheduleRediscovery()
            return
        }

        autoConnectIfUnambiguous()
    }

    /// Connects to the remembered headset or a sole candidate. Otherwise the user
    /// picks (Gentex doc requirement); guessing could grab a colleague's headset.
    private func autoConnectIfUnambiguous() {
        // Not just `.disconnected`: a power-cycled headset leaves
        // `.failed(.disconnected)`, and it was found but never connected.
        guard state.allowsNewConnection else { return }

        if let remembered = discoveredHeadsets.first(where: { $0.id == rememberedIdentifier }) {
            connect(remembered)
        } else if discoveredHeadsets.count == 1 {
            connect(discoveredHeadsets[0])
        }
    }

    // MARK: - Connection

    /// Stops auto-reconnect after a deliberate Disconnect. Mirrors Android's
    /// `_isIntentionallyDisconnected`.
    private(set) var isIntentionallyDisconnected = false

    func connect(_ headset: DiscoveredHeadset) {
        isIntentionallyDisconnected = false
        cancelRediscovery()
        stopDiscovery()

        guard let target = headset.peripheral else {
            // Preview/test instance only.
            state = .failed(.connectionFailed(detail: "This headset is not backed by a real device."))
            return
        }

        peripheral = target
        target.delegate = self
        connectedHeadset = headset
        packetLog.removeAll()
        state = .connecting

        centralManager.connect(target)

        connectTimeoutTask?.cancel()
        connectTimeoutTask = Task { [weak self] in
            try? await Task.sleep(for: Self.connectTimeout)
            guard !Task.isCancelled else { return }
            self?.connectDidTimeOut(target)
        }
    }

    private func connectDidTimeOut(_ target: CBPeripheral) {
        guard case .connecting = state, peripheral === target else { return }

        centralManager.cancelPeripheralConnection(target)
        state = .failed(.connectionFailed(detail: "The headset did not answer in time."))
        resetConnectionState()
        scheduleRediscovery()
    }

    func disconnect() {
        isIntentionallyDisconnected = true
        cancelRediscovery()
        cancelConnectTimeout()
        stopDiscovery()
        guard let peripheral else {
            resetConnectionState()
            return
        }
        centralManager.cancelPeripheralConnection(peripheral)
    }

    // MARK: - Identity

    /// Matched by header (`00 1d 41 0c`, unused by config responses). One request
    /// at a time; cached after the first success.
    @discardableResult
    func requestIdentity(timeout: Duration = .seconds(5)) async throws -> HeadsetIdentity {
        if let identity { return identity }
        guard state.isConnected else { throw HeadsetError.notConnected }
        guard identityContinuation == nil else { throw HeadsetError.identityRequestInFlight }

        try send(LTCPacket.identityQuery)

        // No suspension before storing the continuation, so the reply can't beat it.
        return try await withCheckedThrowingContinuation { continuation in
            identityContinuation = continuation
            identityTimeoutTask = Task { [weak self] in
                try? await Task.sleep(for: timeout)
                guard !Task.isCancelled else { return }
                self?.completeIdentityRequest(.failure(HeadsetError.identityTimedOut))
            }
        }
    }

    private func completeIdentityRequest(_ result: Result<HeadsetIdentity, Error>) {
        identityTimeoutTask?.cancel()
        identityTimeoutTask = nil
        guard let continuation = identityContinuation else { return }
        identityContinuation = nil
        if case .success(let identity) = result { self.identity = identity }
        continuation.resume(with: result)
    }

    // MARK: - Sending

    /// Sends the bare LTC packet. No SPP framing or checksum over BLE.
    func send(_ packet: Data) throws {
        guard state.isConnected, let peripheral, let writeCharacteristic else {
            throw HeadsetError.notConnected
        }

        let writeType: CBCharacteristicWriteType =
            writeCharacteristic.properties.contains(.write) ? .withResponse : .withoutResponse

        peripheral.writeValue(packet, for: writeCharacteristic, type: writeType)
        appendToLog(direction: .sent, bytes: packet)
    }

    // MARK: - Helpers

    private func appendToLog(direction: HeadsetPacketLogEntry.Direction, bytes: Data) {
        #if DEBUG
        // Visible from a Mac while running on device.
        print("[GENTEX-BLE] \(direction.rawValue) \(bytes.ltcHexString)")
        #endif

        packetLog.append(
            HeadsetPacketLogEntry(direction: direction, bytes: bytes, timestamp: Date())
        )
        if packetLog.count > Self.packetLogLimit {
            packetLog.removeFirst(packetLog.count - Self.packetLogLimit)
        }
    }

    private func cancelConnectTimeout() {
        connectTimeoutTask?.cancel()
        connectTimeoutTask = nil
    }

    private func resetConnectionState() {
        cancelConnectTimeout()

        // Don't leave an identity caller suspended.
        completeIdentityRequest(.failure(HeadsetError.notConnected))

        peripheral = nil
        writeCharacteristic = nil
        notifyCharacteristic = nil
        connectedHeadset = nil
        identity = nil

        // Stale candidates would look like "user is choosing" and block rediscovery.
        discoveredHeadsets.removeAll()
    }

    /// `nil` for states that aren't failures.
    private static func error(for state: CBManagerState) -> HeadsetError? {
        switch state {
        case .poweredOff: return .bluetoothPoweredOff
        case .unauthorized: return .bluetoothUnauthorized
        case .unsupported: return .bluetoothUnsupported
        case .poweredOn, .resetting, .unknown: return nil
        @unknown default: return nil
        }
    }
}

// MARK: - CBCentralManagerDelegate

extension HeadsetSession: CBCentralManagerDelegate {

    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        MainActor.assumeIsolated {
            switch central.state {
            case .poweredOn:
                if case .failed = state { state = .disconnected }
                if discoveryPending { startDiscovery() }
            default:
                if let error = Self.error(for: central.state) {
                    state = .failed(error)
                }
                isDiscovering = false
                resetConnectionState()
            }
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        MainActor.assumeIsolated {
            guard !discoveredHeadsets.contains(where: { $0.id == peripheral.identifier }) else { return }

            var headset = DiscoveredHeadset(peripheral: peripheral, source: .advertised)
            headset.advertisedServices =
                advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] ?? []
            headset.rssi = RSSI.intValue
            headset.manufacturerData =
                advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data

            // Local name beats CBPeripheral.name, which may not be resolved yet.
            if let localName = advertisementData[CBAdvertisementDataLocalNameKey] as? String,
               !localName.isEmpty {
                let manufacturerData = headset.manufacturerData
                headset = DiscoveredHeadset(
                    id: headset.id, name: localName, source: .advertised,
                    advertisedServices: headset.advertisedServices, rssi: headset.rssi,
                    peripheral: peripheral
                )
                headset.manufacturerData = manufacturerData
            }

            // Name shortlist for production; diagnostic mode keeps everything.
            guard discoveryMode == .unfiltered || headset.looksLikeGentexHeadset else { return }

            discoveredHeadsets.append(headset)

            // Already chosen once; don't ask again.
            if discoveryMode == .headsetsOnly, headset.id == rememberedIdentifier {
                connect(headset)
            }
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
        MainActor.assumeIsolated {
            // Stays .connecting until the service and both characteristics resolve.
            peripheral.discoverServices([Self.serviceUUID])
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        MainActor.assumeIsolated {
            state = .failed(.connectionFailed(detail: error?.localizedDescription ?? "Unknown error."))
            resetConnectionState()
            scheduleRediscovery()
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        MainActor.assumeIsolated {
            if let error {
                state = .failed(.disconnected(detail: error.localizedDescription))
            } else {
                state = .disconnected
            }
            resetConnectionState()
            scheduleRediscovery()
        }
    }
}

// MARK: - CBPeripheralDelegate

extension HeadsetSession: CBPeripheralDelegate {

    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        MainActor.assumeIsolated {
            guard let service = peripheral.services?.first(where: { $0.uuid == Self.serviceUUID }) else {
                state = .failed(.serviceNotFound)
                centralManager.cancelPeripheralConnection(peripheral)
                return
            }

            peripheral.discoverCharacteristics(
                [Self.writeCharacteristicUUID, Self.notifyCharacteristicUUID],
                for: service
            )
        }
    }

    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        MainActor.assumeIsolated {
            for characteristic in service.characteristics ?? [] {
                switch characteristic.uuid {
                case Self.writeCharacteristicUUID:
                    writeCharacteristic = characteristic
                case Self.notifyCharacteristicUUID:
                    notifyCharacteristic = characteristic
                    peripheral.setNotifyValue(true, for: characteristic)
                default:
                    break
                }
            }

            guard writeCharacteristic != nil, notifyCharacteristic != nil else {
                state = .failed(.characteristicsNotFound)
                centralManager.cancelPeripheralConnection(peripheral)
                return
            }

            cancelConnectTimeout()
            state = .connected

            // GAIA confirmed; remember it only now.
            rememberedIdentifier = connectedHeadset?.id

            // Non-fatal: on failure the region selector stays visible, the safe default.
            Task { [weak self] in try? await self?.requestIdentity() }
        }
    }

    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        MainActor.assumeIsolated {
            guard characteristic.uuid == Self.notifyCharacteristicUUID,
                  let data = characteristic.value, !data.isEmpty else { return }

            appendToLog(direction: .received, bytes: data)

            // Identity replies go to their waiting request, not the packet handler.
            if data.starts(with: HeadsetIdentity.responseHeader) {
                completeIdentityRequest(Result { try HeadsetIdentity.parse(data) })
                return
            }

            onPacketReceived?(data)
        }
    }

    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didWriteValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        MainActor.assumeIsolated {
            if let error {
                state = .failed(.writeFailed(detail: error.localizedDescription))
            }
        }
    }
}
