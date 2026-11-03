//
//  TxPowerView.swift
//  AMP2_App_iOS
//
//  LTC transmit power (setting 0x07), -18 dBm to +10 dBm.
//
//  Values follow the Gentex BLE doc, not Android (ble-parity-plan.md decision
//  0.2). A rejected write here means that decision was wrong.
//

import SwiftUI

struct TxPowerView: View {
    @Environment(HeadsetSettingsSync.self) private var settings

    /// Local while dragging so the poll loop doesn't fight the slider; written on release.
    @State private var draftIndex: Double?

    /// Slider runs over the level index, not dBm, since the steps are uneven
    /// (+6 to +10 at the top). Raw bytes 0x00–0x09 are in order, so byte == index.
    private var index: Double {
        draftIndex ?? Double(settings.settings.txPower?.rawValue ?? 0)
    }

    var body: some View {
        ScrollView {
            VStack {
                SelectionSlider(
                    level: index,
                    range: 0...Double(TxPower.allCases.count - 1),
                    onSelection: { selection in
                        settings.write(.txPower, value: TxPower.allCases[Int(selection)].rawValue)
                    },
                    label: { selection in
                        settings.settings.txPower?.displayName ?? "—"
                    },
                    description: "Determines how much power the headset gives to LTC, which impacts transmission range.",
                    lowLabel: TxPower.minus18.displayName,
                    highLabel: TxPower.plus10.displayName
                )
            }
            .frame(
                maxWidth: .infinity,
                alignment: .top
            )
            .padding(
                .horizontal, 16
            )
        }
        .navigationTitle("LTC Power")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                AppText("LTC Power", style: .header3)
            }
        }
    }
}

#Preview {
    let session = HeadsetSession()
    NavigationStack {
        TxPowerView()
            .environment(HeadsetSettingsSync(transport: session))
    }
}
