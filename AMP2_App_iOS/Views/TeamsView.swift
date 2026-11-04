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
                label: { option in
                    switch option {
                    case .alpha: return "Alpha"
                    case .bravo: return "Bravo"
                    case .charlie: return "Charlie"
                    case .delta: return "Delta"
                    case .jointOps: return "Joint Ops"
                    }
                },
                description: "Determines who you can talk to with Local Teams Comms (LTC)."
            )
            .frame(
                maxWidth: .infinity,
                alignment: .top
            )
            .padding(
                .horizontal, 16
            )
        }
        .navigationTitle("Teams")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                AppText("Teams", style: .header3)
            }
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
