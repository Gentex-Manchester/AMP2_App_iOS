# BLE Protocol (iOS)

How the iOS app talks to the AMP 2.0 headset, **as implemented and verified on
hardware** — not as originally documented. Where the two differ, this file
records the difference and how we found it.

Source of truth for the wire format is
Gentex's *LTC Configuration Commands (BLE)* document (July 27, 2026).
Errata are listed at the bottom.

Implementation: `Gentex_iOS/Bluetooth/`.

---

## 1. Transport

| | |
|---|---|
| GATT service | `00001100-d102-11e1-9b23-00025b00a5a5` |
| Write characteristic | `00001101-d102-11e1-9b23-00025b00a5a5` |
| Notify characteristic | `00001102-d102-11e1-9b23-00025b00a5a5` |

Commands are written to the write characteristic; responses arrive as
notifications on the notify characteristic.

### This is not the Android transport

Android talks to the headset over Bluetooth Classic / SPP and frames every
packet for it: an `FF 03 01 <len>` header before the payload, and an XOR
checksum after. **Over BLE the headset expects the bare packet** — no framing,
no checksum. Confirmed on hardware: the headset answers unframed packets and
`Gentex_Android/…/protocol/PacketBuilder.kt` must not be ported.

### Bluetooth Classic is a hard prerequisite

The headset exposes no BLE service until it is **Connected** over Bluetooth
Classic in iOS Settings. Paired-but-not-connected is not enough, and neither is
sitting in pairing mode. An iOS app cannot initiate Classic pairing itself, so
the user must do it in Settings. `ConnectionTutorialView` covers this
explicitly because the failure is silent — the app simply finds nothing.

### Discovery

**The headset advertises no service UUIDs.** `scanForPeripherals(withServices:
[gaia])` therefore never matches it, and `retrieveConnectedPeripherals(with
Services:)` returns nothing until some app has connected to it over BLE at
least once — iOS holds no GATT service record for a device only paired over
Classic. Both of these were discovered by hardware testing after the obvious
implementation found nothing at all.

`HeadsetSession.startDiscovery` therefore tries, in order:

1. `retrievePeripherals(withIdentifiers:)` for a remembered headset
2. `retrieveConnectedPeripherals(withServices:)` — works only after (3) has
   succeeded once
3. An **unfiltered** scan, shortlisted by name (`gentex` or `amp`)

The name check is load-bearing, being the only pre-connection signal available.
Legitimacy is confirmed after connecting: a device without the GAIA service
fails with `.serviceNotFound`, and the part-number query says what answered.

---

## 2. Command format

    00 1d 40 2c <op> <setting> <length> [payload]

| Field | Value |
|---|---|
| Header | `00 1d 40 2c` |
| Op | `0x00` read, `0x01` write |
| Setting | see below |
| Length | expected response length for a read; payload length for a write |

Read the predefined team: `00 1d 40 2c 00 00 01`
Write the predefined team to Alpha: `00 1d 40 2c 01 00 01 00`

## 3. Response format

    00 1d 41 2c [payload]

A read returns the setting's value; a write returns a status code. **The two
are indistinguishable from the bytes alone** — correlation depends on only one
request being outstanding, which `HeadsetSettingsSync` guarantees by
serializing its queue.

| Status | Meaning |
|---|---|
| `0x00` | `LTC_NO_ERR` |
| `0x01` | `LTC_ERR_LEN` |
| `0x02` | `LTC_BAD_VALUE` |
| `0x03` | `LTC_ERR_COMM_FAIL` |

**`LTC_NO_ERR` does not mean the setting applied.** The headset acknowledges
before it knows. See the LTC mode blocker below.

## 4. Settings

| ID | Setting | Values |
|---|---|---|
| `0x00` | Predefined team | `0x00` Alpha … `0x04` Joint Ops |
| `0x01` | Security key | `0x00` Mike … `0x09` Victor |
| `0x02` | Custom security key | reserved, not implemented in firmware |
| `0x03` | RF channel | `0x00`–`0x04` = channels 1–5 (0-based on the wire, 1-based in the UI) |
| `0x04` | Network ID | any byte, `0x00`–`0xff` |
| `0x05` | LTC mode | `0x00` Off, `0x01` PTT, `0x02` VAD |
| `0x06` | VAD threshold | `0x00`–`0x0a` |
| `0x07` | Tx power | `0x00`–`0x09` (see errata) |
| `0x08` | LTC volume | `0x00`–`0x0a` |
| `0x0a` | Zone | `0x00` North America, `0x01` Latin America, `0x02` Eurasia — **but SRD rev 3 lists only two zones; see §8** |

