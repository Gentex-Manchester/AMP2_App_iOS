//
//  VADThresholdView.swift
//  AMP2_App_iOS
//
//  VAD/VOX microphone sensitivity (setting 0x06), 0–10.
//
//  Reached from the bottom of the Headset screen, and only while VOX/VAD is the
//  selected LTC mode, per Peter's 07/07/2026 mock-ups.
//

import SwiftUI

struct VADThresholdView: View {
    @Environment(HeadsetSettingsSync.self) private var settings

    /// Local while dragging so the poll loop doesn't fight the slider; written on release.
    @State private var draftLevel: Double?

    private var level: Double {
        draftLevel ?? Double(settings.settings.vadThreshold ?? 0)
    }

    var body: some View {
        ScrollView {
            SelectionSlider(
                level: level,
                range: 0...10,
                onSelection: { selection in
                    if let byte = LTCLevel.byte(for: Int(selection)) {
                        settings.write(.vadThreshold, value: byte)
                    }
                },
                label: { selection in
                    settings.settings.vadThreshold.map(String.init) ?? "—"
                },
                description: String(localized: "Determines the sensitivity of the microphone when VAD mode is enabled."),
                lowLabel: String(localized: "Low"),
                highLabel: String(localized: "High")
            )
            .frame(
                maxWidth: .infinity,
                alignment: .top
            )
            .padding(
                .horizontal, 16
            )
        }
        .navigationTitle("VAD Threshold")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("VAD Threshold")
                    .appTextStyle(.header3)
                    .foregroundStyle(Color("OnBackground"))
            }
        }
    }
}

#Preview {
    let session = HeadsetSession()
    NavigationStack {
        VADThresholdView()
            .environment(HeadsetSettingsSync(transport: session))
    }
}
