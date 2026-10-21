//
//  HeadsetSettingsSync.swift
//  Gentex_iOS
//
//  Caches the headset's nine LTC settings and applies user changes.
//
//  Mirrors Android's `HeadsetManager`. The timings and queueing exist because
//  the headset drops fast commands and reports stale values right after a write.
//  They were tuned for SPP, so treat them as a BLE starting point.
//  Transport lives in HeadsetSession; see requirements/ble-parity-plan.md 0.4.
//

import Foundation
import Observation

// MARK: - Cached State

/// Last-reported headset config. `nil` means "not read yet", never "off" or zero.
struct HeadsetSettingsState: Equatable, Sendable {
    var predefinedTeam: PredefinedTeam?
    var securityKey: SecurityKey?
    var rfChannel: Int?
    var networkId: Int?
    var ltcMode: LTCMode?
    var vadThreshold: Int?
    var txPower: TxPower?
    var ltcVolume: Int?
    var zone: Region?

    /// Raw bytes the app doesn't recognize (e.g. LTC mode `0x04`), so an unknown
    /// value doesn't look like "not read yet".
    var unrecognized: [LTCSetting: UInt8] = [:]

    var isComplete: Bool {
        predefinedTeam != nil && securityKey != nil && rfChannel != nil
            && networkId != nil && ltcMode != nil && vadThreshold != nil
            && txPower != nil && ltcVolume != nil && zone != nil
    }

    /// Derived from key, channel, and network ID, not the `predefinedTeam` byte,
    /// which goes stale after a custom team is written.
    var activePredefinedTeam: PredefinedTeam? {
        guard let securityKey, let rfChannel, let networkId else { return nil }
        return PredefinedTeam.matching(
            securityKey: securityKey, rfChannel: rfChannel, networkId: networkId
        )
    }

    /// `nil` while the settings are still being read.
    var isCustomTeamActive: Bool? {
        guard securityKey != nil, rfChannel != nil, networkId != nil else { return nil }
        return activePredefinedTeam == nil
    }

    // MARK: Decoding

    /// Shared by poll responses and the optimistic overlay so both decode bytes the same way.
    mutating func apply(_ byte: UInt8, to setting: LTCSetting) {
        var recognized = true

        switch setting {
        case .predefinedTeam:
            predefinedTeam = PredefinedTeam(rawValue: byte)
            recognized = predefinedTeam != nil
        case .securityKey:
            securityKey = SecurityKey(ltcByte: byte)
            recognized = securityKey != nil
        case .rfChannel:
            rfChannel = LTCRFChannel.channel(forByte: byte)
            recognized = rfChannel != nil
        case .networkId:
            networkId = Int(byte)          // any byte is valid
        case .ltcMode:
            ltcMode = LTCMode(rawValue: byte)
            recognized = ltcMode != nil
        case .vadThreshold:
            vadThreshold = LTCLevel.level(forByte: byte)
            recognized = vadThreshold != nil
        case .txPower:
            txPower = TxPower(rawValue: byte)
            recognized = txPower != nil
        case .ltcVolume:
            ltcVolume = LTCLevel.level(forByte: byte)
            recognized = ltcVolume != nil
        case .zone:
            zone = Region(ltcByte: byte)
            recognized = zone != nil
        case .customSecurityKey:
            return  // reserved, never polled
        }

        if recognized {
            unrecognized[setting] = nil
        } else {
            unrecognized[setting] = byte
        }
    }

    /// UI-formatted value, or `nil` if not read yet.
    func displayValue(for setting: LTCSetting) -> String? {
        switch setting {
        case .predefinedTeam:    return predefinedTeam?.displayName
        case .securityKey:       return securityKey?.rawValue.capitalized
        case .rfChannel:         return rfChannel.map(String.init)
        case .networkId:         return networkId.map(String.init)
        case .ltcMode:           return ltcMode?.displayName
        case .vadThreshold:      return vadThreshold.map(String.init)
        case .txPower:           return txPower?.displayName
        case .ltcVolume:         return ltcVolume.map(String.init)
        case .zone:              return zone?.displayName
        case .customSecurityKey: return nil
        }
    }
}

// MARK: - Write Failure

/// A change the headset refused or failed to apply.
struct WriteFailure: Equatable, Sendable {

