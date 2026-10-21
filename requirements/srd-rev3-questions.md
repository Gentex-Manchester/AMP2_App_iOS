# Open items for Gentex

Rev 3 is the source of truth (confirmed August 24, 2026), so most of what was a
question list is now a decision list. One item remains, and it is a wording
correction rather than a blocker.

## 1. Zone — answered, no app work

**Gentex confirmed on August 25, 2026 that setting `0x0a` is bugged in the
headset.** It is not writable over Bluetooth Classic, BLE, or the headset's own
menu, and the Android app behaves the same way. Nothing changes on either app.

The app keeps the region control and keeps writing the setting; the silent
rollback already prevents it from claiming a change the headset refused.

The evidence that produced the report, all from August 24, 2026:

- **Swept `0x00` to `0x07` over BLE.** All eight acknowledged `LTC_NO_ERR`, all
  eight read back `0x00`. `0x05` to `0x07` are undefined in the BLE command
  document, and the headset accepted those too, so it is not range checking the
  payload.
- **Control.** Writing `0x50` to LTC volume, whose range is `0x00` to `0x0a`,
  returned `LTC_BAD_VALUE` and left the value unchanged. The headset does
  range-check settings it processes, and reports the failure.
- **The headset's own menu fails identically.** Reading the zone twice a second
  while an operator changed the region on the headset and heard it announce
  "selection confirmed", the byte read `0x00` on all 61 reads spanning that
  moment.
- **The part number reports the unit unlocked.** Last eight digits `12011201`,
  third-to-last `2`, which the BLE command document says means no region lock.
- **Not an iOS problem.** Android sends the identical command. Note that Android
  would not surface this: its zone write updates the on-screen state as though
  the headset had confirmed it, with no rollback.

Full packet traces are in [`docs/ble-protocol.md`](../docs/ble-protocol.md) §8.

## 2. Two references that read as Android only

Neither blocks work. Worth correcting in the next revision.

- **Gradle.** Rev 3 says automated tests shall run from the command line using
  Gradle. The iOS equivalent is `xcodebuild`.
- **Xcode 26.3.** This project builds with 26.5.

## Settled, recorded here so they are not re-asked

- **Rev 3 is authoritative**, draft marking notwithstanding. It supersedes the
  Custom Teams deck on custom teams.
- **Per-team security keys wait for documentation.** The BLE command document
  still marks `0x02` "not implemented at this time".
- **Passphrase-derived AES-256 keys wait for Android.** Android is the source of
  truth for iOS; two implementations guessing separately cannot interoperate.
- **Develop against the headset in hand.** No speculative support for models we
  cannot test.
- **Zone (`0x0a`) is a headset firmware defect.** Confirmed by Gentex,
  August 25, 2026. Not an app problem on either platform.
- **MAC filtering on `80:3B:70` is impossible on iOS.** Apps never see Bluetooth
  MAC addresses. The app shortlists by name, then confirms with the part-number
  query after connecting.
