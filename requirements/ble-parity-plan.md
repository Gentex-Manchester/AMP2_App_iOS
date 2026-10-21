# iOS BLE Integration & Android Parity — Plan

**Status:** Phases 1–6 implemented and verified on hardware. Phase 7 partly
done; the rest deferred — see that section for what is actually outstanding
versus what is self-imposed polish.
**Written:** August 3, 2026 · **Last updated:** August 4, 2026
**Trigger:** AMP 2.0 headset hardware received; Bluetooth is no longer blocked.

**No open blockers.** The LTC radio fault was resolved by a power cycle on
August 21, 2026, and the zone fault is a confirmed firmware defect (see below).

This plan covers everything the iOS app still needs to reach parity with the
Android app and with the product's final intended behavior. The encrypted
custom-teams database and cross-platform QR sharing are complete
([`docs/README.md`](../docs/README.md)); essentially everything that remains is
headset communication and the UI that depends on live headset state.

## Sources

| Source | What it establishes |
|---|---|
| Gentex's *LTC Configuration Commands (BLE)* document (July 27, 2026) | GATT service/characteristics, packet format, setting IDs, value tables, polling sequence, headset variant query |
| Gentex's GaiaInterfaceExample project (July 27, 2026) | Peter's proof-of-concept CoreBluetooth app. Explicitly "don't feel obligated to use it" — reference only |
| Gentex email, July 7, 2026 | LTC Mode moves inline onto the Headset screen; the dedicated LTC Mode screen is removed; VAD Threshold moves to the bottom of the Headset screen |
| Gentex email, July 20, 2026 | Final Team Details design (view/edit modes) — **already implemented** |
| Gentex email, July 28, 2026 | RF channels 6–11 dropped entirely; all regions get 1–5 — **already implemented** |
| `Gentex_Android/` (reference only, never edit) | The behavioral target: `protocol/`, `connectivity/`, `ui/screens/headset/`, `ui/screens/teams/` |

---

## UI scope and constraints

This work adds screens and changes existing ones. Phase 5 rebuilds the Headset
screen, Phase 6 adds team join and active-team state, and several new subpages
appear along the way. That is expected and in scope.

**What must not change:**

- **Navigation chrome.** The custom horizontal tab bar in portrait and the
  landscape sidebar layout, both in `ContentView.swift`, stay exactly as they
  are. New screens are pushed inside the existing `NavigationStack`s, not
  bolted onto the root layout.
- **Orientation settings.** `OrientationMode`, `OrientationLock`, the
  `AppDelegate` orientation locking, and `OrientationSettingsView` are finished
  and out of scope. New screens must work in both orientations, but they adapt
  to the existing system rather than extending it.
- **Appearance settings.** `AppearanceMode`, `AppearanceSettingsView`, and the
  light/dark handling are finished and out of scope. New screens inherit the
  existing appearance handling and must look right in both modes.
- **The sidebar-side preference** and any other `@AppStorage`-backed display
  preference already shipped.

**Match Android's behavior, not its appearance.** The Android screens are the
functional specification — which settings exist, what polling does, how joining
a team works. They are not a visual reference. Every new screen follows the
existing iOS conventions:

