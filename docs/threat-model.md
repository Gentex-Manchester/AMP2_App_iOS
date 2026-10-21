# Threat Model

Scope: the two encryption mechanisms in this feature and their accepted limits.
See [encryption-architecture.md](encryption-architecture.md) for mechanics.

## Database-at-rest (SQLCipher) — strong, device-bound

- The team database is encrypted with SQLCipher (AES-256).
- The key is randomly generated on-device and stored in the iOS Keychain with
  `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`: device-local, not synced to
  iCloud, not in backups, only readable while the device is unlocked.
- The key never leaves the device and is never placed in a QR code.
- **Result:** the encrypted database is bound to a single physical device and is
  strongly protected at rest. This is the intended, robust protection boundary.

## QR transport (embedded key) — deterrence only (ACCEPTED LIMITATION)

The QR payload is encrypted with a **fixed AES-256 key embedded in the app
binary** and only **XOR-obfuscated**. The Android app embeds the same key.

> **Accepted limitation:** Generic camera apps, QR-scanner apps, and automated
> scrapers cannot read the payload — they see only opaque Base64 ciphertext. But
> a **motivated reverse-engineer** with a decompiler can extract the embedded key
> and the XOR mask from either the iOS or Android binary and then decrypt (or
> forge) any QR payload. The obfuscation raises the effort bar; it does not
> provide cryptographic secrecy against a determined actor.

This trade-off is **deliberate and agreed by the team** for the current phase:

- The requirement is sharing a single team via QR between devices, without
  accounts, a KMS, or server round-trips.
- A shared, fixed key is the only way another device can decode a shared team
  offline. Any per-user/per-device key would break sharing.
- The data shared (team name, region, RF channel, security key, network ID) is
  low-sensitivity operational configuration, not credentials or PII.

### What is deferred (future phase)

- **Stronger, user-managed or remotely-managed QR keys** (e.g. passphrase-derived
  keys, account/KMS-issued keys). The QR contract's `version` field and the room
  left for an optional `customSecurityKey` field make this a versioned, additive
  upgrade later — see [qr-contract.md](qr-contract.md) and
  [future-phases.md](future-phases.md).
- **Passphrase-derived AES-256 custom keys** are explicitly out of scope now:
  Android does not implement them yet, and the current Android `Crypto` object
  covers only QR transport encryption.

### Source guardrail

`QRCodeCrypto.swift` carries a `// MARK: - Threat Model` comment restating this
limitation at the point of implementation, so the constraint is visible to anyone
editing the crypto code.

## Summary

| Boundary | Strength | Key location | Leaves device? |
|---|---|---|---|
| Local team DB | Strong (SQLCipher, device-bound) | Keychain (random, per-device) | No |
| QR payload | Deterrence only (embedded, obfuscated) | App binary (fixed, shared) | Yes, inside the QR |