    /// A case, not a string, so tests assert on behavior rather than copy.
    enum Reason: Equatable, Sendable {
        /// Error status in reply to the write.
        case rejected
        /// ACKed, then read back as something else. See docs/ble-protocol.md §7.
        case notApplied
        /// No reply within `responseTimeout`.
        case noResponse
        case couldNotSend
        case unreadableReply
    }

    let setting: LTCSetting
    let reason: Reason
    /// Value now on screen; `nil` if the headset never reported one.
    let revertedTo: String?

    var message: String {
        let name = setting.displayName
        switch reason {
        case .rejected:
            return "The headset rejected \(name)."
        case .notApplied:
            return "The headset accepted \(name) but didn't apply it."
        case .noResponse:
            return "The headset didn't respond when changing \(name)."
        case .couldNotSend:
            return "\(name) couldn't be sent to the headset."
        case .unreadableReply:
            return "The headset sent an unrecognized reply when changing \(name)."
        }
    }

    var revertedNotice: String? {
        revertedTo.map { "It's still set to \($0)." }
    }
}

// MARK: - Queue Work

private enum HeadsetTask: Equatable {
    /// Heartbeat read. Droppable.
    case poll(LTCSetting)
    /// User write. Preempts polls, never dropped.
    case write(LTCSetting, value: UInt8)

    var setting: LTCSetting {
        switch self {
        case .poll(let setting): return setting
        case .write(let setting, _): return setting
        }
    }

    var isWrite: Bool {
        if case .write = self { return true }
        return false
    }
}

// MARK: - Settings Sync

@Observable
final class HeadsetSettingsSync {

    // MARK: Timings
    //
    // From Android's `protocol/Packet.kt` and `HeadsetManager`. The hardware
    // misbehaves without them; don't shorten them to speed up tests.

    /// Keeps the headset's buffer from overrunning.
    static let interPacketDelay: Duration = .milliseconds(200)
    /// Replies don't name their setting, so matching needs one request in flight.
    /// Without a timeout, slow replies were filed under the wrong setting.
    static let responseTimeout: Duration = .milliseconds(1500)
    static let heartbeatInterval: Duration = .seconds(5)
    /// Ignore polls and pause the heartbeat this long after a write; the headset
    /// reports pre-write values meanwhile and the UI would snap back.
    static let writeCooldown: Duration = .seconds(3)

    // MARK: Observable State

    /// Hardware truth, written only by poll responses. Show this in diagnostics.
    private(set) var confirmed = HeadsetSettingsState()

    /// Unconfirmed user values. Confirmation takes 3–5s (lull plus a poll cycle),
    /// so changes show at once and roll back if the headset disagrees.
    private var optimistic: [LTCSetting: UInt8] = [:]

    /// `confirmed` with unconfirmed changes overlaid. What the UI shows.
    var settings: HeadsetSettingsState {
        guard !optimistic.isEmpty else { return confirmed }
        var merged = confirmed
        for (setting, byte) in optimistic {
            merged.apply(byte, to: setting)
        }
        return merged
    }

    /// Why the last change rolled back. Packet console only; rollbacks are silent elsewhere.
    private(set) var lastFailure: WriteFailure?

    /// Derived, not stored: a stored flag once stayed `true` after the heartbeat died.
    var isPolling: Bool { heartbeatTask != nil }

    // MARK: Private State

    private let transport: any HeadsetTransport

    private var priorityQueue: [HeadsetTask] = []
    private var routineQueue: [HeadsetTask] = []

    /// Request awaiting a reply. The serial queue keeps this to one at a time.
    private var pendingTask: HeadsetTask?

    private var responseContinuation: CheckedContinuation<Void, Never>?
    private var responseTimeoutTask: Task<Void, Never>?

    private var processorTask: Task<Void, Never>?
    private var heartbeatTask: Task<Void, Never>?
    private var lullTask: Task<Void, Never>?
    private var lastWriteAt: ContinuousClock.Instant?

    /// Wakes the processor when work is queued.
    private var wakeUp: AsyncStream<Void>.Continuation?

    // MARK: Init

    init(transport: any HeadsetTransport) {
        self.transport = transport
        transport.onPacketReceived = { [weak self] data in
            self?.handle(data)
        }
        transport.onConnectionStateChanged = { [weak self] state in
            guard let self else { return }
            if state.isConnected {
                startPolling()
            } else {
                haltAndDrain()
            }
        }
        startProcessor()
    }

