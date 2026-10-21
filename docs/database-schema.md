# Database Schema

The custom-teams database is a single encrypted SQLite (SQLCipher) file at
`Application Support/Gentex/gentex.db`, accessed through SQLite.swift typed
queries (`TeamSchema.swift`, `TeamStore.swift`).

## Tables

### `teams`

The team fields mirror the Android `TeamEntity`.

| Column | SQLite type | Swift type | Notes |
|---|---|---|---|
| `id` | `INTEGER PRIMARY KEY AUTOINCREMENT` | `Int64` | Local row id; not shared in QR payloads |
| `region` | `TEXT NOT NULL` | `String` | `Region.rawValue` (e.g. `"northAmerica"`) for teams created in the app; QR imports keep the payload's string. `Region(from:)` reads either form |
| `rf_channel` | `INTEGER NOT NULL` | `Int` | 1–5 in every region (see [region-rules.md](region-rules.md)) |
| `security_key` | `TEXT NOT NULL` | `String` | One of 10 predefined keys (see below) |
| `custom_security_key` | `TEXT` (nullable) | `String?` | **Reserved.** Must be `nil` this phase |
| `network_id` | `INTEGER NOT NULL` | `Int` | 0–255 inclusive (one byte) |
| `name` | `TEXT NOT NULL` | `String` | Non-empty after trimming |
| `is_favorited` | `INTEGER NOT NULL DEFAULT 0` | `Bool` | Favorite flag |
| `is_locked` | `INTEGER NOT NULL DEFAULT 0` | `Bool` | Locked flag; future hook for active-team protection |

Typed schema (`TeamSchema.swift`) exposes these as SQLite.swift `Expression`s,
and `TeamStore` uses typed `insert`/`update`/`filter`/`order` queries rather than
ad-hoc SQL strings.

**Predefined security keys**, validated case-insensitively against a title-case list:
`Mike, November, Oscar, Papa, Quebec, Romeo, Sierra, Tango, Uniform, Victor`.
The `SecurityKey` enum (`SecurityKey.swift`) retains its uppercase raw values
(`MIKE`, `VICTOR`, etc.) for QR payload encoding/decoding and Codable
compatibility. Validation uses a separate title-case list in `TeamValidation`.
Any casing is accepted on input and stored as supplied: the UI writes title
case, and a QR import keeps the payload's casing.

### `_schema_metadata`

Key/value table holding iOS-only persistence bookkeeping, kept **separate** from
the shared team payload fields.

| Column | Type | Notes |
|---|---|---|
| `key` | `TEXT PRIMARY KEY NOT NULL` | e.g. `schema_version` |
| `value` | `TEXT NOT NULL` | e.g. `"2"` |

## Migration strategy

- **Current schema version: `2`** (`TeamSchema.currentVersion`).
- Version is persisted in `_schema_metadata` under `schema_version`. A missing
  row is treated as version `0` (pre-versioned), so migrations begin at 1.
- `TeamSchema.migrations` is a `[Int: [String]]` keyed by **target** version.
  Version 1 is the initial schema and has **no migration entry** — the tables are
  created by `allDDL`. Version 2 rewrites the old `Victory` spelling:
  `UPDATE teams SET security_key = 'Victor' WHERE security_key COLLATE NOCASE = 'Victory'`.
- On open, `DatabaseManager.runMigrations` walks from `storedVersion + 1` up to
  `currentVersion`, runs each version's statements (if any), then records the new
  version. Adding a future migration is: bump `currentVersion`, add the DDL under
  `migrations[newVersion]`.
- `CREATE TABLE ... IF NOT EXISTS` makes initial creation idempotent.

> The schema is intentionally aligned to the Android entity and kept
> forward-compatible: `custom_security_key` already exists (nullable, unused)
> and the design leaves room for future headset-derived state without reshaping
> the table (see [future-phases.md](future-phases.md)).

## Validation (`TeamValidation.swift`)

Validation is stateless and enforced by `TeamStore` on create/update (and by
`QRPayload` on import):

- **Network ID:** integer in `0...255` inclusive; otherwise rejected. The
  headset carries this value in a single byte (LTC setting `0x04`).
- **RF channel:** must be in `1...5` — the same range in every region.
- **Security key:** must match one of the 10 predefined keys (case-insensitive; stored as supplied).
- **`customSecurityKey`:** must be `nil` — any non-nil value yields
  `customSecurityKeyNotSupported`.
- **Name:** non-empty after trimming whitespace.

Validation failures surface as `DatabaseError.databaseOperationFailed` with a
readable message and never produce a partial/corrupt write.

## Duplicate prevention

`TeamStore` blocks duplicate teams. Two teams are "the same" when their
**region, RF channel, security key, network ID, and name** all match (ignoring
`id`, `isFavorited`, `isLocked`). `create` rejects any duplicate; `update`
rejects duplicates excluding the row being edited.
