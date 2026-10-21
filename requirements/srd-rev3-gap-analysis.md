# SRD rev 3 — gap analysis and plan (iOS)

Source: [`docs/Gentex/08242026 SRD rev3/SRD1005074_rev3_DRAFT.odt`](../docs/Gentex/08242026%20SRD%20rev3/), received August 24, 2026.

**Rev 3 is authoritative.** The file is marked draft and its revision table
carries no release date, but Gentex confirmed on August 24, 2026 that it is the
latest document and the source of truth. The removals below are approved: they
are work to schedule, not decisions to wait on.

Three standing decisions shape what follows:

- **Android is the source of truth for iOS.** Where a requirement needs a shared
  answer Android has not solved, iOS waits rather than inventing one.
- **Per-team security keys wait for documentation.** The BLE command document
  still marks the custom key `0x02` "not implemented at this time".
- **Develop against the headset in hand.** No speculative support for models we
  cannot test.

Rev 2 was previously logged as superseded in [`docs/decisions.md`](../docs/decisions.md).
Rev 3 now supersedes rev 2. No copy of rev 2 was ever stored in this repo.

---

## What rev 3 changed

Straight from the revision table:

- Removed the custom team system
- Removed saved data requirements
- Added requirements for pairing and interfacing with devices, including over USB
- Adjusted the requirement for how the app handles multiple connected devices
- Adjusted the available configuration settings
- Added requirements for customizing the security keys of teams
- Added App Store approval requirements (Miscellaneous Requirements)
- Added testing requirements

---

## The zone setting shrank from three values to two

Rev 3 lists Zone as **`AMERICAS`** and **`EUROPE & ASIA`**. Two options. This app
sends three — North America `0x00`, Latin America `0x01`, Eurasia `0x02` — which
came from the BLE command document, not the SRD.

This looked like an explanation for the zone bug in `docs/ble-protocol.md` §8:
if the firmware now recognizes only `0x00` and `0x01`, the app's `0x02` would be
out of range and a headset that accepts and ignores it produces exactly the
observed behavior.

**Tested on August 24, 2026. It is not the cause, and the bug is now understood.**
Sweeping `0x00` through `0x07` produced `LTC_NO_ERR` eight times with no change,
including for values undefined anywhere in the documentation. A control write of
an out-of-range LTC volume returned `LTC_BAD_VALUE`, so the headset does
range-check settings it processes. Zone gets no check, meaning the write is
discarded. Setting `0x0a` is read-only on this unit.

The zone count still has to be settled, because it decides what the region
control offers — assuming it stays at all. See `docs/ble-protocol.md` §8.

---

## Settings: what rev 3 asks for versus what the app does

| Setting | Rev 3 | This app today | Status |
|---|---|---|---|
| Team | ALPHA, BRAVO, CHARLIE, DELTA, JOINT OPS | Presets, plus user-defined custom teams | **Custom teams now out of scope** |
| ALPHA…JOINT OPS Security Key | One key **per team**, ten NATO words (VICTOR default) or any AES-256 key | **One** global security key setting (`0x01`), ten NATO words, Mike default | **Gap — model change** |
| LTC Mode | PTT, VAD, Off | Same | Matches |
| VAD Level | 0–10 | Same | Matches |
| TXPWR | 1–10 | Ten values, −18 dBm to +10 dBm | **Clarify** |
| LTC Volume | 0–10 | Same | Matches |
| Zone | AMERICAS, EUROPE & ASIA | North America, Latin America, Eurasia | **Gap — see above** |
| RF Channel | Not listed | 1–5, editable through custom teams | Out of scope with custom teams |
| Network ID | Not listed | 0–255, editable through custom teams | Out of scope with custom teams |

Two details worth not missing: the default security key is **VICTOR** in rev 3,
where this app uses Mike for presets; and TXPWR is written as **1–10** rather
than a dBm range, which may be a labelling difference or a real range change.

---

## What already satisfies rev 3

No work needed. Listed so nobody rebuilds them.