    deinit {
        processorTask?.cancel()
        heartbeatTask?.cancel()
        lullTask?.cancel()
    }

    // MARK: - Polling

    /// Idempotent.
    func startPolling() {
        guard transport.connectionState.isConnected else { return }
        guard heartbeatTask == nil else { return }

        heartbeatTask = Task { [weak self] in
            while !Task.isCancelled {
                self?.enqueuePollSequence()
                try? await Task.sleep(for: Self.heartbeatInterval)
            }
        }
    }

    func stopPolling() {
        heartbeatTask?.cancel()
        heartbeatTask = nil
        lullTask?.cancel()
        lullTask = nil
        routineQueue.removeAll()
    }

    /// One poll cycle, no heartbeat.
    func pollOnce() {
        enqueuePollSequence()
    }

    private func enqueuePollSequence() {
        // Previous cycle not drained means the link is slower than the heartbeat.
        guard routineQueue.isEmpty else { return }
        routineQueue = LTCSetting.pollSequence.map { .poll($0) }
        wakeUp?.yield()
    }

    // MARK: - Writes

    /// Shows the value immediately; rolls back on rejection, error, or a mismatched read.
    func write(_ setting: LTCSetting, value: UInt8) {
        optimistic[setting] = value
        lastFailure = nil

        priorityQueue.append(.write(setting, value: value))

        // Queued reads predate the change and would report the old value.
        routineQueue.removeAll()

        // Each write restarts the lull, so dragging a slider doesn't fight polling.
        beginLull()
        wakeUp?.yield()
    }

    /// A preset goes out as the single team command (`0x00`): the headset then plays its
    /// spoken confirmation and sets key/channel/network itself. Three separate writes
    /// regroup silently and leave the team byte stale (Android: `TeamsViewModel.setTeam`).
    /// Custom teams have no team byte, so they still take three writes.
    func applyTeam(securityKey: SecurityKey, rfChannel: Int, networkId: Int) throws {
        guard let channelByte = LTCRFChannel.byte(forChannel: rfChannel) else {
            throw LTCProtocolError.headsetReportedError(.badValue)
        }
        guard let networkByte = LTCNetworkID.byte(for: networkId) else {
            throw LTCProtocolError.headsetReportedError(.badValue)
        }

        // Predict all three so the "Active" badge moves on the tap.
        optimistic[.securityKey] = securityKey.ltcByte
        optimistic[.rfChannel] = channelByte
        optimistic[.networkId] = networkByte
        lastFailure = nil

        if let preset = PredefinedTeam.matching(
            securityKey: securityKey, rfChannel: rfChannel, networkId: networkId
        ) {
            optimistic[.predefinedTeam] = preset.rawValue
            priorityQueue.append(.write(.predefinedTeam, value: preset.rawValue))
        } else {
            priorityQueue.append(contentsOf: [
                .write(.securityKey, value: securityKey.ltcByte),
                .write(.rfChannel, value: channelByte),
                .write(.networkId, value: networkByte)
            ])
        }

        routineQueue.removeAll()
        beginLull()
        wakeUp?.yield()
    }

    // MARK: - Resolving Optimistic Values

    private func confirmOptimistic(_ setting: LTCSetting) {
        optimistic[setting] = nil
    }

    /// Silent on purpose: the headset can ACK a change and then refuse it (docs/ble-protocol.md §7-8),
    /// and a warning each time reads as an app bug. Recorded in `lastFailure` and the debug log.
    private func revertOptimistic(_ setting: LTCSetting, because reason: WriteFailure.Reason) {
        guard optimistic.removeValue(forKey: setting) != nil else { return }

        // A failed team write takes its three predicted values with it.
        if setting == .predefinedTeam {
            optimistic[.securityKey] = nil
            optimistic[.rfChannel] = nil
            optimistic[.networkId] = nil
        }

        let failure = WriteFailure(
            setting: setting,
            reason: reason,
            revertedTo: confirmed.displayValue(for: setting)
        )
        lastFailure = failure

        #if DEBUG
        print("[LTC] reverted \(setting.displayName): \(reason). "
              + "Now \(failure.revertedTo ?? "unknown").")
        #endif
    }