`0x09` (frequency hopping) is referenced by the Android app but undefined in the
documentation, so it is not implemented.

### Predefined teams

Every preset uses security key Mike. A team whose live key, channel, and network
ID match none of these is a **custom** team.

| Team | RF channel | Network ID |
|---|---|---|
| Alpha | 2 | 100 |
| Bravo | 3 | 125 |
| Charlie | 4 | 150 |
| Delta | 5 | 175 |
| Joint Ops | 1 | 200 |

Detection uses these three settings, **not** the `0x00` team byte, which goes
stale as soon as a custom team overwrites the settings it implies.

**Switching teams is a different matter: write the team byte.** Setting `0x00` is
what the headset treats as a team change. It plays a spoken confirmation and
derives the key, channel, and network ID itself. Writing those three settings
individually reaches the same values without ever telling the headset a team
changed, so it stays silent and its team byte goes stale.

Confirmed on hardware, August 24, 2026, switching to Charlie:

    Write team = 0x02:   00 1D 40 2C 01 00 01 02
    Response:            00 1D 41 2C 00        (LTC_NO_ERR)
    Read team:           00 1D 40 2C 00 00 01
    Response:            00 1D 41 2C 02        (Charlie)
    Read security key:   00 1D 40 2C 00 01 01
    Response:            00 1D 41 2C 00        (Mike)
    Read RF channel:     00 1D 40 2C 00 03 01
    Response:            00 1D 41 2C 03        (channel 4)
    Read network ID:     00 1D 40 2C 00 04 01
    Response:            00 1D 41 2C 96        (150)

Channel 4 and network 150 are Charlie's values, and the app never sent them.

A **custom** team has no team byte, so it still goes out as three writes. That is
the only case where the three-write sequence is correct. Android reached the same
conclusion on July 24, 2026 — the sequence is commented out above
`TeamsViewModel.setTeam`.

## 5. Headset identity

    Query:    00 1d 40 0c 00 00 00 2f
    Response: 00 1d 41 0c 00 00 00 2f <ASCII part number> 00

Development unit answers `1004257-1201-1201`.

**Region lock** — take the last eight digits ignoring hyphens (`12011201`) and
read the third-to-last as the kit: `0` North America locked, `3` Europe locked,
`1`/`2` unlocked. When locked, the region selector is hidden entirely because
the headset rejects zone changes.

Our unit is kit `2` — unlocked — so **the region-locked path has never been
exercised on hardware.**

The part number also identifies the variant (`1004257` Flagship, `1004058`
Base), but nothing branches on it: Gentex withdrew the requirement that custom
teams be Flagship-only.

## 6. Timing

Ported from Android's `HeadsetManager`, whose values exist because the hardware
misbehaves without them. Treat as a starting point over BLE, not a
specification — MTU and notification delivery differ from SPP.

| | |
|---|---|
| Inter-packet delay | 200 ms |
| Response timeout | 1.5 s (an unanswered write rolls back) |
| Heartbeat | 5 s, all nine settings |
| Post-write cooldown / lull | 3 s |

**Do not poll while the headset is applying a setting.** An earlier
implementation re-read each setting immediately after writing it, to confirm
rather than assume. That put a read on the link 200 ms after the write, while
the headset was still re-initializing, and it announced "configuration failed."
The lull timer re-reads everything once the user stops making changes, which is
what Android does and why Android does not have this problem.

### Why the UI does not wait for confirmation

Those timings put 3–5 seconds between a tap and the headset confirming it: the
lull has to expire, then the heartbeat has to poll its way round to the setting.
Blocking the UI for that long made every control feel broken.

`HeadsetSettingsSync` therefore keeps two things apart:

| | |
|---|---|
| `confirmed` | What the headset has actually reported. Written only by poll responses. |
| `settings` | What the UI shows: `confirmed` with unconfirmed changes laid over it. |

A change appears immediately and is rolled back when the headset disagrees —
rejected, unsendable, unanswered, an unparseable reply, or **acknowledged and
then read back as a different value**. That last case is not hypothetical: it is
exactly what §7 below describes, and it is why an ACK is treated as provisional
rather than as proof.

**A rollback is silent.** The control returns to the headset's real value and
says nothing. These fire during normal operation — zone is refused on every
attempt today (§8), and LTC mode was until a power cycle fixed it (§7) — and a
warning each time reads as the app malfunctioning when it is working correctly.
The failure is recorded in `lastFailure` for the packet console and printed to
the debug log, and that is as far as it goes.

Diagnostics read `confirmed`, never `settings` — a console that showed
optimistic values would report bytes the headset never sent.

