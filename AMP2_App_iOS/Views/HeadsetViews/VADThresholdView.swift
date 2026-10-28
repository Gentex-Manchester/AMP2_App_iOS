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
            VStack {
                Text("Determines the sensitivity of the microphone when VAD mode is enabled.")
                    .font(.ibmPlexSans(size: 18))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 16)

                VStack(spacing: 12) {
                    Slider(
                        value: Binding(
                            get: { level },
                            set: { draftLevel = $0 }
                        ),
                        in: 0...10,
                        step: 1,
                        onEditingChanged: { editing in
                            guard !editing, let draftLevel else { return }
                            if let byte = LTCLevel.byte(for: Int(draftLevel)) {
                                settings.write(.vadThreshold, value: byte)
                            }
                            self.draftLevel = nil
                        }
                    )
                    .tint(.opsCoreRed)
                    .padding(.horizontal, 16)

                    HStack {
                        Text("Low")
                            .font(.ibmPlexSans(size: 14))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(settings.settings.vadThreshold.map(String.init) ?? "—")
                            .font(.ibmPlexSans(size: 18, weight: .bold))
                        Spacer()
                        Text("High")
                            .font(.ibmPlexSans(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                }
            }
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
                    .font(.ibmPlexSans(size: 28, weight: .bold))
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