- BLE connection to the headset, with automatic reconnect to a known headset
- Part-number query used to identify a compatible headset
- One headset at a time
- Disconnect detection, with cached settings cleared so nothing stale is shown
- Regular polling of live settings, since the user can change them on the headset
- Bluetooth and camera permission requests, with a permissions screen
- Dark and light mode
- Portrait and landscape, chosen from app settings rather than following the device
- Bluetooth connection guide, which directs the user to the system Bluetooth screen
- User manual screen
- Privacy and Contact Us screens
- Settings are held in memory only and cleared on disconnect

---

## Gaps

### A. Approved removals

Each deletes working, tested, shipped code. Approved by Gentex on August 24,
2026; scheduled as phase 3 (on hold).

- **A1. Custom team system removed.** Affects the SQLCipher database,
  `TeamStore`, `Team`, `TeamValidation`, `TeamSchema`, the Teams tab, the create
  and edit screens, and the team QR export and import flow. This is the largest
  single body of work in the app.
- **A2. "Shall not save any configuration settings after disconnect."** The
  headset settings layer already complies. The custom teams database does not,
  because storing teams is the point of it. Resolved by A1 either way.
- **A3. Encryption-at-rest architecture.** With no persisted data, SQLCipher, the
  Keychain key, and the migration runner all lose their reason to exist. Removing
  them would also drop the `AppDependencies` package and its embed-frameworks
  requirement, which is a meaningful simplification.

### B. New requirements, safe to build now

- **B1. Per-team security keys.** Five settings rather than one. Needs the wire
  encoding from Gentex: the BLE command document defines a single security key at
  `0x01`, with `0x02` reserved for a custom key and marked "not implemented at
  this time."
- **B2. Passphrase-derived AES-256 keys**, deterministic so two users entering
  the same passphrase get the same key. Needs an agreed derivation — algorithm,
  salt, and iteration count — shared with Android, or keys will not match across
  platforms.
- **B3. Share security keys by QR**, covering all five teams.
- **B4. Load security keys from QR, applied to the headset immediately** on scan.
  Different from today's flow, which imports into the database and requires a
  separate join.
- **B5. Clear team security key settings.**
- **B6. Model-specific interface.** Use the official names, "AMP 2.0 Elite" and
  "AMP 2.0 Pro", show the right imagery, and hide the region control where the
  model does not support it. `HeadsetView` currently hardcodes "AMP 2.0 Elite".
  The part number already tells us the model; only the mapping is missing.
- **B7. "Headset disconnected" popup**, showable from any screen, returning the
  user to the nearest screen that does not need a headset.
- **B8. Multiple compatible devices → tell the user to disconnect and unpair all
  but one.** This replaces `HeadsetPickerView`, which currently asks the user to
  choose one.
- **B9. Direct the user to enable Bluetooth** when it is switched off.
- **B10. Track permission state** so the app does not use a capability it has lost.
- **B11. Demo mode**, full interface without a headset, hidden behind a secret menu.
- **B12. Log export**, encoded so the end user cannot easily read it.
- **B13. Explain wired versus wireless at first launch**, then direct the user to
  the system Bluetooth screen. Wired is Android-only; iOS is BLE only, so the iOS
  wording needs to say so without implying a missing feature.
- **B14. Accessibility.** Respect system text size and contrast settings. Dynamic
  Type scaling is in; the app has no accessibility modifiers yet and has icon-only controls VoiceOver cannot
  describe.

### C. Testing gaps

Rev 3 sets hard numbers. When rev 3 arrived the suite met none of them; phase 5
(below) addressed all four.

- **C1. 80% code coverage minimum** on application code. Coverage is not measured
  at all today.
- **C2. Integration tests** across major components. None exist.
- **C3. UI tests** for primary workflows including launch and navigation. The UI
  test target contains only Xcode's generated stubs.
- **C4. Test results as a deliverable.**

Note that the SRD says tests "shall be runnable from the command line using
Gradle", which is Android's build system. The iOS equivalent is `xcodebuild`, and
Gentex should confirm that reading.

### D. Cannot be done as written on iOS

Already established on hardware. Flag to Gentex rather than attempt.

