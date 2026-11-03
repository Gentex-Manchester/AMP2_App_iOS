# Contributing to Gentex AMP 2.0 (iOS)

Welcome! This document explains how to contribute to the Gentex AMP 2.0 iOS headset companion app. It's scoped to this project's specific conventions — please read it before picking up work.

---

## Finding Work

- **Roadmap & requirements** — see [`requirements/README.md`](requirements/README.md) for the big-picture plan and feature requirements.

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
| **MARK comments** | Use `// MARK: - SectionName` to group Properties, Init, Body, Subviews, etc. |
| **Imports** | `import SwiftUI` in views; |
| **Font** | `.font(.ibmPlexSans(size:weight:))` — never system fonts. |
| **Previews** | Every view must have a `#Preview`. |
| **Error handling** | `throws`-based with custom `LocalizedError` enums providing `errorDescription` + `recoverySuggestion`. |
| **Singletons** | `DatabaseManager.shared` and `TeamStore.shared` for production, but `TeamStore` exposes `init(connection:)` for test injection. |
| **Layout** | `.frame(maxWidth: .infinity, alignment: .leading)` + manual padding. Primary accent is `Color.opsCoreRed` (#E31B23), never `Color.red`. Every rectangle uses `.cornerRadius(16)`. |
| **Orientation** | `ContentView` picks portrait or landscape from the `OrientationMode` setting and the window's shape; some subviews also read `verticalSizeClass`. |

---

## Testing Expectations

- **Framework**: Unit tests use Swift Testing (`import Testing`): `@Suite`, `@Test`, `#expect`, `#expect(throws:)`. UI tests use XCTest.
- **Existing suite**: `AMP2_App_iOSTests/Gentex_iOSTests.swift` (unit) and `AMP2_App_iOSUITests/` (UI) — these must stay green. `./scripts/test.sh` runs both.
- **New features**: Must include tests.
- **Access**: Use `@testable import AMP2_App_iOS` for internal symbols; use the `sampleTeam()` helper fixture.
- **Run tests**: `xcodebuild -project AMP2_App_iOS.xcodeproj -scheme AMP2_App_iOS -destination 'platform=iOS Simulator,name=iPhone 17' test`

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

## Questions?

Check the technical docs in [`docs/README.md`](docs/README.md) for architecture, schema, QR contract, and threat-model details.
