**This README and other documentation is currently out-of-date and will not be updated until later stages of development.**

# Gentex AMP 2.0 — iOS Companion App

A companion app for the Gentex AMP 2.0 tactical headset. This app lets users
configure and manage **RF teams** — groups of headsets that communicate on the
same radio frequency — for military and tactical operations. Custom teams are
stored in an **encrypted local database**, can be **shared peer-to-peer via QR
codes** between iOS devices, and are applied to the headset
over Bluetooth. Built for iOS 18.0+ with SwiftUI.

---

## Architecture at a Glance

- **iOS SwiftUI app** — Pure SwiftUI with no ViewModels, except the Bluetooth
  layer, which uses two `@Observable` objects injected through `@Environment`.
  Uses `NavigationStack` for navigation, `@State` for local state, and
  `@AppStorage` for persisted preferences (theme, orientation). The root view
  picks a portrait or landscape layout from the orientation setting and the
  window's shape.
- **Encrypted local database** — Custom teams are persisted in a SQLCipher
  (AES-256-encrypted SQLite) database, accessed through SQLite.swift. The
  encryption key is generated on first launch and stored in the iOS Keychain —
  it never leaves the device.
- **QR team sharing** — A single custom team can be exported as a QR code and
  imported on another iOS device. The QR payload is encrypted with an
  app-embedded AES-256 key. The Android app uses a different QR payload format, so QR codes do not
  transfer between iOS and Android. Cross-platform sharing is not a requirement.
- **Bluetooth headset** — The app connects to the headset over BLE GATT, reads
  and writes every documented setting, detects which team is active, and applies
  custom teams. Changes appear immediately and roll back if the headset refuses
  them. Pairing itself happens in the iOS Settings app, because iOS gives apps no
  way to open the system Bluetooth pairing screen. See
  [`docs/ble-protocol.md`](docs/ble-protocol.md).

```
Gentex_iOSApp (@main)
├── AppDelegate
└── ContentView
    ├── Content area (Headset, Teams, Settings)
    └── Custom tab bar overlay: bottom in portrait, sidebar in landscape
```

For detailed technical documentation, see [`docs/README.md`](docs/README.md)
(encryption architecture, database schema, QR contract, region rules, threat
model, and design decisions).

---

## Getting Started for Developers

### Prerequisites

- **Xcode 26.5+** (Swift 5 language mode)
- **iOS 18.0+ simulator** or device. The simulator has no Bluetooth radio, so
  the Headset tab only connects on a physical iPhone.
- **Internet access on the first build.** Xcode fetches
  [SQLite.swift](https://github.com/stephencelis/SQLite.swift) (with its
  SQLCipher trait) from GitHub through Swift Package Manager. Versions are
  pinned in `Package.resolved`.
- **IBM Plex Sans font** — included in the repository under `Gentex_iOS/Fonts/`
  and registered in `Info.plist`. No manual font installation needed.

### Quick Start

```bash
open Gentex_iOS.xcodeproj
```

### Running on a Device

Simulator builds need no signing. To install on an iPhone, select the
`Gentex_iOS` target, open **Signing & Capabilities**, and choose your own
development team. If Xcode reports that the bundle identifier
`eotak.Gentex-iOS` is unavailable, change it to one your team owns.

The app does not pair with the headset itself. Before launching it, open
**Settings > Bluetooth** on the iPhone and connect the headset there: it must
show as **Connected**, not only paired. See
[`docs/ble-protocol.md`](docs/ble-protocol.md) §1 and §10 for why.

### Build Schemes

The project has two build schemes:

| Scheme | Configuration | Use |
|---|---|---|
| `Gentex_iOS` | `Debug` | Standard build for testing and CI. |
| `Gentex_iOS (Dev)` | `Debug-Dev` | Development build, defining the `DEV_NO_GATE` compilation condition. That flag no longer gates anything — it bypassed the former Flagship-headset check, which Gentex removed — so it builds the same app as `Gentex_iOS`. Its test action runs unit tests only. |