- **D1. "Only check Bluetooth devices with a MAC address starting with 80:3B:70."**
  iOS never exposes Bluetooth MAC addresses to apps. `CBPeripheral.identifier` is
  a per-app UUID. The app shortlists by name before connecting and confirms
  legitimacy with the part-number query afterwards. See
  `requirements/ble-parity-plan.md` §0.1.
- **D2. USB connection.** Rev 3 scopes wired connection to Android only and iOS to
  BLE only, which matches what is built. The USB connection guide and the
  charging warning are therefore Android-only. Confirm no iOS USB guide is
  expected.
- **D3. GAIA over Bluetooth Serial Port Profile.** Rev 3 §4.3.1 describes SPP,
  which is the Android transport. iOS uses BLE GATT and the packet framing
  differs — no SPP header, no checksum. See `docs/ble-protocol.md` §1.
- **D4. Xcode 26.3** is specified; this project builds with 26.5. Harmless, but
  worth correcting in the next revision.

---

## Plan: seven phases

Each phase lists its own status. Phase 3 is on hold waiting on Gentex, and
phases 6 and 7 wait on answers from phase 1.

### Do now

**Phase 1 — Unblock.** Done.

- [x] Commit the rev 3 analysis and the Android-parity fixes
- [x] Fix team switching: a preset goes out as the single team command (`0x00`),
      not three setting writes. Confirmed on hardware
- [x] Diagnose the zone fault: setting `0x0a` is read-only on this unit, proved
      four ways. Recorded in `docs/ble-protocol.md` §8
- [x] Fix the app giving up on discovery after a disconnect or an empty scan
- [x] Report the zone defect to Gentex. Answered August 25, 2026: `0x0a` is
      bugged in the headset across all three transports, Android included. No
      app work on either platform. The region control stays as it is

**Phase 2 — Bug fixes, polish, and connection resilience.** Rev 3 B7, B9, B10,
plus the field reports.

Gentex reviewed the build on August 25, 2026: connection and the pairing flow
both pass, and the recommendation for the week is bug fixes and polish over new
features. Field-reported defects lead this phase.

- [x] Rotating inside a submenu threw the user back to the root. `ContentView`
      branched between a portrait `VStack` and a landscape `HStack`, which gave
      the content a new identity on every rotation and destroyed every `@State`
      below it. The content now holds one structural position and the tab bar
      moves around it with `.padding` and `.overlay(alignment:)`
- [x] B7 — "Headset disconnected" alert, presented from the root so it survives
      the screen it interrupts, and both navigation stacks trimmed back to the
      last screen that works without a headset. A deliberate disconnect stays
      silent
- [x] B9 — a Bluetooth radio fault now leads `DisconnectedView` instead of
      sitting under "No headset connected" as grey footnote text, and the
      Connect button is disabled while the radio is down. Scanning with no radio
      only fails again, and a dead button reads as the app being broken
- [x] B10 — the permissions list reports what iOS actually says per permission,
      re-read whenever the screen comes back to the foreground. The Bluetooth
      side of "never use a capability it lost" is B9's disabled button
- [x] A headset switched off and back on left the app stranded. Three faults on
      one path: auto-connect matched only `.disconnected` so it ignored the
      headset it had just found, the found-something branch of discovery never
      rescheduled, and a connection attempt to a powered-down headset pended
      forever in a state rediscovery will not interrupt
- [x] Tests for each. 141 tests across 19 suites

**Phase 3 — Remove the custom team system.** Rev 3 A1 to A3, plus B8.
**On hold, August 25, 2026.**

Gentex confirmed the removal is real and explained it: customers and Gentex
management found custom teams too complex and short of what they needed. The
replacement is simpler but needs headset firmware that is a couple of weeks
away, and the schedule for it is still being costed with our managers.

So the deletion waits. It is ~3,700 of 9,041 Swift lines — the Teams views, the
whole `Database/` layer, SQLCipher, and the `AppDependencies` package — and some
of it may be foundation the replacement builds on. Cutting it before the new
system is specified risks doing the work twice.

Two further reasons to wait, both worth re-checking when this resumes:

- **It would break the cross-platform QR contract unilaterally.** `QRCodeCrypto`
  is the iOS half of a byte-for-byte pact with Android's `util/Crypto.kt`, and
  Android has not dropped custom teams.
