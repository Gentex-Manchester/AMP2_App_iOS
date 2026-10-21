# Contributing to Gentex AMP 2.0 (iOS)

Welcome! This document explains how to contribute to the Gentex AMP 2.0 iOS headset companion app. It's scoped to this project's specific conventions — please read it before picking up work.

---

## Finding Work

- **Roadmap & requirements** — see [`requirements/README.md`](requirements/README.md) for the big-picture plan and feature requirements.

### Labels

Look for the **`good first issue`** label — those are specifically curated for newcomers or contributors who want a small, well-scoped task to start with.

---

## Branching Model

1. Branch off `main`: `git checkout -b feat/<short-description>`.
2. **Commits are managed manually** — no auto-commit tooling. Write clear, conventional commit messages (`feat:`, `fix:`, `docs:`, etc.).
3. If you need an isolated workspace that doesn't disturb your current branch, use `git worktree`.

---

## Coding Conventions

Key rules:

| Convention | Rule |
|---|---|
| **Subviews** | `private var fooView: some View` computed property — never `@ViewBuilder func` |
| **MARK comments** | Use `// MARK: - SectionName` to group Properties, Init, Body, Subviews, etc. |
| **Imports** | `import SwiftUI` in views; for database code use `import Foundation` + `import AppDependencies` (re-exports `SQLite`). Never `import SQLite` directly. |
| **Font** | `.font(.ibmPlexSans(size:weight:))` — never system fonts. |
| **Previews** | Every view must have a `#Preview`. |
| **Error handling** | `throws`-based with custom `LocalizedError` enums providing `errorDescription` + `recoverySuggestion`. |
| **Singletons** | `DatabaseManager.shared` and `TeamStore.shared` for production, but `TeamStore` exposes `init(connection:)` for test injection. |
| **Layout** | `.frame(maxWidth: .infinity, alignment: .leading)` + manual padding. Primary accent is `Color.opsCoreRed` (#E31B23), never `Color.red`. Every rectangle uses `.cornerRadius(16)`. |
| **Orientation** | `ContentView` picks portrait or landscape from the `OrientationMode` setting and the window's shape; some subviews also read `verticalSizeClass`. |

---

## Testing Expectations

- **Framework**: Unit tests use Swift Testing (`import Testing`): `@Suite`, `@Test`, `#expect`, `#expect(throws:)`. UI tests use XCTest.
- **Existing suite**: `Gentex_iOSTests/Gentex_iOSTests.swift` (unit) and `Gentex_iOSUITests/` (UI) — these must stay green. `./scripts/test.sh` runs both.
- **New features**: Must include tests. Database tests use `TeamStore(connection:)` with an in-memory `Connection(.inMemory)` for isolated state — no database file or setUp/tearDown needed.
- **Access**: Use `@testable import Gentex_iOS` for internal symbols; use the `sampleTeam()` helper fixture.
- **Run tests**: `xcodebuild -project Gentex_iOS.xcodeproj -scheme Gentex_iOS -destination 'platform=iOS Simulator,name=iPhone 17' test`

---

## Pull Request Expectations

Before opening a PR, verify:

1. **Build succeeds** — no compilation errors.
2. **All tests pass** — the full suite (existing + new) must be green.
3. **No new warnings** — treat warnings as errors.
4. **Relevant docs updated** — if you changed behavior, update the corresponding docs in `docs/`.

### Code Review

- **Requesting review**: Give the reviewer the issue, the diff, and what you tested before merging.
- **Receiving review**: Verify feedback against the codebase before implementing; technical correctness over performative agreement.

---

## Dev Scheme (`Gentex_iOS (Dev)`)

The project includes a **`Gentex_iOS (Dev)`** scheme that uses the **`Debug-Dev`** build configuration, which defines the **`DEV_NO_GATE`** compiler flag. That flag originally bypassed a Flagship-headset gate on custom teams; Gentex removed that requirement and the gate is gone, so the flag gates nothing and the scheme builds the same app as `Gentex_iOS`. Its test action runs unit tests only.

- Use the **`Gentex_iOS`** scheme for builds, CI, and the full test suite.

---

## Questions?

Check the technical docs in [`docs/README.md`](docs/README.md) for architecture, schema, QR contract, and threat-model details.
