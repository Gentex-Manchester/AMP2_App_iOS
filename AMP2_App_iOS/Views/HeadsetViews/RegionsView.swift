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
    @Environment(HeadsetSettingsSync.self) private var settings
    @Environment(HeadsetSession.self) private var session

    @AppStorage("selectedRegion") private var selectedRegionRaw: String = Region.americas.rawValue

    /// The headset's reported zone wins over the stored preference.
    private var activeRegion: Region {
        settings.settings.zone ?? Region(rawValue: selectedRegionRaw) ?? .americas
    }

    var body: some View {
        ScrollView {
            if (session.state.isConnected) {
                let selectedZone = settings.settings.zone
                
                VStack(spacing: 10) {
                    Text("Determines the radio frequency band used for LTC Teams. Users in different zones cannot communicate.")
                        .font(.ibmPlexSans(size: 18))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 16)
                    
                    HStack(spacing: 10){
                        SelectionButton(
                            label: "Americas",
                            selected: selectedZone == Region.americas,
                            action: { settings.write(LTCSetting.zone, value: Region.americas.ltcByte) }
                        )
                        
                        SelectionButton(
                            label: "Eurasia",
                            selected: selectedZone == Region.eurasia,
                            action: { settings.write(LTCSetting.zone, value: Region.eurasia.ltcByte) }
                        )
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

    private func regionButton(_ region: Region) -> some View {
        Button {
            // Always stored, so it survives a disconnect and drives validation.
            selectedRegionRaw = region.rawValue
            if session.state.isConnected {
                settings.write(.zone, value: region.ltcByte)
            }
        } label: {
            Text(region.displayName)
                .font(.ibmPlexSans(size: 20))
                .foregroundColor(.white)
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity)
                .background(activeRegion == region ? Color.opsCoreRed : Color.opsCoreRed.opacity(0.50))
                .cornerRadius(16)
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