- **It is not the polish Gentex asked for this week.**

- [ ] A1 — remove custom teams: `TeamStore`, `Team`, `TeamValidation`,
      `TeamSchema`, the Teams tab, create and edit, team QR export and import
- [ ] A2 — falls out of A1: no configuration settings saved after disconnect
- [ ] A3 — remove SQLCipher, the Keychain key, the migration runner, and the
      `AppDependencies` package with its embed-frameworks phase
- [ ] B8 — replace `HeadsetPickerView` with the disconnect-all-but-one message

**Phase 4 — Interface and onboarding.** Rev 3 B6, B13, B14. **Current work.**

Promoted while phase 3 waits. All of it survives the team redesign, because none
of it is about teams — so aim the effort at the Headset and Settings screens
first and leave the Teams tab until its replacement is known.

- [ ] B14 — accessibility: contrast and VoiceOver labels on the icon-only
      controls (Dynamic Type is done)
- [ ] B13 — first-launch explanation of how the headset connects, then the route
      to the system Bluetooth screen
- [ ] B6 — model-specific naming and imagery for the headset in hand. No
      speculative support for models we cannot test

**Phase 5 — Testing bar.** Rev 3 C1 through C4. **Done.**

Promoted ahead of phase 4 on August 25, 2026. With the team system's
replacement undecided, test infrastructure is the work that cannot be wasted —
it is needed whatever the new system turns out to be, and it makes the eventual
deletion safe to attempt.

- [x] C1 — code coverage on in both schemes, scoped to the app target.
      **Baseline 15.20% (2152/14156 lines) across 44 files**, measured at
      `294a783`. Read that number with the deletion in mind: `TeamsDetailsView`
      alone is 3,356 uncovered lines, so a large part of the gap is code rev 3
      removes
- [x] C4 — `scripts/test.sh` builds, tests, measures coverage, and writes
      `build/test-results/results.md` with the verdict, counts, coverage, and a
      least-covered-file list. Exits non-zero on failure, so CI can use it
      unchanged
- [x] C2 — an integration suite driving the sync layer across the transport
      seam through multi-step sequences, one per hardware behavior that cost a
      bench session to establish: the zone defect, the LTC mode `0x04` latch,
      `confirmed` versus `settings` during a pending write, a drop and
      reconnect, a preset join reconciling from the headset, two writes
      resolving independently, reply attribution, and the lull ending on its
      own. 149 tests across 20 suites
- [x] C3 — UI tests for launch, navigation, and the pairing walkthrough, plus
      regressions for the two field-reported bugs. **Coverage 15.22% to
      31.83%.** Teams flows deliberately skipped until their replacement is
      known

### Waiting on documents

**Phase 6 — Security keys.** Rev 3 B1 through B5. Not blocked on an answer;
blocked on documentation that does not exist yet.

The BLE command document defines one security key at `0x01` and marks `0x02`
"not implemented at this time". Rev 3's passphrase-derived AES-256 keys need a
derivation shared with Android, and Android has not built one. Start when either
arrives.

- [ ] B1 — per-team security keys, five settings rather than one
- [ ] B2 — passphrase-derived AES-256 keys, matching Android exactly
- [ ] B3 — share all five team keys by QR
- [ ] B4 — load keys from QR and apply them to the headset on scan
- [ ] B5 — clear team security key settings

**Phase 7 — Store readiness.** Rev 3 B11, B12, and the App Store requirements.

- [ ] B11 — demo mode, full interface without a headset, behind a secret menu
- [ ] B12 — log export, encoded so the end user cannot read it
- [ ] Verify the privacy policy and contact details meet App Store requirements

---

## Effect on current work

- `docs/ble-protocol.md` §8 is closed: Gentex confirmed a firmware defect on
  August 25, 2026.
- `docs/decisions.md` records rev 3 as authoritative over rev 2.
- The question to Gentex of how many zones there are, and which bytes, is still
  open.
- Nothing in the plan requires reversing the optimistic-write work, the tutorial
  fix, or the font fix. Those stand regardless of how the draft settles.
