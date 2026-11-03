//
//  TeamsView.swift
//  AMP2_App_iOS
//

import SwiftUI

struct TeamsView: View {
    @Environment(HeadsetSession.self) private var session
    @Environment(HeadsetSettingsSync.self) private var settings
    
    var body: some View {
        ScrollView {
            let selectedTeam = settings.settings.team
            
            VStack(spacing: 10) {
                Text("Determines who you can talk to with Local Teams Comms (LTC).")
                    .font(.ibmPlexSans(size: 18))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 16)
                
                HStack(spacing: 10){
                    SelectionButton(
                        label: "Alpha",
                        enabled: session.state.isConnected,
                        selected: selectedTeam == Team.alpha,
                        action: { settings.write(LTCSetting.team, value: Team.alpha.rawValue) }
                    )
                    
                    SelectionButton(
                        label: "Bravo",
                        enabled: session.state.isConnected,
                        selected: selectedTeam == Team.bravo,
                        action: { settings.write(LTCSetting.team, value: Team.bravo.rawValue) }
                    )
                }
                
                HStack(spacing: 10) {
                    SelectionButton(
                        label: "Charlie",
                        enabled: session.state.isConnected,
                        selected: selectedTeam == Team.charlie,
                        action: { settings.write(LTCSetting.team, value: Team.charlie.rawValue) }
                    )

                    SelectionButton(
                        label: "Delta",
                        enabled: session.state.isConnected,
                        selected: selectedTeam == Team.delta,
                        action: { settings.write(LTCSetting.team, value: Team.delta.rawValue) }
                    )
                }
                
                HStack(spacing: 10) {
                    SelectionButton(
                        label: "Joint Ops",
                        enabled: session.state.isConnected,
                        selected: selectedTeam == Team.jointOps,
                        action: { settings.write(LTCSetting.team, value: Team.jointOps.rawValue) }
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
        .navigationTitle("Teams")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Teams")
                    .font(.ibmPlexSans(size: 28, weight: .bold))
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
