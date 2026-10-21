# Gentex AMP 2.0 (iOS) — Technical Documentation

> **Looking for a project overview?** See the root [README.md](../README.md) for
> architecture, setup, and onboarding. This folder contains the technical deep
> dives for the encrypted custom-teams feature.

## Encrypted Custom Teams & QR Sharing

This folder is the standalone, authoritative documentation for the encrypted
custom-teams feature: a device-local encrypted database of custom RF teams, plus
single-team sharing via QR codes between iOS devices.

If you only read one thing, read this file, then jump to the topic you need.

## What this feature does

- Stores **custom teams** in an **encrypted local SQLite database** (SQLCipher,
  community edition) accessed through **SQLite.swift** with the `SQLCipher`
  package trait enabled.
- Encryption key is **generated on first launch** and stored in the **iOS
  Keychain** (`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`) — device-local,
  never synced, never exported.
- Replaces the previously hardcoded Teams UI with **real CRUD** (create, read,
  update, delete, favorite, duplicate-check) against the encrypted database.
- Enforces **region rules** (North America, Latin America, Eurasia) for RF
  channel availability.
- Shares a **single custom team** via a **QR code** whose payload is encrypted
  with an app-embedded, XOR-obfuscated AES-256 key (`AES/GCM/NoPadding`).
  QR codes do not transfer to or from the Android app, which uses a different
  payload format; cross-platform sharing is not a requirement.

## What this feature does NOT do (this phase)

- No Bluetooth code in the database or QR layers. Joining a custom team on the
  headset goes through `HeadsetSettingsSync.applyTeam` — see
  [ble-protocol.md](ble-protocol.md).
- No full-database import/export.
- No cloud sync, accounts, KMS, or user-managed QR keys.
- No FIPS 140-3 validated module (dropped for budget — see
  [decisions.md](decisions.md)).
- No `customSecurityKey` generation or UI (reserved, nullable schema field only).

## Two DIFFERENT encryption mechanisms (do not confuse them)

| | Database-at-rest | QR transport |
|---|---|---|
| Purpose | Protect the local team database on the device | Share one team to another device |
| Mechanism | SQLCipher (AES-256) via SQLite.swift `SQLCipher` trait | CryptoKit `AES.GCM` (`AES/GCM/NoPadding`) |
| Key | Random per-device key in iOS Keychain | Fixed app-embedded XOR-obfuscated key |
| Leaves device? | **Never** | Yes (inside the QR payload) |
| Threat model | Strong, device-bound | Deterrence only — see [threat-model.md](threat-model.md) |

See [encryption-architecture.md](encryption-architecture.md) for the full
explanation of why these are separate.

## Documentation index

| File | Contents |
|---|---|
| [encryption-architecture.md](encryption-architecture.md) | SQLCipher-at-rest via SQLite.swift trait + Keychain; embedded-key QR transport; why they differ; the local wrapper package; `PRAGMA cipher_version` verification gotcha |
| [database-schema.md](database-schema.md) | `teams` table columns/types, `_schema_metadata` version tracking, migration strategy |
| [region-rules.md](region-rules.md) | Region model, channel availability (1–5 in all regions; 6–11 unsupported), Network ID range |
| [qr-contract.md](qr-contract.md) | Versioned QR payload JSON contract, AES-GCM wrapper details, fixture vectors, Android format note |
| [threat-model.md](threat-model.md) | Accepted limitation of the embedded QR key; deferred stronger keys |
| [ble-protocol.md](ble-protocol.md) | The BLE wire format as implemented and verified on hardware: transport, discovery, commands, settings, timings, the resolved LTC-mode and closed zone hardware faults, and documentation errata |
| [future-phases.md](future-phases.md) | Open work: LTC override, headset-driven `is_locked`, `customSecurityKey`; dropped headset-variant gating |
| [decisions.md](decisions.md) | Authoritative sources, SRD revision history, dropped FIPS, confirmed rules |
| [../requirements/srd-rev3-gap-analysis.md](../requirements/srd-rev3-gap-analysis.md) | SRD rev 3 versus what is built: what it removes, what it adds, what iOS cannot do as written, and the plan |

## Source map (implementation)

| File | Role |
|---|---|
| `AppDependencies/Package.swift` | Local wrapper package enabling `traits: ["SQLCipher"]` and re-exporting `SQLite` |
| `Gentex_iOS/Database/DatabaseManager.swift` | DB lifecycle, key application, encryption verification, schema + migrations |
| `Gentex_iOS/Database/KeychainManager.swift` | Keychain wrapper for the device-local DB key |
| `Gentex_iOS/Database/TeamStore.swift` | CRUD persistence layer |
| `Gentex_iOS/Database/TeamSchema.swift` | Typed schema + DDL + version SQL |
| `Gentex_iOS/Database/TeamValidation.swift` | Stateless field validation |
| `Gentex_iOS/Database/QRCodeCrypto.swift` | AES-256-GCM encrypt/decrypt |
| `Gentex_iOS/Database/QRPayload.swift` | Versioned JSON payload contract |
| `Gentex_iOS/Database/DatabaseError.swift` | Error taxonomy |
| `Gentex_iOS/Database/Models/{Team,Region,SecurityKey}.swift` | Canonical models |
| `Gentex_iOS/Views/TeamsViews/*` | Teams list, create/edit, locked view, QR export/import |
| `Gentex_iOS/Bluetooth/*` | BLE transport (`HeadsetSession`), settings sync and team apply (`HeadsetSettingsSync`), LTC packet codec (see [ble-protocol.md](ble-protocol.md)) |

## Build & test

```bash
xcodebuild -project Gentex_iOS.xcodeproj -scheme Gentex_iOS \
  -destination 'platform=iOS Simulator,name=iPhone 17' build

xcodebuild -project Gentex_iOS.xcodeproj -scheme Gentex_iOS \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```
