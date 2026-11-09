//
//  RegionsView.swift
//  AMP2_App_iOS
//
//  The headset's operating region (zone, setting 0x0a).
//
//  Writes the headset's zone when connected; otherwise sets the stored
//  preference. Region-locked headsets hide the row.
//

import SwiftUI

struct RegionsView: View {
    @Environment(HeadsetSettingsSync.self) private var headsetSettings
    @Environment(HeadsetSession.self) private var session

    var body: some View {
        ScrollView {
            SelectionButtonRow(
                options: Region.allCases,
                selection: Binding(
                        get: {
                            headsetSettings.settings.zone ?? Region.americas
                        },
                        set: { selection in
                            headsetSettings.write(
                                LTCSetting.zone,
                                value: selection.ltcByte
                            )
                        }
                    ),
                onSelection: { selection in
                    headsetSettings.write(LTCSetting.zone, value: selection.ltcByte)
                },
                label: { option in
                    switch option {
                    case .americas: return "Americas"
                    case .eurasia: return "Eurasia"
                    }
                },
                description: "Determines the radio frequency band used for LTC Teams. Users in different zones cannot communicate."
            )
            .frame(
                maxWidth: .infinity,
                alignment: .top
            )
            .padding(
                .horizontal, 16
            )
        }
        .navigationTitle("LTC Zone")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                AppText("LTC Zone", style: .header3)
                    .foregroundStyle(Color("OnBackground"))
            }
        }
    }
}

#Preview {
    let session = HeadsetSession()
    NavigationStack {
        RegionsView()
            .environment(session)
            .environment(HeadsetSettingsSync(transport: session))
    }
}
