# AMP 2.0 Companion App for iOS

A companion app for the Gentex AMP 2.0 tactical headset. This app lets users
configure and manage **teams** — groups of headsets that communicate on the
same radio frequency — for military and tactical operations. Changes are 
applied to the headset over Bluetooth. Built for iOS 18.0+ with SwiftUI.

---

## Architecture at a Glance

- **iOS SwiftUI app** — Pure SwiftUI with no ViewModels, except the Bluetooth
  layer, which uses two `@Observable` objects injected through `@Environment`.
  Uses `NavigationStack` for navigation, `@State` for local state, and
  `@AppStorage` for persisted preferences (theme, orientation). The root view
  picks a portrait or landscape layout from the orientation setting and the
  window's shape.
- **Bluetooth headset** — The app connects to the headset over BLE GATT and reads
  and writes every documented setting. Changes appear immediately and roll back
  if the headset refuses them. Pairing itself happens in the iOS Settings app,
  because iOS gives apps no way to open the system Bluetooth pairing screen. See
  [`ble-protocol.md`](ble-protocol.md).

---

## Getting Started for Developers

### Prerequisites

- **Xcode 26.5+** (Swift 5 language mode)
- **iOS 18.0+ simulator** or device. The simulator has no Bluetooth radio, so
  the Headset tab only connects on a physical iPhone.

### Quick Start

```bash
open Gentex_iOS.xcodeproj
```

### Running on a Device

Simulator builds need no signing. To install on an iPhone, select the
`AMP2_App_iOS` target, open **Signing & Capabilities**, and choose your own
development team. If Xcode reports that the bundle identifier
is unavailable, change it to one your team owns.

The app does not pair with the headset itself. Before launching it, open
**Settings > Bluetooth** on the iPhone and connect the headset there: it must
show as **Connected**, not only paired.

---

## How to Contribute / Work on This Repo

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

- **Font**: Always use `.font(.ibmPlexSans(size:weight:))` — no system fonts.
- **Documentation**: Every view needs `#Preview`. Use `// MARK: -` comments to
  group sections.
- **Testing**: Unit tests use Swift Testing (`import Testing`); UI tests use
  XCTest.

For the full conventions, see [`CONTRIBUTING.md`](CONTRIBUTING.md).

---

## Related Repositories

- **AMP 2.0 App for Android** — Android companion app with a similar feature set.
  The Android app includes some features not available on iOS, like USB connectivity.
