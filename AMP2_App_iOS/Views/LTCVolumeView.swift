//
//  LTCVolumeView.swift
//  AMP2_App_iOS
//
//  LTC volume (setting 0x08), 0–10.
//

import SwiftUI

struct LTCVolumeView: View {
    @Environment(HeadsetSettingsSync.self) private var settings

    /// Local while dragging so the poll loop doesn't fight the slider; written on release.
    @State private var draftLevel: Double?

    private var level: Double {
        draftLevel ?? Double(settings.settings.ltcVolume ?? 0)
    }

    var body: some View {
        ScrollView {
            SelectionSlider(
                level: level,
                range: 0...10,
                onSelection: { selection in
                    if let byte = LTCLevel.byte(for: Int(selection)) {
                        settings.write(.ltcVolume, value: byte)
                    }
                },
                label: { selection in
                    "\(selection)"
                },
                description: "Determines how loudly audio from the LTC module is played compared to other audio sources on the headset.",
                lowLabel: "Quiet",
                highLabel: "Loud"
            )
            .frame(
                maxWidth: .infinity,
                alignment: .top
            )
            .padding(
                .horizontal, 16
            )
        }
        .navigationTitle("LTC Volume")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                AppText("LTC Volume", style: .header3)
                    .foregroundStyle(Color("OnBackground"))
            }
        }
    }
}

#Preview {
    let session = HeadsetSession()
    NavigationStack {
        LTCVolumeView()
            .environment(HeadsetSettingsSync(transport: session))
    }
}