    /// Pauses the heartbeat until writes stop for `writeCooldown`. Always reschedules the
    /// restart; bailing when already stopped once left polling dead after a second write.
    private func beginLull() {
        lullTask?.cancel()
        stopHeartbeatOnly()

        lullTask = Task { [weak self] in
            try? await Task.sleep(for: Self.writeCooldown)
            guard !Task.isCancelled else { return }
            self?.startPolling()
        }
    }

    private func stopHeartbeatOnly() {
        heartbeatTask?.cancel()
        heartbeatTask = nil
    }

    // MARK: - Processor

    private func startProcessor() {
        let (stream, continuation) = AsyncStream<Void>.makeStream()
        wakeUp = continuation

        processorTask = Task { [weak self] in
            for await _ in stream {
                guard let self else { return }
                while let task = self.dequeue() {
                    // One request in flight, or unlabelled replies get misattributed.
                    await self.execute(task)
                    try? await Task.sleep(for: Self.interPacketDelay)
                }
            }
        }
    }

    /// Writes first; polls wait until they're sent.
    private func dequeue() -> HeadsetTask? {
        if !priorityQueue.isEmpty { return priorityQueue.removeFirst() }
        if !routineQueue.isEmpty { return routineQueue.removeFirst() }
        return nil
    }

    private func execute(_ task: HeadsetTask) async {
        guard transport.connectionState.isConnected else {
            haltAndDrain()
            return
        }

        let packet: Data
        switch task {
        case .poll(let setting):
            packet = LTCPacket.read(setting)
        case .write(let setting, let value):
            packet = LTCPacket.write(setting, value: value)
            lastWriteAt = ContinuousClock.now
        }

        pendingTask = task

        do {
            try transport.send(packet)
        } catch {
            pendingTask = nil
            if task.isWrite {
                revertOptimistic(task.setting, because: .couldNotSend)
            }
            return
        }

        await withCheckedContinuation { continuation in
            responseContinuation = continuation
            responseTimeoutTask = Task { [weak self] in
                try? await Task.sleep(for: Self.responseTimeout)
                guard !Task.isCancelled else { return }
                // Abandon so a late reply isn't credited to the next request.
                self?.abandonExchange()
            }
        }
    }

    /// Timed out. An unanswered write can't be assumed to have landed, so it rolls back.
    private func abandonExchange() {
        if let task = pendingTask, task.isWrite {
            revertOptimistic(task.setting, because: .noResponse)
        }
        finishExchange()
    }

    private func finishExchange() {
        responseTimeoutTask?.cancel()
        responseTimeoutTask = nil
        pendingTask = nil

        guard let continuation = responseContinuation else { return }
        responseContinuation = nil
        continuation.resume()
    }

    // MARK: - Responses

    private func handle(_ data: Data) {
        guard let task = pendingTask else { return }
        // Release the processor on every path.
        defer { finishExchange() }

        guard let response = try? LTCResponse.parse(data) else {
            if task.isWrite {
                revertOptimistic(task.setting, because: .unreadableReply)
            }
            return
        }

        if task.isWrite {
            do {
                try response.validateWriteSucceeded()
                // An ACK is not proof (docs/ble-protocol.md §7); the value stays
                // provisional until a read agrees.
            } catch {
                revertOptimistic(task.setting, because: .rejected)
            }

            // No immediate re-read: polling while the headset applies a change
            // (e.g. LTC on re-inits the radio) made it announce "configuration
            // failed". The lull re-reads later, as Android does.
            return
        }

        // Within the cooldown the headset may still report the pre-write value.
        if let lastWriteAt, ContinuousClock.now - lastWriteAt < Self.writeCooldown {
            return
        }

        guard let value = response.value else { return }
        confirmed.apply(value, to: task.setting)

        // Past the cooldown, this read settles any unconfirmed change.
        guard let expected = optimistic[task.setting] else { return }

        if value == expected {
            confirmOptimistic(task.setting)
        } else {
            revertOptimistic(task.setting, because: .notApplied)
        }
    }

    // MARK: - Teardown

    /// Called on disconnect. Stale settings on screen are worse than none.
    func haltAndDrain() {
        finishExchange()
        stopPolling()
        priorityQueue.removeAll()
        routineQueue.removeAll()
        pendingTask = nil
        lastWriteAt = nil
        // No failure message: a dropped link isn't a refusal.
        optimistic.removeAll()
        lastFailure = nil
        confirmed = HeadsetSettingsState()
    }
}