---

## 7. Resolved — LTC mode `0x04` is cleared by a power cycle

**Resolved August 21, 2026. A battery pull fixes it.** Removing the headset's
battery, leaving it out briefly, and refitting it clears the `0x04` state.
PTT and VAD then write and read back correctly, confirmed on hardware.

`0x04` is therefore a **latched** failure state, not a permanent fault: once the
radio fails to initialize the headset stays stuck there, and no amount of
rewriting the setting recovers it. Only a full power cycle does. A reboot from
the headset's own menu was not tried, so it is unknown whether the battery has
to come out or whether any power cycle suffices.

Consequences worth keeping:

- **VAD threshold is testable again.** It only applies in VAD mode, which the
  headset can now enter.
- **An ACK still is not proof.** The optimistic-write rollback in §6 was built
  for this fault and stays. Whatever latched the radio once can latch it again,
  and §8 below shows zone failing the same way today.
- If a user reports a setting that will not change and reads back as an
  undocumented value, **ask them to pull the battery** before anything else.

The original diagnosis follows, since it is what the fault looks like when live.

Writing PTT (`0x01`) or VAD (`0x02`) is acknowledged with `LTC_NO_ERR`, then the
headset announces "configuration failed, try again" and the setting reads back
as `0x04` — a value the documentation does not define. Writing Off (`0x00`)
works and reads back correctly.

    Write PTT:       00 1D 40 2C 01 05 01 01
    Response:        00 1D 41 2C 00        (LTC_NO_ERR)
    Read LTC mode:   00 1D 40 2C 00 05 01
    Response:        00 1D 41 2C 04

The headset was confirmed at `0x00` before this exchange, so `0x04` is an
initialization-failure state rather than a stale boot value. `0x00` tears the
radio down and cannot really fail; `0x01` and `0x02` require it to come up.

Reported to Gentex. See `requirements/ble-parity-plan.md` for status. The report
stands: the headset should not latch into an undefined state that only a battery
pull clears, and Gentex is worth telling that the workaround exists.

---

## 8. Closed — zone is a headset defect, and not ours to fix

**Gentex confirmed this on August 25, 2026.** Setting `0x0a` is bugged in the
headset firmware and is not writable over Bluetooth Classic, BLE, or the
headset's own menu. The Android app hits the same wall. No app-side work will
change it, and none is planned.

The investigation that led there is kept below, because it also establishes what
the app does correctly and why the region control stays on screen.

### The original finding

Writing zone (`0x0a`) is acknowledged and then not applied, the same shape as the
LTC mode fault above. Captured August 21, 2026, on a headset that had just been
power-cycled and whose LTC mode was working normally in the same session:

    Write zone Eurasia:  00 1D 40 2C 01 0A 01 02
    Response:            00 1D 41 2C 00        (LTC_NO_ERR)
    Read zone:           00 1D 40 2C 00 0A 01
    Response:            00 1D 41 2C 00        (0x00, still North America)

The packet is well-formed against §2 and §4: op `01`, setting `0A`, length `01`,
payload `02`. The read that follows uses the same setting byte and works.

**The app is not involved.** Two further tests, same session:

1. **Isolated write, polling stopped.** Same result — acknowledged, then read
   back as `0x00` twice in a row. The queue, the lull, and the 3s cooldown are
   all ruled out.
2. **Changed from the headset's own button menu, no phone involved.** The
   headset announced "selection confirmed" and the zone still read `0x00` on
   every subsequent poll.

Test 2 is decisive and mirrors how §7 was pinned down: the fault reproduces with
the app entirely out of the picture, so it is hardware-side.

Note it does **not** distinguish a region lock from a latched failure, since a
locked unit would presumably refuse its own menu too. The next test that would
separate them is a battery pull followed by a zone change, because that is what
cleared the §7 fault.

**Most likely cause: the unit is region-locked and our kit-digit decoding is
wrong.** The Gentex documentation says a region-locked headset rejects zone
changes, which is exactly this behavior. Per §5 we decode part number
`1004257-1201-1201` as kit `2`, meaning unlocked, by taking the last eight digits
(`12011201`) and reading the third-to-last. If that rule is misread, the app is
offering a Region selector on a locked headset and every write will be refused.

Worth noting the decoding has never been validated against a unit known to be
locked — `requirements/ble-parity-plan.md` §0.1 flagged that gap when the rule
was written, and this may be it surfacing.

### Ruled out: the radio being up

