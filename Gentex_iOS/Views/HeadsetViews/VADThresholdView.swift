//
//  VADThresholdView.swift
//  Gentex_iOS
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
                Text("Adjusts the sensitivity of the microphone when LTC is in VAD mode.")
                    .font(.ibmPlexSans(size: 18, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 50)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)

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
                    .padding(.horizontal, 30)

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
                    .padding(.horizontal, 30)
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)
        }
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
