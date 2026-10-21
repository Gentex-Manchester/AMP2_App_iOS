# Region & RF Channel Rules

Implemented in `Models/Region.swift` and enforced by `TeamValidation.swift`.

## Regions

There are exactly three regions (`Region` enum):

| Region | `rawValue` | Display name | Available RF channels |
|---|---|---|---|
| North America | `northAmerica` | `North America` | 1, 2, 3, 4, 5 |
| Latin America | `latinAmerica` | `Latin America` | 1, 2, 3, 4, 5 |
| Eurasia | `eurasia` | `Eurasia` | 1, 2, 3, 4, 5 |

`Region(from:)` parses either the raw value or the display name,
case-insensitively, so QR payloads carrying `"North America"` map cleanly.

## Channel availability rules

- **Every region supports the same five RF channels (1–5).**
- RF channels **6–11 are not supported by the app in any region**: they cannot
  be selected in the UI, and `TeamValidation` rejects them on create, edit, and
  QR import.
- Custom teams **transfer freely across all regions** — a team's availability
  never changes with the region, because the channel rules are identical
  everywhere. No disabling, remapping, or channel warnings are needed.

> Supersedes the earlier rule where channels 6–11 were Eurasia-exclusive and
> teams using them were disabled (not remapped) in North America and Latin
> America. Per product decision, the app no longer supports those channels at
> all (see [decisions.md](decisions.md)).

## Field ranges (confirmed)

| Field | Valid range | Notes |
|---|---|---|
| Network ID | **0–255 inclusive** | One byte, matching the headset's LTC setting `0x04` and the Android implementation |
| RF channel (all regions) | 1–5 | 6–11 are unsupported in every region |

## Region source

When a headset is connected, the Regions screen shows the zone the headset
reports (LTC setting `0x0a`) and writes the user's choice back to it. The
selection is also persisted locally (`@AppStorage("selectedRegion")`); that
local value seeds the region of new teams and drives validation, so it works
with no headset connected. The schema does not depend on the source: the
persisted `region` field and the availability logic are the same either way.

## Android parity note

The Android app still models channels 6–11 for Eurasia (with a remap-to-5
fallback in other zones in `CustomTeamHelper`). Until Android is updated to drop
those channels, an Android-exported team with channel 6–11 is **rejected on iOS
import** (validation fails). Tracked as a parity gap; the fix belongs on the
Android side.
