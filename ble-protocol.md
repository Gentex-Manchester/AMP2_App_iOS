# BLE Protocol (iOS)

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
no checksum. 

### Bluetooth Classic is a hard prerequisite

The headset exposes no BLE service until it is **Connected** over Bluetooth
Classic in iOS Settings. Paired-but-not-connected is not enough, and neither is
sitting in pairing mode. An iOS app cannot initiate Classic pairing itself, so
the user must do it in Settings. The in-app pairing flow covers this
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
3. An **unfiltered** scan, shortlisted by name (`amp`)

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

Read team: `00 1d 40 2c 00 00 01`
Write Alpha to team: `00 1d 40 2c 01 00 01 00`

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
| `0x01` | Security key | `0x00` Mike … `0x0A` Custom |
| `0x02` | Custom security key | Any AES-256 key |
| `0x03` | RF channel | Unused |
| `0x04` | Network ID | Unused |
| `0x05` | LTC mode | `0x00` Off, `0x01` PTT, `0x02` VAD |
| `0x06` | VAD threshold | `0x00`–`0x0a` |
| `0x07` | Tx power | `0x00`–`0x09` |
| `0x08` | LTC volume | `0x00`–`0x0a` |
| `0x09` | Act as LTC repeater | Unused |
| `0x0a` | Zone | `0x00` Americas, `0x01` Eurasia — **Only available for select headset models** |

## 5. Headset identity

    Query:    00 1d 40 0c 00 00 00 2f
    Response: 00 1d 41 0c 00 00 00 2f <ASCII part number> 00

Development unit answers `1004257-1201-1201`.

**Region lock** — take the last eight digits ignoring hyphens (`12011201`) and
read the third-to-last as the kit: `0` North America locked, `3` Europe locked,
`1`/`2` unlocked. When locked, the region selector is hidden entirely because
the headset rejects zone changes.

The part number also identifies the variant (`1004257` Flagship, `1004058`
Base), but nothing branches on it.

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
then read back as a different value**. That last case is not hypothetical,
and it is why an ACK is treated as provisional rather than as proof.

**A rollback is silent.** The control returns to the headset's real value and
says nothing. The failure is recorded in `lastFailure` for the packet console 
and printed to the debug log, and that is as far as it goes.

Diagnostics read `confirmed`, never `settings` — a console that showed
optimistic values would report bytes the headset never sent.

---

## 7. Documentation errata

Gentex originally asked for the iOS pairing tutorial to match Android's, where a button
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

The obvious follow-up is to update the headset to advertise the GAIA service UUID, since
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
