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
            VStack {
                Text("Determines how loudly audio from the LTC module is played compared to other audio sources on the headset.")
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
                                settings.write(.ltcVolume, value: byte)
                            }
                            self.draftLevel = nil
                        }
                    )
                    .tint(.opsCoreRed)
                    .padding(.horizontal, 16)

                    HStack {
                        Text("Quiet")
                            .font(.ibmPlexSans(size: 14))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(settings.settings.ltcVolume.map(String.init) ?? "—")
                            .font(.ibmPlexSans(size: 18, weight: .bold))
                        Spacer()
                        Text("Loud")
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
        .navigationTitle("LTC Volume")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("LTC Volume")
                    .font(.ibmPlexSans(size: 28, weight: .bold))
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
