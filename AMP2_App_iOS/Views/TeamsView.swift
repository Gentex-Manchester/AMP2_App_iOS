//
//  TeamsView.swift
//  AMP2_App_iOS
//

import SwiftUI

struct TeamsView: View {
    @Environment(HeadsetSession.self) private var session
    @Environment(HeadsetSettingsSync.self) private var headsetSettings
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                SelectionButtonRow(
                    options: Team.allCases,
                    selection: Binding(
                            get: {
                                headsetSettings.settings.team ?? Team.jointOps
                            },
                            set: { selection in
                                headsetSettings.write(
                                    LTCSetting.team,
                                    value: selection.rawValue
                                )
                            }
                        ),
                    onSelection: { selection in
                        headsetSettings.write(LTCSetting.team, value: selection.rawValue)
                    },
                    label: { option in option.displayName },
                    description: String(localized: "Determines who you can talk to with Local Teams Comms (LTC).")
                )
                .frame(maxWidth: .infinity)
                
                Spacer(minLength: -8) // Visually improves spacing on this screen
                
                regionView
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                TroubleshootingPopup(
                    title: String(localized: "I’m on the same team as another user, but can’t hear them."),
                    text: String(localized: "Make sure that your LTC Key and Region settings match. These settings must match between users who want to talk using LTC. Note that commercial headsets cannot adjust the LTC Region setting.")
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
        }
        .navigationTitle("Teams")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Teams")
                    .appTextStyle(.header3)
            }
        }
    }
    
    @ViewBuilder
    var regionView: some View {
        switch headsetSettings.settings.zone {
        case .americas:
            Text("Region: Americas (North America & South America)")
                .appTextStyle(.body)
                .foregroundStyle(Color("OnBackground"))
        case .eurasia:
            Text("Region: Eurasia (Europe & Asia)")
                .appTextStyle(.body)
                .foregroundStyle(Color("OnBackground"))
            Text("Note that team Delta is not approved for use in Japanese territories.")
                .appTextStyle(.subbody)
                .foregroundStyle(Color("OnBackground"))
        default:
            Text("No region detected")
                .appTextStyle(.body)
                .foregroundStyle(Color("OnBackground"))
        }
    }
}

#Preview {
    let session = HeadsetSession()
    let sync = HeadsetSettingsSync(transport: session)
    NavigationStack {
        TeamsView()
            .environment(session)
            .environment(sync)
    }
}