Zone sets the RF regulatory band, so firmware refusing to move it mid-transmit
was a plausible cause — LTC mode read `0x01` during the tests above. Tested
directly:

    Write LTC mode Off:  00 1D 40 2C 01 05 01 00
    Response:            00 1D 41 2C 00
    Write zone Eurasia:  00 1D 40 2C 01 0A 01 02
    Response:            00 1D 41 2C 00
    Read zone:           00 1D 40 2C 00 0A 01
    Response:            00 1D 41 2C 00        (still North America)
    Read LTC mode:       00 1D 40 2C 00 05 01
    Response:            00 1D 41 2C 00        (confirmed Off)

The radio was down and zone was still refused. **Not the cause**, and no
zone-before-LTC sequencing is needed in the app.

### Resolved: the headset does not process zone writes

Swept every value from `0x00` to `0x07`, reading back after each. All eight were
acknowledged `LTC_NO_ERR`, and the zone read back `0x00` every time.

    Write zone = 0x00 … 0x07:  00 1D 40 2C 01 0A 01 xx
    Response, all eight:       00 1D 41 2C 00        (LTC_NO_ERR)
    Read zone, all eight:      00 1D 41 2C 00        (unchanged)

`0x05`, `0x06`, and `0x07` are undefined in every version of the documentation.
A setting that is being processed would reject them.

**Control, to prove the headset rejects bad values elsewhere.** LTC volume takes
`0x00` to `0x0a` and is known to work:

    Write LTC volume = 0x50:   00 1D 40 2C 01 08 01 50
    Response:                  00 1D 41 2C 02        (LTC_BAD_VALUE)
    Read LTC volume:           00 1D 40 2C 00 08 01
    Response:                  00 1D 41 2C 05        (unchanged)

So the headset does range-check settings it handles, and reports the failure.
Zone gets no range check at all, which means the write is discarded before
anything looks at the payload.

**Setting `0x0a` is read-only on this unit over BLE.** Not a value-mapping error,
not a region lock, and not fixable in the app.

**The headset's own menu cannot change it either.** Reading the zone twice a
second while an operator changed the region on the headset and heard it announce
"selection confirmed", the byte read `0x00` on all 61 reads spanning that moment.
Nothing changes the zone on this unit, over BLE or from the hardware itself.

### Ruled out along the way

- **An out-of-range zone value.** SRD rev 3 lists two zones where the BLE
  document lists three, so `0x02` looked like it might no longer exist. `0x01` is
  valid under either reading and was ignored the same way.
- **A region lock.** The BLE document's rule is to take the last eight digits of
  the part number and read the third-to-last: `0` North America locked, `3`
  Europe locked, `1` or `2` unlocked. `1004257-1201-1201` gives `12011201`,
  third-to-last `2`. **Unlocked.** `HeadsetIdentity.regionLock` already computes
  this correctly. An earlier revision of this section proposed reading the third
  digit of the final group instead, which gives `0`; that reading appears nowhere
  in the documentation and was fitted to the symptom. Withdrawn.
- **A different byte for Europe & Asia.** Android carries a commented-out map
  where `0x02` was Brazil and `0x04` was Japan, which suggested Europe & Asia
  might live elsewhere. The sweep covered `0x00` through `0x07`.
- **The radio being up.** Zone is refused with LTC Off, confirmed.
- **The app being involved at all.** The headset's own menu fails identically,
  watched live at two reads per second.
- **The app's queue, lull, or write cooldown.** Every test above wrote outside
  the queue entirely.

### What Android does

Identical. `SETTING_ZONE = 0x0A`, values `0x00`, `0x01`, `0x02`, sent as a single
`ConfigChange`. There is nothing to port.

Two differences worth noting. Android's `setZone` calls
`updateStateFromHardware`, writing the requested zone into state as though the
headset had reported it, with no rollback — so **Android would not notice this
failure**, and the absence of an Android bug report is not evidence the hardware
works. And Android implements no region-lock check at all, so the "hide the
region setting on locked headsets" requirement is unimplemented there.

Android's zone screen does carry a warning this app lacks: "This setting may
adjust what teams are available. Users in different zones may not be able to
communicate."

### Where it landed

Gentex answered on August 25, 2026: `0x0a` is bugged in the headset, across all
three transports, and is not an app problem on either platform.

So the app keeps the Region selector visible and keeps writing the setting. Zone
reads correctly and is shown to the user, so the screen still earns its place,
though it does not change which RF channels are legal (1–5 everywhere). The silent rollback in §6 already stops the app
from claiming a change the headset refused, which is exactly the behavior a
firmware fix would need on the other side.

Revisit only if a later firmware release lists `0x0a` as fixed.

---

## 9. Documentation errata

Found while implementing. Worth correcting upstream.

