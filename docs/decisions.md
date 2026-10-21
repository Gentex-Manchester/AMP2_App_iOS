# Decisions & Authoritative Sources

Record of the confirmed product/technical decisions that constrain this feature.

## Authoritative sources

- **Authoritative:** the Custom Teams UI/UX deck (`260622 Custom Teams UIUX.pptx`)
  and product emails from Peter (RF channel/region behavior, device-local binding,
  QR cross-platform sharing) and David (embedded-key QR encryption).
- **Byte-level crypto source of truth:** Android `util/Crypto.kt`
  — the Android `Crypto` object that `QRCodeCrypto` reproduces.
- **Current SRD:** `SRD1005074_rev3_DRAFT.odt` (August 24, 2026), in
  [`docs/Gentex/08242026 SRD rev3/`](Gentex/). **Authoritative.** The file is
  marked draft and its revision table carries no release date, but Gentex
  confirmed on August 24, 2026 that it is the latest document and the source of
  truth. Where it conflicts with the deck, the emails, or the BLE command
  document, rev 3 wins until a newer document arrives. See
  [`requirements/srd-rev3-gap-analysis.md`](../requirements/srd-rev3-gap-analysis.md).
- **Superseded / historical:** `SRD1005074_rev2.docx`, superseded by rev 3. No
  copy was ever stored in this repo. Where it conflicted with the deck or emails,
  the deck and emails won.

Rev 3 removes the custom team system the deck specifies, so the two disagree on
the core feature rather than on details. Rev 3 wins: the deck is superseded on
custom teams.

Three further decisions taken with rev 3 (August 24, 2026):

- **Android is the source of truth for iOS.** Where a requirement needs a shared
  answer that Android has not solved yet — passphrase-derived AES-256 keys being
  the live example — iOS waits rather than inventing one. Two implementations
  guessing separately cannot interoperate.
- **Per-team security keys wait for documentation.** Rev 3 asks for five keys,
  the BLE command document defines one at `0x01` and marks `0x02` "not
  implemented at this time". Treat that as still true.
- **Removing the custom team system is on hold.** Rev 3 removes it, and Gentex
  confirmed why on August 25, 2026: customers and Gentex management found it too
  complex and short of the functional requirements. But the replacement is
  simpler *and* needs headset firmware that is a couple of weeks out, and the
  schedule is still being costed with our managers. Deleting ~3,700 lines before
  we know what replaces them risks throwing away foundations the new system
  builds on. The code stays until the replacement is specified.
- **Develop against the headset in hand.** Model-specific behavior is built for
  the unit we have, not speculatively for models we cannot test.

## Confirmed decisions

| Decision | Status | Notes |
|---|---|---|
| SQLite access layer | **Confirmed** | `SQLite.swift` with the `SQLCipher` trait (via local wrapper package). Raw SQLCipher C API and other wrappers are prohibited |
| Encryption at rest | **Confirmed** | Community (open-source) SQLCipher |
| FIPS 140-3 | **DROPPED** | Removed for budget. Community SQLCipher is used instead; FIPS is not a goal |
| Flagship gating | **DROPPED (Aug 2026)** | Gentex withdrew it. Custom teams work on every AMP 2.0 headset; the part number is read only to detect region locking |
| Network ID range | **Revised Aug 2026** | 0–255 inclusive. Was 1–256, which rejected valid Android teams with ID 0 and accepted 256, a value that cannot fit the headset's one-byte payload (LTC setting `0x04`). Now matches Android and the hardware |
| Region model | **Changed** | North America, Latin America, Eurasia. All regions support **channels 1–5 only**; 6–11 are unsupported by the app (Peter product email). Supersedes the earlier "6–11 Eurasia-exclusive, disabled (not remapped) in NA/LA" rule |
| Device binding | **Confirmed** | Encrypted DB stays on one physical device; no whole-DB import/export |
| QR sharing | **Revised** | Single team only, between iOS devices, embedded-key AES-GCM. iOS ↔ Android sharing was later dropped as a requirement; Android uses a different payload format |
| QR threat model | **Confirmed** | Embedded/obfuscated key = deterrence only, not anti-reverse-engineering |
| `customSecurityKey` | **Reserved only** | Nullable schema field; omitted from UI and generated QR payloads; not generated or required |
| Passphrase-derived AES-256 custom keys | **DEFERRED** | Android does not implement them yet; not part of the current shared contract |
| Bluetooth / headset integration | **Implemented (BLE GATT)** | Verified on hardware August 2026. See [ble-protocol.md](ble-protocol.md) |

## Rationale notes

- **Why the local wrapper package:** Xcode's UI cannot select Swift package
  traits, and SQLCipher support is trait-gated. The wrapper package enables
  `traits: ["SQLCipher"]` in its manifest and re-exports `SQLite`. See
  [encryption-architecture.md](encryption-architecture.md).
- **Why the QR key is embedded/shared, not per-device:** decoding a team offline
  on another device requires a shared key. Per-device keys would break sharing. The
  accepted limitation is documented in [threat-model.md](threat-model.md).
- **Why `customSecurityKey` is reserved but unused:** keeping the column and QR
  versioning ready avoids a breaking migration later, while not shipping
  unfinished UI or Android-incompatible derivation logic now.
- **Why the brand palette is a token file, not `Color.red`:** `Color.red` is the
  *system* red — roughly #FF3B30, and Apple has shifted it between OS releases.
  Ops-Core red is #E31B23, a fixed brand value Android already holds in
  `ui/graphics/color/Color.kt`. Gentex reported the mismatch on September 3,
  2026. `Color+Gentex.swift` is now the single definition on the iOS side and
  `BrandColourTests` asserts the exact bytes.
- **Why IBM Plex Sans weights are named the way they are:** the raw values in
  `IBMPlexSansWeight` are PostScript names read out of the `.ttf` name tables,
  not filenames. IBM abbreviates four of the eight — Regular is plain
  `IBMPlexSans`, and Medium/SemiBold/ExtraLight are `-Medm` / `-SmBld` /
  `-ExtLt`. The obvious guesses (`-Regular`, `-Medium`, …) resolve to nothing,
  and `Font.custom` answers that with a silent fallback to the system font
  rather than an error. That is what Gentex saw as "a large portion of the text
  uses the system default font": `.regular` is the default weight, so most of
  the app was rendering in SF Pro. `TypographyTests` now fails if any weight
  stops resolving.
- **Why text sizes scale with Dynamic Type:** `Font.custom(_:size:)` is a fixed
  point size and ignores the reader's text-size setting entirely, while
  Android's `sp` units scale with it. On any device with text turned up, Android
  grew and iOS did not — the "iOS text is noticeably smaller" report. The
  helpers now pass `relativeTo:`, which is a no-op at the default text size and
  tracks the reader above it. Base sizes follow Android's scale in
  `ui/theme/Type.kt` (18 body, matching its `bodyLarge` override).
  The no-headset screen (`DisconnectedView`) runs a step larger (22 headline,
  20 body) at Gentex's request, September 2026, and sits its content in the
  upper part of the space above the button instead of pinned to the top.
