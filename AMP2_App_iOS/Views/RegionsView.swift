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
            let selectedZone = headsetSettings.settings.zone
            
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
                description: "Determines how LTC communications are encrypted."
            )
            .frame(
                maxWidth: .infinity,
                alignment: .top
            )
            .padding(
                .horizontal, 16
            )
        }
        .navigationTitle("Region")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Region")
                    .font(.ibmPlexSans(size: 28, weight: .bold))
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