### Build & Test from the Command Line

```bash
# Build the standard scheme
xcodebuild -project Gentex_iOS.xcodeproj -scheme Gentex_iOS \
  -destination 'platform=iOS Simulator,name=iPhone 17' build

# Build with the Dev scheme
xcodebuild -project Gentex_iOS.xcodeproj -scheme 'Gentex_iOS (Dev)' \
  -destination 'platform=iOS Simulator,name=iPhone 17' build

# Run all unit and UI tests (./scripts/test.sh also writes a coverage report)
xcodebuild -project Gentex_iOS.xcodeproj -scheme Gentex_iOS \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

No secrets, API keys, or cloud credentials are needed — all data is
device-local.

---

## How to Contribute / Work on This Repo

### Finding Work

- Read the roadmap in [`requirements/README.md`](requirements/README.md) for
  the big-picture plan.

### Branching & Commits

- Branch from `main` with a `feat/<name>` naming convention, e.g.,
  `feat/add-bluetooth-sync`.
- **Commits are managed manually** — make meaningful, focused commits with
  clear messages. There is no auto-commit workflow.
- If you need an isolated workspace, consider using `git worktree` to work on
  a feature branch without affecting the main working directory.

### Pull Requests

Before opening a PR:
1. Build succeeds with no errors
2. All existing tests pass
3. No new compiler warnings
4. Relevant documentation updated (in `docs/`)

### Coding Conventions (Quick Reference)

- **Subviews**: computed `private var fooView: some View` properties — never
  `@ViewBuilder func`.
- **Imports**: Use `import AppDependencies` for database code (which re-exports
  SQLite.swift). Never `import SQLite` directly, and never `import SwiftData`.
- **Font**: Always use `.font(.ibmPlexSans(size:weight:))` — no system fonts.
- **Documentation**: Every view needs `#Preview`. Use `// MARK: -` comments to
  group sections.
- **Testing**: Unit tests use Swift Testing (`import Testing`); UI tests use
  XCTest. Database tests
  use `TeamStore(connection:)` with an in-memory `Connection(.inMemory)`.

For the full conventions, see [`CONTRIBUTING.md`](CONTRIBUTING.md).

---

## Project Status and Roadmap

### ✅ Completed: Encrypted Teams Database & QR Sharing

- SQLCipher-based encrypted local database for custom RF teams
- Full CRUD (Create, Read, Update, Delete), favorite toggle, duplicate detection
- Region-aware RF channel availability (North America, Latin America, Eurasia)
- QR export/import between iOS devices (AES-256-GCM)
- Unit tests (Swift Testing) and UI tests (XCTest), all passing; `./scripts/test.sh` reports current counts and coverage
- Complete technical documentation in [`docs/`](docs/README.md)

All six PRD tasks (Task-001 through Task-006) are complete and have passed
review. The PRD and per-task progress log were retired once the phase closed;
the requirements they described now live in
[`requirements/README.md`](requirements/README.md) and
[`docs/`](docs/README.md).

### 🔄 In Progress

- **SRD rev 3, phase 4: interface and onboarding.** See
  [`requirements/srd-rev3-gap-analysis.md`](requirements/srd-rev3-gap-analysis.md).

### 📋 Up Next

- **Polish** — additional UI refinement, edge-case hardening, performance
  optimization.

See the [roadmap in `requirements/README.md`](requirements/README.md) for the
detailed plan across all milestones.

---

## Key Files

| File | What it is |
|---|---|
| [`docs/README.md`](docs/README.md) | Technical documentation index (encryption, schema, QR contract, etc.) |
| [`requirements/README.md`](requirements/README.md) | Functional requirements, non-functional reqs, and roadmap |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | How to contribute: branching, PRs, conventions |
| [`docs/Gentex/`](docs/Gentex/) | Gentex's SRD rev 3 draft (August 24, 2026) |

---

## Related Repositories

- **Gentex Android** — Android companion app with the same encrypted database.
  Its QR payload format differs from the iOS one, so QR codes do not transfer
  between the two apps.
