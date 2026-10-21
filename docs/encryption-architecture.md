# Encryption Architecture

This feature uses **two independent encryption mechanisms**. They protect
different things, use different keys, and must not be conflated.

1. **Database-at-rest** — SQLCipher (community edition) via **SQLite.swift** with
   the `SQLCipher` package trait. Protects the local team database file on the
   device. The key is device-local and never leaves the device.
2. **QR transport** — CryptoKit `AES.GCM` with an app-embedded, XOR-obfuscated
   key. Protects a single team payload while it travels inside a QR code to
   another device (iOS or Android).

> These are DIFFERENT mechanisms. The SQLCipher database key and database file
> **never** leave the device. The QR payload is encrypted with a completely
> separate, fixed, embedded key. Compromising one does not compromise the other.

---

## 1. Device-local SQLCipher-at-rest (via SQLite.swift + `SQLCipher` trait)

### Why a local wrapper package is required

SQLCipher support in SQLite.swift (0.16.0+) is gated behind a Swift Package
**trait** named `SQLCipher`. **Xcode's UI cannot select package traits.** The
documented workaround is a **local wrapper Swift package** that depends on
SQLite.swift with the trait enabled and re-exports `SQLite`.

`AppDependencies/Package.swift`:

```swift
// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "AppDependencies",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "AppDependencies", type: .dynamic, targets: ["AppDependencies"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/stephencelis/SQLite.swift.git",
            from: "0.16.0",
            traits: ["SQLCipher"]
        )
    ],
    targets: [
        .target(
            name: "AppDependencies",
            dependencies: [.product(name: "SQLite", package: "SQLite.swift")]
        )
    ]
)
```

`AppDependencies/Sources/AppDependencies/empty.swift`:

```swift
@_exported import SQLite
```

The app target depends on the local `AppDependencies` package instead of
SQLite.swift directly. Because the trait is enabled in the manifest (not the
Xcode UI), it is guaranteed active at build time. App source files simply
`import AppDependencies` and get the SQLCipher-enabled `SQLite` module.

> **pbxproj caution:** the local package integration is fragile. All of the
> package-reference objects (`XCLocalSwiftPackageReference`,
> `XCSwiftPackageProductDependency`, the per-target `PBXBuildFile`, and the
> Frameworks build-phase entries) must live **inside** the `objects = { ... }`
> dictionary. If placed after it, `plutil -lint` still passes but Xcode resolves
> zero packages and fails with `unable to resolve module dependency:
> 'AppDependencies'`. Verify with `plutil -convert json` after any edit.

### Key generation and storage (`KeychainManager`)

- On first launch, an alphanumeric passphrase of up to 64 characters is
  generated from 48 cryptographically-secure random bytes (`SecRandomCopyBytes`),
  standard Base64-encoded with `+`, `/`, and `=` removed.
- It is stored in the iOS Keychain as a `kSecClassGenericPassword` with
  accessibility **`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`**:
  - Only accessible while the device is unlocked.
  - **Not** synced to iCloud Keychain.
  - **Not** included in encrypted backups (device-local).
- Service/account: `com.gentex.ios.db.v2` / `sqlcipher_key`.
- The key is **never** exported, synced, or placed into a QR code.

### Applying the key and verifying encryption (`DatabaseManager`)

The database lives at
`Application Support/Gentex/gentex.db`. Open sequence:

1. Retrieve the passphrase from Keychain (or generate + store it on first run).
2. Open the connection: `try Connection(dbURL.absoluteString)`.
3. **Apply the key as the FIRST operation:** `try db.key(passphrase)`
   (SQLite.swift's documented API, equivalent to `PRAGMA key`).
4. **Verify encryption is active** (see below).
5. Create schema (`teams`, `_schema_metadata`) if missing.
6. Run pending migrations.

There is **no silent fallback** to an unencrypted database. If verification
fails, a controlled `DatabaseError.encryptionNotActive` is raised, which triggers
a clean retry (delete DB files + Keychain key, regenerate, re-open).

### The `PRAGMA cipher_version` verification gotcha

Encryption is verified two ways:

```swift
// Check 1: cipher_version must be NON-EMPTY
let cipherVersion = try? db.scalar("PRAGMA cipher_version") as? String
guard let version = cipherVersion, !version.isEmpty else {
    throw DatabaseError.encryptionNotActive(...)
}

// Check 2: write / read-back sanity check confirms the key decrypts correctly
try db.run("CREATE TABLE IF NOT EXISTS _encryption_check (value TEXT)")
try db.run("INSERT INTO _encryption_check (value) VALUES ('sqlcipher_ok')")
// ...read it back and compare, then DROP the table
```

> **CRITICAL — prior bug:** `PRAGMA cipher_version` returns a string like
> `"4.16.0 community"`. It does **NOT** contain the literal substring
> `"sqlcipher"`. A previous attempt checked for `"sqlcipher"` in the output,
> which always failed and wasted significant time. **The correct check is
> non-empty**: non-empty ⇒ SQLCipher active; empty/nil ⇒ plain system SQLite.

The write/read-back check additionally confirms the key actually decrypts the
data, not just that the SQLCipher engine is present.

---

## 2. Cross-device embedded-key QR transport

This is a **field/transport encryption** concern, fully independent of SQLCipher.
It exists so a single team can be shared to another device and decoded there.

- Algorithm: **`AES/GCM/NoPadding`** (AES-256-GCM) via CryptoKit `AES.GCM`.
- Key: a **fixed 32-byte key embedded in the app binary**, XOR-unmasked at init
  from an obfuscated byte array (identical to the Android `Crypto` object).
- Layout: random **12-byte IV prepended** to ciphertext, **128-bit GCM tag**,
  output as **URL-safe Base64, no wrap, no padding**.
- Android uses the same key and layout but a different JSON payload, so QR codes
  do not transfer between the two apps. Cross-platform sharing is not a
  requirement.

Full byte-level details, JSON contract, and fixture vectors are in
[qr-contract.md](qr-contract.md). The accepted security limitation of the
embedded key is documented in [threat-model.md](threat-model.md).

### Why the QR key is separate from the DB key

- The DB key is **random and device-unique**; it could never be shared without
  breaking device binding. If the QR used the DB key, no other device could
  decrypt a shared team.
- The QR key is **shared and fixed** so another device running the app can
  decode a shared team. It intentionally provides only deterrence, not the
  strong protection the DB key provides.
- Keeping them separate means the strong, device-bound database protection is
  never weakened by the QR sharing requirement.