- `.font(.ibmPlexSans(size:weight:))`, never system fonts
- `Color.opsCoreRed` (#E31B23) accent, `Color(.systemGray4/5/6)` backgrounds,
  16pt corner radius on every rectangle, `.opacity(0.50)` for deselected states
- Subviews as `private var fooView: some View` computed properties, never
  `@ViewBuilder func`
- New destinations added to the existing `SettingsRoute` enum in
  `AppSettingsView.swift`, following the pattern already there
- A `#Preview` on every new view

If a new screen has no iOS precedent, model it on the closest existing one —
`RegionsView` and `VADThresholdView` are the templates for a settings subpage,
`TeamsDetailsView` for anything with view/edit modes.

---

## Phase 0 — Decisions

All five are settled. Nothing is waiting on Gentex; no questions were sent.
Each records what we chose and why, so the reasoning survives if the choice
turns out wrong on hardware.

### 0.1 Headset identification — service UUID, then part number

The BLE documentation says to identify legitimate headsets by the MAC prefix
`80:3B:70:XX:XX:XX`. **iOS does not expose Bluetooth MAC addresses to apps.**
CoreBluetooth gives an opaque, per-app, per-device `CBPeripheral.identifier`
UUID; there is no public API that returns a hardware address, over BLE or
Classic. The Android approach (`bluetoothAdapter.bondedDevices` filtered on
address prefix) has no iOS equivalent. Peter's own sample doesn't implement the
MAC check either — it lists every peripheral it finds and displays
`peripheral.identifier.uuidString`.

**Decision — revised August 3, 2026 after hardware testing.** The original plan
was wrong in a way only hardware could reveal, and both of its discovery paths
failed:

> **The AMP 2.0 advertises no service UUIDs at all.** An unfiltered scan finds
> it (`Gentex_AMP2.0_PROTO-123456`, RSSI −47, `advertises: (none)`), but
> `scanForPeripherals(withServices: [gaia])` never matches it. Separately,
> `retrieveConnectedPeripherals(withServices:)` returns nothing until some app
> has connected to the peripheral over BLE at least once — iOS has no GATT
> service record for a device that has only been paired over Classic. In
> hindsight the tell was in Peter's sample all along: it scans with
> `withServices: nil`.

Identify in this order:

1. **Remembered** — `retrievePeripherals(withIdentifiers:)` for a headset this
   app has connected to before. Its identifier is persisted on first successful
   connection. No scan.
2. **System-connected** — `retrieveConnectedPeripherals(withServices: [gaia])`.
   Only ever returns anything after path 3 has succeeded once, for the reason
   above, so it is an optimization rather than a primary path.
3. **Unfiltered scan**, shortlisted by name (`gentex` or `amp`, case-insensitive,
   mirroring Android). This is the path that actually finds a new headset.

Because there is no service filter, the name heuristic is load-bearing rather
than cosmetic — it is the only pre-connection signal available. Legitimacy is
still established after connecting: a device lacking the GAIA service fails
with `.serviceNotFound` and is dropped, and the part-number query
(`00 1d 40 0c 00 00 00 2f`) confirms what answered.

**Variant gating** (superseded: Gentex dropped the gate in Phase 3) — allowlist `1004257` (Flagship) and treat everything else as
not-Flagship, so an unknown variant fails closed rather than wrongly unlocking
custom teams. `1004257` is corroborated by the worked example in the BLE doc;
`1004058` (Base) comes from `Gentex_Android/…/models/Headset.kt`, which is the
only record of it — noted here so it isn't lost, but nothing branches on it.

**Region lock** — parse the ASCII part number from the response, take the last
eight digits ignoring hyphens, and read the third-to-last as the kit: `0` =
North America locked, `3` = Europe locked, `1`/`2` = unlocked. Our unit is kit
`2` per the doc's example (`1004257-1201-1201` → `12011201`), so **the
region-locked path cannot be tested on the hardware we have** — it needs review
by inspection, or a locked unit later.

### 0.2 Tx Power — use the BLE doc's table

The BLE doc (rev. July 24, 2026) and the Android implementation disagree:

| | Values | Range |
|---|---|---|
| BLE doc | 10 (`0x00`–`0x09`) | −18 dBm … +10 dBm in 3 dBm steps |
| Android `models/HeadsetSettings.kt` `TxPower` | 11 (`0x00`–`0x0A`) | −40 dBm … +10 dBm in irregular steps |

**Decision:** follow the BLE doc. It is the newer document and it describes the
unit that was shipped to us; the Android enum most likely reflects earlier
firmware. Transport is not the cause of the difference — Tx Power is setting
`0x07` on the LTC radio, and the payload byte means the same thing over BLE or
SPP.

Verify on hardware before shipping: write each value and confirm the headset
returns `LTC_NO_ERR` rather than `LTC_BAD_VALUE`. If `0x0a` is accepted, the
Android table is closer to right and this decision needs revisiting with Peter.

### 0.3 Network ID — move iOS to 0–255

| | Accepted range |
|---|---|
| iOS `TeamValidation.validateNetworkId` | **1–256** |
| Android `CustomTeamsViewModel` | **0–255** |
| Headset (BLE doc, setting `0x04`) | any one byte, **0x00–0xFF = 0–255** |

iOS is wrong on both ends: it rejects `0`, which Android accepts and the headset
allows, and it accepts `256`, which cannot be encoded in the one-byte payload.
A team created on Android with network ID 0 imports as invalid on iOS today,
and a team created on iOS with 256 could never be written to a headset.

**Decision:** iOS moves to 0–255 to match Android and the hardware, after
confirming a team with network ID 0 round-trips through the QR contract and
writes to the headset successfully. This changes the documented QR contract
([`docs/qr-contract.md`](../docs/qr-contract.md) states 1–256), so give David a
heads-up as a cross-platform contract change. Fix this in Phase 1 regardless of
BLE progress — it is a live interop bug today.

### 0.4 State management architecture

The project conventions mandate pure SwiftUI: no ViewModels, no
`ObservableObject`, all logic in views, `@State` and `@AppStorage` only. That
convention does not survive contact with a BLE peripheral that pushes
asynchronous notifications into nine cached settings shared across five screens.

**Decision:** introduce observable objects for the headset subsystem only,
using Swift's Observation framework (iOS 17+, so no back-deployment concern)
and injected through `@Environment`. Views stay otherwise pure. This is a
deliberate, documented exception, not an opening to add ViewModels everywhere;
the project conventions get updated in the same change to say so.

**Amended in Phase 4 — two objects, not one.** The original wording said
"exactly one." Building it showed that conflated two responsibilities that want
separate lifetimes and tests:

- `HeadsetSession` — the transport. `CBCentralManager`, discovery, connection
  state, raw packet in/out. Knows nothing about LTC semantics.
- `HeadsetSettingsSync` — the protocol conversation. The cached settings, the
  heartbeat, the priority write queue.

Keeping them fused would have meant a single type doing CoreBluetooth delegate
work and protocol queueing, untestable apart. The spirit of the decision holds:
the headset subsystem owns its state in one place, and nothing else in the app
gains an observable object.

Rejected alternatives: a global singleton (untestable, no injection point for a
mock headset) and threading state through `@State` bindings (five screens deep,
unworkable).

### 0.5 App region vs. headset zone

iOS currently persists region in `@AppStorage("selectedRegion")` and uses it for
team validation. The headset has its own zone setting (`0x0a`) which is
authoritative and, on region-locked units, immutable.

**Decision:** when a headset is connected, the headset's zone is the source of
truth and the app mirrors it into `@AppStorage`; when disconnected, the stored
value is used for validation and display. On a region-locked headset the zone
selector is hidden entirely (per the BLE doc). Since all regions now share
channels 1–5, region no longer gates team validity at all — it is display and
headset-write state only.

---

## Phase 1 — BLE transport foundation

1. **Add `NSBluetoothAlwaysUsageDescription`** to the build settings as
   `INFOPLIST_KEY_NSBluetoothAlwaysUsageDescription` for all three
   configurations. Done — without it the app crashes the moment a
   `CBCentralManager` is instantiated. (`NSCameraUsageDescription` is
   already there as the pattern to follow.)
2. **`Bluetooth/HeadsetSession.swift`** — `@Observable`, owns `CBCentralManager`
   and `CBPeripheralDelegate` conformance. Connection state enum mirroring
   Android's: `disconnected`, `connecting`, `connected`, `error(String)`.
3. **Discovery** per 0.1: `retrieveConnectedPeripherals` first, scan as fallback.
4. **GATT wiring** — service `00001100-d102-11e1-9b23-00025b00a5a5`, write
   characteristic `…1101`, notify characteristic `…1102` with
   `setNotifyValue(true, …)`.
5. **Fix the network ID range** (0.3) in `TeamValidation`, the QR contract doc,
   and the tests.
6. **Multiple-headset selection** — the BLE doc requires letting the user pick
   when more than one legitimate headset is connected. New screen; follow the
   existing list-row styling from `TeamsView`.

**Verification:** connect to the physical headset, confirm the service and both
characteristics are discovered, confirm notifications arrive. No packet
semantics yet — raw hex only.

## Phase 2 — LTC protocol codec

**Do not port Android's `PacketBuilder` verbatim.** Android frames every packet
for RFCOMM/SPP: `FF 03 01 <len>` header plus a trailing XOR checksum wrapped
around the LTC packet. Over BLE GATT the headset expects the bare inner packet —
`00 1d 40 2c <op> <setting> <len> [payload]` — with no framing and no checksum.
This is the single most likely place to lose days if it is missed.

1. **`Bluetooth/LTCPacket.swift`** — setting IDs (`0x00` team, `0x01` security
   key, `0x03` RF channel, `0x04` network ID, `0x05` LTC mode, `0x06` VAD
   threshold, `0x07` TX power, `0x08` LTC volume, `0x0a` zone), read/write op
   codes, encoder.
2. **`Bluetooth/LTCResponse.swift`** — validate the `00 1d 41 2c` response
   header, extract the payload, map status codes (`LTC_NO_ERR` 0x00,
   `LTC_ERR_LEN` 0x01, `LTC_BAD_VALUE` 0x02, `LTC_ERR_COMM_FAIL` 0x03) to a
   `LocalizedError` enum following the existing `DatabaseError` pattern.
3. **Value enums** — `LTCMode`, `TxPower` (BLE doc table, per 0.2), `Zone`, and
   the byte mappings for the existing `SecurityKey` and RF channel. The doc's RF
   channel table has a typo (`0x10 – Channel 11`); the correct value is `0x0a`,
   confirmed by the Set Custom Team section and by Android. Moot while 6–11 are
   unsupported, but do not copy the typo.
4. **Tests** — full encode/decode round-trip coverage, in a new
   `Gentex_iOSTests` suite. These are pure byte-manipulation tests requiring no
   hardware, so they run in CI like the existing 59.

No UI in this phase.

## Phase 3 — Headset identity and region lock

**Scope reduced (August 2026):** Gentex removed the requirement that custom
teams be exclusive to the Flagship headset. There is no variant gate to build
and none to enforce — custom teams work on every AMP 2.0 headset. This phase is
now only about region locking.

1. Issue the part-number query `00 1d 40 0c 00 00 00 2f` on connect and parse
   the ASCII response into e.g. `1004257-1201-1201`.
2. **Region lock** — kit digit per 0.1. When locked, hide the region/zone
   selector entirely. Our unit is kit `2` (unlocked), so this path can only be
   verified by inspection until a locked unit is available.
3. The variant (`1004257` Flagship, `1004058` Base) is still readable from the
   part number, but nothing branches on it. Do not reintroduce a variant check
   without confirming the requirement has changed back.

Consequences elsewhere:

- The Flagship-headset detection and gate-test issues are obsolete — close them.
- `DEV_NO_GATE` and the `Debug-Dev` configuration now gate nothing. The scheme
  is worth keeping for development-only features such as the Phase 4 packet
  console; the flag should be repurposed or renamed when that lands, not left
  as a misleading name.
- The locked-team UI (`LockedTeamDetailsView`, `Team.isLocked`) is **not**
  related to this gate — `is_locked` is per-team state reserved for
  active-team detection in Phase 6. Leave it alone.

## Phase 4 — Live settings state and the command queue

Mirror Android's `HeadsetManager` semantics, which exist because the hardware
misbehaves without them:

- **Two queues** — a priority queue for user-initiated writes and a routine
  queue for polling; writes always preempt polls and flush pending polls.
- **200 ms inter-packet delay** to avoid overflowing the headset's buffer.
- **5 s heartbeat** polling all nine settings in sequence.
- **3 s post-write cooldown/lull** — ignore poll responses briefly after a write
  and pause the heartbeat while the user is actively dragging a slider, so stale
  reads don't fight the UI.
- **Halt everything on disconnect** and drain both queues.

Copy Android's timings as-is and validate against the hardware. They were tuned
for the SPP transport, and BLE differs in MTU and notification delivery, so
treat them as a starting point rather than a specification — if the headset
drops packets or lags, tune here first.

Swift shape: an `AsyncStream`-driven actor, or a global actor for the BLE queue.
(The unused `DatabaseActor` this once suggested reusing was removed in September
2026.)

**Also add a packet console** — Android has `GentexLogger`, `PacketLog`,
`ConsoleLogRow`, and a Developer Options screen. During bring-up this is not a
nicety; it is how you diagnose a headset that stops responding. Build it early
in this phase, behind the Dev scheme or a hidden settings gesture. This is a
developer tool, so it is the one screen where visual polish is not required —
monospaced hex rows are fine.

## Phase 5 — Rebuild the Headset screen

The current `HeadsetView` is a static mockup: three of its four
`NavigationLink`s point at `SettingsRoute.orientation` as placeholders, and
nothing is bound to data. This phase changes the *contents* of the Headset tab
only. The tab bar, the landscape sidebar, and both settings screens named in the
UI constraints section stay untouched.

Per the 07/07 email:

1. **LTC Mode inline** on the Headset screen; **delete `LTCModeView.swift`** and
   the `.ltcMode` route.
2. **VAD Threshold** link at the bottom of the Headset screen, shown only when
   LTC Mode is VAD/VOX. `VADThresholdView` already exists — rewire it, don't
   redesign it.
3. **New subpages matching Android's** — LTC Volume (`0x00`–`0x0a`), LTC Power /
   TXPWR, Region/Zone. Android's equivalents are
   `ui/screens/headset/HeadsetSubpageHost.kt`, but build them in the iOS idiom:
   `RegionsView` is the closest existing template, and the LTC Volume and TXPWR
   screens are the same shape as `VADThresholdView`.
4. **Comment out the "All-Hands" LTC mode option** rather than deleting it,
   matching Android's `ALL_HANDS(0x03, "All Hands")` in
   `models/HeadsetSettings.kt`. The BLE doc defines only Off/PTT/VAD, so it must
   not be reachable, but the value is preserved in case it returns.
5. Bind `DisconnectedView`, `HeadsetView`, and `ConnectionTutorialView` to real
   connection state. These views already exist and are styled — this is wiring,
   not a redesign.
6. **Rewrite the connection tutorial copy** — it must tell users to pair the
   headset over Bluetooth Classic **in iOS Settings first**, because BLE only
   becomes available afterward and an iOS app cannot initiate Classic pairing
   itself. A genuine iOS-vs-Android UX divergence; mention it to Peter when the
   screen is built so the Android tutorial doesn't drift out of sync.
   `ConnectionTutorialView`'s existing layout and `TutorialData` structure carry
   over; only the steps change.

   There is **no public API that deep-links to the Settings ▸ Bluetooth pane**.
   `UIApplication.openSettingsURLString` opens our own app's settings page;
   `App-Prefs:root=Bluetooth` is a private scheme with a history of App Store
   rejections and of breaking between iOS releases. Plan for: Connect button →
   explanatory sheet → button to our app's settings page, with text directing
   the user onward to Bluetooth. **Open question for whoever builds this:** if
   the app ships via enterprise/MDM rather than the App Store, the private
   scheme becomes viable — confirm the distribution channel first.
   Separately, `CBCentralManagerOptionShowPowerAlertKey` gives a system alert
   with a working Settings button when Bluetooth is switched *off* — public API,
   worth using, but it does not cover the pairing case.

## Phase 6 — Teams ↔ headset

1. **Preset teams** — Alpha, Bravo, Charlie, Delta, Joint Ops, with the settings
   from the BLE doc (all security key Mike; RF/network ID 2/100, 3/125, 4/150,
   5/175, 1/200 respectively). `TeamsView` already has a `builtInTeamsSection`
   placeholder waiting for exactly this, so the row styling is settled.
2. **Preset favorites** — persisted in `@AppStorage`, matching Android's
   `PresetFavoritesRepository`. Reuses the existing favorites UI.
3. **Active-team detection** — compare the headset's polled team, security key,
   RF channel, and network ID against the presets; a mismatch means a custom
   team is active, and it is matched against the local database. This closes
   the active-team detection issue. The reserved `is_locked`
   column stays unused. Needs a new active-team indicator on team rows — the
   one genuinely new visual element in this phase.
4. **Join team** — write security key, then RF channel, then network ID in quick
   succession as a batch of priority writes (Android's `batchPriorityEnqueue`).
   Disabled with an explanatory message when no headset is connected.
5. **Team Details join action** — the view/edit-mode redesign is already in and
   must not be reworked; the join button and active badge slot into the existing
   button group.

## Phase 7 — Remaining parity and quality work

Two different kinds of work live in the issue tracker, and they should not be
read as one list. Distinguishing them matters because Phase 7 otherwise looks
like a checklist that has to be cleared before the app can ship.

### Customer-driven — Gentex asked for these

Traceable to a requirement, an email from Peter, or Android parity.

- `001-bluetooth-headset-integration` — **closed**, superseded by this plan.
- `002-active-team-detection` — **closed**, implemented in Phase 6.
- `007-camera-qr-scanning` — **closed**, shipped in `bbcb361`.
- `003-flagship-headset-detection`, `006-flagship-gate-tests` — **closed as
  obsolete**; Gentex withdrew the variant gate.
- `004-custom-security-key` — still reserved and out of scope. The BLE
  documentation confirms the hardware setting (`0x02`) is "not implemented at
  this time", so this is blocked on firmware and on Android implementing it
  first.

### Engineering quality — our own judgement

Not requested by anyone outside the team, but load-bearing for correctness.

- **Fake-transport seam for `HeadsetSettingsSync`** — **done.** The queue,
  lull, and cooldown logic could only be exercised against a live headset,
  which is how two bugs reached hardware. `HeadsetTransport` plus a fake makes
  it unit-testable.
- `009-database-migration-tests` — **closed.** Migrations are the one place a
  bug corrupts data the user cannot recreate.
- `011-error-ui-for-db-failures` — **closed.** Failures were swallowed, and a
  failed read blanked the team list, making "no teams" and "the read failed"
  indistinguishable.
- `005-asset-catalog-warnings` — **closed.**

### Deferred — self-imposed polish, no external requirement

**These were authored by the team in commit `c544516` and parked in
milestone-3-polish. No Gentex requirement, email, or Android parity gap calls
for any of them.** They are worth doing eventually; none of them blocks
shipping, and none should be treated as outstanding work against this plan.

- `008-accessibility-audit` — **deferred.** Genuinely untouched: the app has
  zero accessibility modifiers and 13 icon-only controls that VoiceOver cannot
  describe. Note the issue's premise about Dynamic Type is wrong —
  `Font.custom(_:size:)` has scaled automatically since iOS 14; the real
  refinement is `relativeTo:` so headings do not scale like body text. Half of
  this issue (rotor order, VoiceOver navigation) cannot be verified without a
  device running VoiceOver, so do not ship it untested.
- `010-localization-infrastructure` — **deferred.** English-only is a
  deliberate current state; `resConfigs "en"` on Android says the same.
- `012-landscape-orientation-testing` — **deferred.** Landscape works; this
  asks for systematic verification, which needs device time rather than code.

Not in scope: direct SPP/serial communication (the doc explicitly leaves it
undocumented), the `0x09` hopping setting Android references but the doc does
not define, full-database import/export, and any change to the navigation,
orientation, or appearance systems.

---

## Sequencing and risk

Phases 1→2→3→4 are strictly sequential; 5 and 6 both depend on 4 but are
independent of each other and can proceed in parallel.

Nothing is blocked on Gentex. Every Phase 0 item was decided locally, which
means the risk moved from "waiting for an answer" to "our assumption is wrong
and the hardware tells us late." Status of the four assumptions:

1. ~~**Service UUID advertisement** (0.1)~~ — **disproved on hardware, Aug 3.**
   The headset advertises nothing. Discovery rewritten around an unfiltered
   scan with a name shortlist; see 0.1. Cost: one afternoon, no Gentex
   involvement needed.
2. **Tx Power table** (0.2) — still open. Write `0x0a` and see whether the
   headset returns `LTC_BAD_VALUE` (doc is right, 10 values) or `LTC_NO_ERR`
   (Android is right, 11 values). One packet settles it, but it is a *write* to
   a live radio setting, so do it deliberately and restore the previous value.
3. **Network ID 0** (0.3) — still open. Write it and confirm `LTC_NO_ERR`.
4. **Android's timings over BLE** (Phase 4) — still open. 200 ms/5 s/3 s were
   tuned for SPP; MTU and notification delivery differ.

If 2 comes back against us, that is when to email Peter — with a hardware
result attached rather than a question.

## RESOLVED — LTC mode, by a battery pull (August 21, 2026)

**Removing the headset's battery and refitting it clears the `0x04` state.** PTT
and VAD then write and read back correctly. Confirmed on hardware.

So `0x04` is a latched failure state rather than a permanent fault: once the
radio fails to come up the headset stays there, and only a power cycle recovers
it. Whether a menu reboot would do as well is untested.

Gentex is still worth telling — a headset should not latch into an undefined
state that only a battery pull clears — but this no longer blocks the app, and
**VAD threshold is testable again**.

A separate fault, **zone changes are refused**, is closed: Gentex confirmed on
August 25, 2026, that setting `0x0a` is broken in the headset firmware. See
`docs/ble-protocol.md` §8.

The original report follows, since it is what the fault looks like when live.

## Open blocker — LTC mode cannot be changed (August 3, 2026)

**Headset-side, not ours.** Writing LTC mode PTT (`0x01`) or VAD (`0x02`) is
acknowledged with `LTC_NO_ERR`, after which the headset announces
"configuration failed, try again" and the setting reads back as `0x04` — a
value the documentation does not define. Writing Off (`0x00`) works and reads
back correctly, so writes reach the headset and take effect; only bringing LTC
*up* fails. The headset was confirmed at `0x00` before a failed PTT attempt and
transitioned into `0x04`, so `0x04` appears to be an initialization-failure
state rather than a stale boot value.

Reported to Gentex on August 3, 2026, with full hex transcripts.

**Resolved by testing (August 4, 2026): the fault is in the headset, not the
BLE path.**

- LTC mode fails from the **headset's own button menu**, double-pressing the
  centre button as Gentex suggested. No phone involved.
- Changing **Tx power from the headset's own menu** also announces "selection
  confirmed, configuration failed" — yet that setting *does* apply and the app
  reads the new value back.

So the failure announcement accompanies operations that require the LTC radio
to reconfigure, whether or not the stored value takes. LTC mode is the case
where the value also fails to stick, because it needs the radio to come up
rather than merely be re-tuned. Everything points at the radio subsystem on
this prototype unit.

Why the asymmetry between Off and PTT/VAD is informative: `0x00` tears the
radio down, which cannot really fail, while `0x01` and `0x02` require it to
come *up* on the configured channel, key, and network ID. The audible sequence
("LTC initializing" → "LTC on PTT" → "configuration failed") shows the mode
being accepted and the radio bring-up failing behind it. The mode value is not
being rejected.

Unverified hypotheses, in rough order of likelihood: the unit is a prototype
(`PROTO` in its advertised name) whose LTC radio may not be fully enabled; one
of the seven unexplained feature digits in the part number gates LTC; or a
firmware bug specific to the BLE path, which Gentex only recently made
reachable from iOS and had already found two bugs in during July.

Consequences while this is open:

- **VAD Threshold is untestable.** It only applies in VAD mode, which cannot be
  entered.
- **`LTC_NO_ERR` cannot be trusted as confirmation.** The headset returns
  success before it knows whether the setting will apply, so the app cannot
  detect this failure from the protocol. Re-reading after the lull is the only
  signal, and even that only shows the value did not change.
- **Phase 6 is unaffected** — teams are written via security key, RF channel,
  and network ID, none of which involve LTC mode.

## Confirmed on hardware (August 3–4, 2026)

Verified against `Gentex_AMP2.0_PROTO-123456` on a physical iPhone:

- **Writes work, in both directions.** The app changes team, Tx power, and LTC
  volume, and each is confirmed by reading the value back. Changes made on the
  headset's own menu appear in the app within one heartbeat. Only LTC mode
  fails, and it fails from the headset's controls too.
- **The full read path is validated.** All nine settings poll correctly, and
  active-team detection agreed with the headset without being told.

- **The BLE wire format is correct as implemented.** The headset answers a bare
  packet with no SPP framing and no XOR checksum. Had that call gone the other
  way, nothing would have responded.
- **Part number `1004257-1201-1201`** — byte-for-byte the documentation's worked
  example. Identity query, response parse, and kit-digit extraction all work.
- **Region lock: none** (kit digit `2`). As predicted, this unit cannot exercise
  the region-locked path; it needs review by inspection or a locked unit.
- **GATT is exactly as documented** — service `00001100-…`, write `…1101`,
  notify `…1102`, notifications delivered.
- **Bluetooth Classic pairing is a hard prerequisite.** With the headset merely
  in pairing mode and visible in iOS Settings, no BLE service exists. It must
  read "Connected" first. This needs to be explicit in the connection tutorial
  (Phase 5.6) — it is not obvious, and it cost a test cycle here.

## Documentation to update on completion

Per the repo's docs-in-sync rule: `README.md`, `requirements/README.md` (the
Bluetooth section is still marked blocked), the project conventions (the
`@Observable` exception from 0.4 and the removal of the Bluetooth-blocked
pitfall), `docs/qr-contract.md` (network ID range), and a new
`docs/ble-protocol.md` capturing the wire format as implemented — including the
BLE-vs-SPP framing difference and the doc errata found here.

---

## In-app pairing ruled out (August 2026)

Gentex asked whether the iOS tutorial could send the user straight to the system
Bluetooth pairing screen, as the Android tutorial does. **It cannot.** iOS
exposes no public URL for that screen; `UIApplication.openSettingsURLString`
opens the app's own permission page, which is what the old tutorial did and what
Gentex flagged as confusing. `App-Prefs:root=Bluetooth` is private API.

AccessorySetupKit (iOS 18+) was evaluated as the alternative, since it can pair
an accessory without leaving the app. **It cannot discover the AMP 2.0.** An
`ASDiscoveryDescriptor` must match on a company identifier or a service UUID;
matching on name alone raises a fatal error rather than returning one. The
headset advertises neither. See `docs/ble-protocol.md` §10 for the measurement
and the two traps that make it awkward to reproduce.

Decisions that followed:

- The tutorial explains the Settings route properly, including the
  paired-versus-Connected distinction, and offers no button. This is what Gentex
  asked for as the fallback.
- The AccessorySetupKit integration was **removed**, not left dormant.
  Declaring `NSAccessorySetupKitSupports` can restrict CoreBluetooth to
  ASK-authorized accessories, which is a live risk to a discovery path that
  took two hardware cycles to get right, in exchange for a feature that provably
  cannot work.
- The **iOS 18.0 deployment floor was kept** even though it was originally
  raised for AccessorySetupKit. iOS 18 supports the same devices iOS 17 does, so
  it excludes no hardware.
- `DiscoveredHeadset.manufacturerData` and the packet console's company-identifier
  row were **kept**, so the finding is re-checkable in a few taps rather than
  from memory.

**Do not ask Gentex to change the advertisement to enable this.** Researched
August 2026: it would make the headset discoverable by the picker and still not
make pairing work. AccessorySetupKit does not set up Bluetooth Classic devices;
the Classic link appears only when the accessory implements Cross-Transport Key
Derivation, which is stack-level firmware work on a legacy Qualcomm/CSR part
rather than a change to what it broadcasts. The only public attempt to exercise
that path reported it failing. Full evidence and citations in
`docs/ble-protocol.md` §10.

That research also confirmed the removal decision was right rather than merely
cautious: declaring `NSAccessorySetupKitSupports` stops `CBCentralManager`
reaching `poweredOn` until an accessory is ASK-authorized and confines scanning
to ASK-known peripherals, which would have broken the unfiltered scan outright.
