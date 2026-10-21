# Gentex AMP 2.0 (iOS) — Requirements

This document describes what the Gentex AMP 2.0 iOS app is supposed to do, which
features are built today, what is planned for later, and the non-functional
constraints (performance, reliability, security, platform) the system must
satisfy. It is written for engineers who know iOS but are new to this project.

> **Requirements are changing.** SRD1005074 **rev 3** arrived on August 24, 2026
> and removes the custom team system this document specifies. It is still a
> draft. Read [srd-rev3-gap-analysis.md](srd-rev3-gap-analysis.md) before
> treating anything below as current, and see
> [srd-rev3-questions.md](srd-rev3-questions.md) for what Gentex still has to
> answer.

> **Other key docs:** [Project overview](../README.md) ·
> [Technical documentation index](../docs/README.md) ·
> [How to contribute](../CONTRIBUTING.md)

---

## Goals

The Gentex AMP 2.0 app is a companion for a tactical headset worn by first
responders and military personnel. Its job is to let users configure,
store, and share teams — groups of radios that talk to each other on a specific
RF channel, network ID, and security key.

### Custom Teams (persistent, encrypted)
- Users can create, edit, rename, and delete **custom RF teams** —
  configurations that pair a region, RF channel, network ID, and security key.
- Custom teams are stored in an **encrypted local database** on the device so
  they survive app restarts and are not readable if the device is lost.
- **Who it's for:** any user who needs teams beyond the headset's built-in
  presets. Custom teams are available on every AMP 2.0 headset — an earlier
  plan restricted them to the Flagship variant, but Gentex removed that
  requirement.

### Region Rules
- All three regions (North America, Latin America, Eurasia) support the **same
  five RF channels (1–5)**. Channels 6–11 are **not supported by the app** in
  any region.
- Custom teams **transfer freely across regions** with no channel restrictions —
  a team's settings and availability never change with the region.
- **Who it's for:** users who travel or operate across region boundaries. The
  uniform channel set removes the complexity of region-gated channels while
  keeping the headset's region zones intact.

### QR Sharing
- Any single custom team can be **exported as a QR code** and shared to another
  iOS device. The full database is never shared — only one team at a time.
- The QR payload is **encrypted** so generic camera apps cannot read the team
  settings.
- The Android app uses a different QR payload format, so QR codes do not
  transfer between iOS and Android. Cross-platform sharing is not a requirement.
- **Who it's for:** anyone who wants to give a team configuration to another
  user quickly, without manual data entry. The expected outcome is a shared team
  that the recipient imports and saves in a few taps.

### Bluetooth Headset
- The app **connects to the headset over Bluetooth**, detects which team is
  currently active, and applies custom teams directly to the headset's radio.
- **Who it's for:** users who need to switch the headset's active RF team from
  the phone, or see which team the headset is currently using.
- Settings changes appear **immediately** and roll back if the headset refuses
  them, because the headset acknowledges some changes it then fails to apply.
- **Pairing happens in the iOS Settings app.** iOS gives apps no way to open the
  system Bluetooth pairing screen, and AccessorySetupKit cannot discover this
  headset. The in-app tutorial explains the Settings route instead.
- **Status (August 2026):** working. Zone (`0x0a`) cannot be written: Gentex
  confirmed on August 25, 2026, that this is a headset firmware defect, so no
  app work is planned. See [../docs/ble-protocol.md](../docs/ble-protocol.md) §8.

---

## Key Features

### Current Features (implemented)

- **Encrypted local database (SQLCipher)** — all custom teams are stored in a
  SQLite database encrypted at rest with AES-256. The encryption key is randomly
  generated on first launch and stored in the iOS Keychain (device-local, never
  synced to iCloud, never included in backups).
- **Full CRUD operations** — create, read, update, delete, and favorite/unfavorite
  custom teams through the SwiftUI interface. Duplicate teams (same settings) are
  prevented at the persistence layer.
- **Region-aware validation** — all three regions support RF channels 1–5;
  channels 6–11 are unsupported by the app. Teams transfer freely across
  regions. Network IDs are validated against the 0–255 range (one byte, as the
  headset requires).
- **QR export and import** — a single team can be exported as a QR code or
  imported from one. Imported teams are validated before saving. Duplicate or
  conflicting imports are handled deterministically (existing behavior: rejected).
- **Versioned QR payload** — AES-256-GCM with an embedded XOR-obfuscated key,
  encoded as URL-safe Base64. Payloads are versioned so future upgrades are
  backward-compatible.
- **Bluetooth headset** — connects over BLE GATT, reads and writes every
  documented setting, detects the active team by matching the headset's live
  settings, and joins preset or custom teams. The region selector is hidden on
  region-locked headsets.
