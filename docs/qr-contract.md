# QR Payload Contract

Defines the versioned QR payload for sharing a **single** custom
team. Implemented in `QRPayload.swift` (JSON contract) and `QRCodeCrypto.swift`
(encryption wrapper). The full database is never shared.

The pipeline is:

```
export:  Team → QRPayload(JSON) → AES-256-GCM encrypt → URL-safe Base64 → QR
import:  QR → URL-safe Base64 → AES-256-GCM decrypt → QRPayload(JSON) → validate → Team
```

QR payload protection is **separate** from the SQLCipher database encryption (see
[encryption-architecture.md](encryption-architecture.md)). The SQLCipher key and
database file never enter a QR code.

---

## 1. JSON payload (version 1)

```json
{
  "version": 1,
  "team": {
    "name": "Alpha Team",
    "region": "North America",
    "rfChannel": 3,
    "securityKey": "MIKE",
    "networkId": 42
  }
}
```

> Note: `QRPayload.encode()` uses `JSONEncoder` with `.sortedKeys`, so keys are
> emitted alphabetically and deterministically. The order above is illustrative.

### Field contract

| Field | JSON key | Type | Required | Notes |
|---|---|---|---|---|
| version | `version` | Int | Yes | Payload schema version. **Currently `1`.** Checked after the payload decodes |
| team.name | `name` | String | Yes | Team name; trimmed on import |
| team.region | `region` | String | Yes | Stored region string: `Region.rawValue` (e.g. `"northAmerica"`) for teams created on iOS. Import accepts a raw value or display name |
| team.rfChannel | `rfChannel` | Int | Yes | 1–5 (every region) |
| team.securityKey | `securityKey` | String | Yes | Predefined key as stored, e.g. `"Mike"`; any casing accepted on import |
| team.networkId | `networkId` | Int | Yes | 0–255 inclusive (one byte) |

### Versioning

- `version` is always present. The whole payload is decoded first, then the
  version is checked: a payload with the v1 fields and any other version throws
  `unsupportedVersion`, and one missing a v1 field fails JSON decoding.
- The contract leaves room for a future **optional** `customSecurityKey` field
  (see below), and for other additive fields under `team` or at the top level.

### `customSecurityKey` handling (this phase)

- **Omitted** from generated payloads (version 1 does not include it).
- **Not required** on import; imported teams get `customSecurityKey = nil`.
- Reserved for a future payload version. If a future payload unexpectedly
  includes it, current code ignores it (the version-1 decoder has no such field)
  rather than inventing behavior.

### Import validation & conflict handling

On import, the decoded team is validated (`TeamValidation.validateTeam`).
The RF channel range is 1–5 in every region, so import validation is identical
to save-time validation. Invalid payloads throw `QRPayloadError.validationFailed`.
The imported team arrives with `id = 0`; duplicate detection at save time
(`TeamStore`) deterministically blocks importing a team whose region + RF channel
+ security key + network ID + name already exist.

---

## 2. Encryption wrapper (same as Android's `Crypto`)

Implemented with CryptoKit `AES.GCM` in `QRCodeCrypto.swift`, matching the
Android `Crypto` object in the Android repo's `util/Crypto.kt`.

| Property | Value |
|---|---|
| Algorithm | `AES/GCM/NoPadding` (AES-256-GCM) |
| Key | Fixed 32-byte key, XOR-unmasked from an embedded obfuscated array |
| IV / nonce | Random **12 bytes**, **prepended** to the ciphertext |
| Auth tag | **128-bit (16 bytes)**, appended after the ciphertext |
| Output encoding | **URL-safe Base64, no wrap, no padding** (`+`→`-`, `/`→`_`, `=` stripped) |
| Combined layout | `IV(12) ‖ ciphertext ‖ tag(16)` |

> CryptoKit's `AES.GCM.SealedBox` exposes `ciphertext` and `tag` separately; the
> iOS code concatenates `IV + ciphertext + tag` to match Java, whose
> `cipher.doFinal` already returns `ciphertext + tag`.

### Key derivation

```
realKey[i] = OBFUSCATED_KEY[i] XOR MASK[i % MASK.length]
```

- `MASK` = `42 7A 1C 3F` (4 bytes)
- `OBFUSCATED_KEY` = 32 bytes (see `QRCodeCrypto.swift` / Android `util/Crypto.kt`)

---

## 3. Fixture vectors (Android/iOS compatibility)

### 3a. Derived 32-byte AES key

Deterministic result of XOR-unmasking the embedded key. Both platforms MUST
derive exactly these bytes:

```
hex:
47 33 4e 6c 33 70 5f 43 30 62 33 1f 33 6c 31 6c
33 5f 44 33 61 75 5f 53 33 63 75 6a 31 70 79 21
```

(31 of the 32 bytes are printable ASCII — approximately
`G3Nl3p_C0b3?3l1l3_D3au_S3cuj1py!`, where byte index 11 `0x1F` is a non-printable
control byte. The **hex above is authoritative**, not the ASCII rendering.)

A unit test asserts this exact vector so any drift in the embedded key or mask
between platforms is caught immediately.

### 3b. Sample plaintext JSON (pre-encryption)

The exact bytes fed into AES-GCM for a version-1 export of a sample team, with
`.sortedKeys` applied:

```json
{"team":{"name":"Alpha Team","networkId":42,"region":"North America","rfChannel":3,"securityKey":"MIKE"},"version":1}
```

### 3c. Round-trip note

Because the IV is random per encryption, the Base64 ciphertext string is **not**
reproducible across runs. Compatibility is verified by:

- **Key-derivation vector** equality (3a) — deterministic, byte-exact.
- **Cross-key interop decrypt** — encrypt on one side, decrypt on the other using
  the shared derived key and the `IV ‖ ciphertext ‖ tag` layout.
- **URL-safe Base64** round-trip and IV-length/short-input/tamper failure tests.

## 4. Android compatibility

QR codes do **not** transfer between iOS and Android. Cross-platform sharing is
not a requirement, and the Android app uses its own payload: a `GENTEX_TEAM:`
prefix and short-key JSON (`n`, `r`, `c`, `s`, `nid`) with string channel
values such as `"Channel 3"`. The encryption is the same on both platforms; the
JSON is not.

- Android uses `AES/GCM/NoPadding`, a 12-byte IV via `SecureRandom`, a 128-bit
  `GCMParameterSpec` tag, and `Base64.NO_WRAP | Base64.URL_SAFE`. iOS mirrors all
  of these.
- Android's `Base64.URL_SAFE` tolerates missing padding on decode; iOS restores
  padding before decoding (`Data(base64EncodedStringPadded:)`).
- Both platforms share the same `MASK` and `OBFUSCATED_KEY`, so the derived AES
  key is identical.
- `customSecurityKey` is omitted on both platforms in this phase.
