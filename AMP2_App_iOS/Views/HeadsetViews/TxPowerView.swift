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
                Text("Adjusts the transmission power of LTC communications. Higher power increases range and reduces battery life.")
                    .font(.ibmPlexSans(size: 18, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 50)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)

                VStack(spacing: 12) {
                    Slider(
                        value: Binding(
                            get: { index },
                            set: { draftIndex = $0 }
                        ),
                        in: 0...Double(TxPower.allCases.count - 1),
                        step: 1,
                        onEditingChanged: { editing in
                            guard !editing, let draftIndex else { return }
                            settings.write(.txPower, value: TxPower.allCases[Int(draftIndex)].rawValue)
                            self.draftIndex = nil
                        }
                    )
                    .tint(.opsCoreRed)
                    .padding(.horizontal, 30)

                    HStack {
                        Text(TxPower.minus18.displayName)
                            .font(.ibmPlexSans(size: 14))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(settings.settings.txPower?.displayName ?? "—")
                            .font(.ibmPlexSans(size: 18, weight: .bold))
                        Spacer()
                        Text(TxPower.plus10.displayName)
                            .font(.ibmPlexSans(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 30)
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .navigationTitle("LTC Power")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("LTC Power")
                    .font(.ibmPlexSans(size: 28, weight: .bold))
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