- **No headset-variant gating** — custom teams work on every AMP 2.0 headset.
  The feature was originally specified as Flagship-only, enforced by a
  placeholder gate with a `DEV_NO_GATE` compile-time bypass; Gentex dropped the
  restriction and the gate has been removed.

### Planned Features (future)

These are documented in [`docs/future-phases.md`](../docs/future-phases.md) and
the schema is already compatible, but they are **not implemented yet**.

- **LTC override** — override the headset's built-in "loaded team channel" (LTC)
  presets with custom teams. Exact behavior is not yet defined.
- **`customSecurityKey` authoring** — a reserved, nullable schema column for a
  future passphrase-derived AES-256 custom key. No UI, generation, or QR-payload
  inclusion exists today. When Android implements it and the product team
  approves, iOS will add the authoring flow.

---

## Non-Functional Requirements

### Performance

- **Local-only operations.** All database reads and writes happen on-device —
  no network calls, no server round-trips. This means CRUD operations are
  bounded by device speed only.
- **Sub-second CRUD.** Creating, reading, updating, deleting, or favoriting a
  team must feel instant to the user (under one second on any supported device).
  The database is a single-user local file, so there is no contention.
- **Why this matters:** the app is used in the field, often in time-sensitive
  situations. Waiting for a save or load is not acceptable.

### Reliability

- **No data loss on crash.** All writes to the encrypted database use SQLite's
  atomic transaction mechanism. If the app crashes mid-write, the database
  remains in its last consistent state — partial or corrupt writes are not
  possible.
- **Key loss resets the database.** If the database encryption key is missing
  from the Keychain (for example, after a restore from an unencrypted backup),
  the app cannot decrypt the existing database. It deletes the database,
  generates a new key, and starts with no custom teams.
- **Why this matters:** losing team configurations in the field could mean a
  team is unable to communicate. The system must be predictable even under
  failure conditions.

### Security

- **Database at rest is encrypted.** The local team database uses SQLCipher
  (community edition, AES-256). An attacker who gains physical access to the
  device cannot read team data without the device being unlocked.
- **Encryption key is device-bound.** The SQLCipher key is generated on-device
  (48 cryptographically random bytes, Base64-encoded with `+`, `/`, and `=`
  removed) and stored in the iOS
  Keychain with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`. It is never
  synced to iCloud, never included in backups, never exported, and never placed
  in a QR code.
- **No cloud sync.** Custom teams exist only on the device that created them.
  There are no accounts, no server, and no remote storage. The only way a team
  moves between devices is QR sharing.
- **QR transport is deterrence-level.** The QR payload is encrypted with a fixed
  key embedded in the app binary and XOR-obfuscated. This stops casual scanning
  but does not protect against a determined reverse-engineer (see the
  [threat model](../docs/threat-model.md) for the full rationale). This is an
  accepted trade-off for offline sharing without a KMS.
- **Why this matters:** team configurations contain operational parameters
  (channel, network ID) that should not be casually readable. The design
  balances protection with the requirement that teams can be shared offline
  between devices without accounts or servers.

### Platform

- **iOS 18.0+.** The app supports the three most recent major iOS versions. iOS
  26 succeeded iOS 18 directly — Apple switched to year-based numbering in 2025,
  so 19 through 25 do not exist — which puts the floor at 18.0. iOS 18 supports
  the same devices iOS 17 did (iPhone XR/XS and later), so this excludes no
  hardware, only users who declined an update.
- **Swift 5 language mode / Xcode 26.5.** Built with the current Xcode toolchain. The
  project uses `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` — all view code runs
  on the main actor by default.
- **No SwiftData.** The project uses SQLCipher via SQLite.swift for persistence.
  `import SwiftData` is never used.
- **Why this matters:** the iOS 18.0 floor ensures we use modern SwiftUI without legacy workarounds.

---

## Roadmap

### Near-term (current phase)

- **SRD rev 3, phase 4: interface and onboarding** — the current work. See
  [srd-rev3-gap-analysis.md](srd-rev3-gap-analysis.md).
- **SRD rev 3, phase 3: remove the custom team system** — on hold since August
  25, 2026.

### Medium-term (when blockers clear)

- **Custom security keys** — when Android implements passphrase-derived AES-256
  keys and the product team approves, add the `customSecurityKey` authoring flow
  to the create/edit UI and include it in QR payloads. The schema column and QR
  versioning already support this.

No dates are set. Android must implement custom keys before iOS builds the UI.

---

## See Also

- [`docs/README.md`](../docs/README.md) — technical documentation index covering
  the encryption architecture, database schema, region rules, QR contract, and
  threat model.
- [`CONTRIBUTING.md`](../CONTRIBUTING.md) — how to pick up issues, branch
  conventions, coding standards, and PR expectations.
