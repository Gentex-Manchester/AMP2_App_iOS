//
//  RegionsView.swift
//  Gentex_iOS
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

    @AppStorage("selectedRegion") private var selectedRegionRaw: String = Region.northAmerica.rawValue

    /// The headset's reported zone wins over the stored preference.
    private var activeRegion: Region {
        settings.settings.zone ?? Region(rawValue: selectedRegionRaw) ?? .northAmerica
    }

    var body: some View {
        ScrollView {
            VStack {
                Text("The region you're operating in. Determines which teams are available and which settings are available when creating custom teams.")
                    .font(.ibmPlexSans(size: 18, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 50)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)

                VStack(spacing: 10) {
                    ForEach(Region.allCases, id: \.self) { region in
                        regionButton(region)
                    }
                }
                .padding(.horizontal, 20)
            }
            .frame(maxWidth: .infinity, alignment: .top)
        }
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