| Documented | Reality |
|---|---|
| Identify headsets by MAC prefix `80:3B:70` | iOS never exposes Bluetooth MAC addresses. Impossible as written; we identify by service UUID after connecting, then by part number |
| RF channel 11 is `0x10` in the settings table | `0x0a`, per the same document's Set Custom Team section and the Android app. Moot since channels 6–11 were dropped, but the table is wrong |
| Tx power is 10 values, −18 to +10 dBm | Unresolved. Android uses 11 values, −40 to +10 dBm. We follow the documentation as the newer source; writing `0x0a` would settle it, but that is a live radio setting so it has not been attempted |
| LTC mode has three values | The headset also reports `0x04`, undefined anywhere |
| "Connect over Bluetooth Classic first" | True but understated — merely *paired* is not enough, and nothing in the app can detect the difference except finding no service |

---

## 10. The advertisement, and why pairing cannot happen in the app

Gentex asked for the iOS pairing tutorial to match Android's, where a button
opens the system Bluetooth screen via `Settings.ACTION_BLUETOOTH_SETTINGS`.
**iOS has no equivalent.** `UIApplication.openSettingsURLString` opens the app's
own permission page — which is what the old tutorial did, and why it confused
people. `App-Prefs:root=Bluetooth` is private API and gets apps rejected.

**AccessorySetupKit** (iOS 18+) is the one API that could have paired in-app.
It cannot see this headset.

An `ASDiscoveryDescriptor` has to match on something. Setting
`bluetoothNameSubstring` alone is not allowed — it traps the process rather than
returning an error:

```
Fatal error: ASDiscoveryDescriptor's must include bluetoothCompanyIdentifier
or bluetoothServiceUUID when using bluetoothNameSubstring.
```

That leaves two candidates, and the AMP 2.0 supplies neither:

| Descriptor field | What the headset advertises |
|---|---|
| `bluetoothServiceUUID` | Nothing. It advertises no service UUIDs — the same fact that forces the unfiltered scan, see `requirements/ble-parity-plan.md` §0.1 |
| `bluetoothCompanyIdentifier` | Nothing. **No manufacturer data at all** |

Confirmed on hardware, August 2026, with the headset in pairing mode and
actively advertising: `mfr data: (none)`, `advertises: (none)`. The packet
console's unfiltered scan shows both fields per device, so this is re-checkable
in a few taps — the manufacturer line is red when there is no company
identifier.

Two things make this awkward to measure, and both cost a test cycle:

- The headset only advertises while in **pairing mode**, which times out on its
  own. Once the app connects, it stops advertising entirely.
- The app connects to a remembered headset through
  `retrievePeripherals(withIdentifiers:)` **without scanning at all**, so
  `didDiscover` never fires and the advertisement is never seen. Disconnect
  first, then run the unfiltered scan.

**Consequence:** pairing happens in the Settings app, and the tutorial explains
how instead of offering a button.

### Why a firmware change would not fix it either

The obvious follow-up is to ask Gentex to advertise the GAIA service UUID, since
the headset already runs that service and simply does not announce it. That
would make the headset *discoverable* by the picker. It would not make pairing
work, and the request should not be made on those grounds.

AccessorySetupKit does not establish Bluetooth Classic connections. An Apple
engineer states it plainly, in an accepted answer on
[Developer Forums thread 759880](https://developer.apple.com/forums/thread/759880):

> Bluetooth classic devices cannot be set up by their own with ASK. If an LE
> device supports Cross Transport Key Derivation, its counterpart classic device
> will be set up as part of the process.

So the Classic link this headset requires appears only as a side effect of
**Cross-Transport Key Derivation**, a Bluetooth stack feature the accessory must
implement. That is firmware and possibly silicon work on a legacy Qualcomm/CSR
GAIA part, not a change to what the device broadcasts. The only public attempt
to exercise this path — a developer who implemented CTKD in ESP32 firmware
specifically to test `bluetoothTransportBridging` — reported it *preventing*
Classic setup rather than enabling it, as of July 2025
([thread 791707](https://developer.apple.com/forums/thread/791707)).

**Adopting AccessorySetupKit is also not free.** Declaring
`NSAccessorySetupKitSupports` changes `CBCentralManager` behavior app-wide:
it does not reach `poweredOn` until an accessory is ASK-authorized, and scanning
is confined to ASK-known peripherals. That would break the unfiltered scan this
app depends on. This is the reason the ASK integration was removed outright
rather than left dormant behind a flag.

Revisit only if Gentex confirms CTKD support in the headset's Bluetooth stack
**and** Apple's bridging path has a working precedent. An advertisement change
alone is not sufficient.
