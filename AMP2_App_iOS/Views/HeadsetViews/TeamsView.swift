//
//  TeamsView.swift
//  AMP2_App_iOS
//
//  Displays persisted custom teams, built-in headset teams (placeholder),
//  and provides access to team creation, editing, and QR import/export.
//

import SwiftUI

struct TeamsView: View {
    @AppStorage("selectedRegion") private var selectedRegionRaw: String = Region.northAmerica.rawValue
    
    @Environment(HeadsetSession.self) private var session
    @Environment(HeadsetSettingsSync.self) private var headsetSettings
    

    private func joinPreset(_ preset: Team) {
        guard session.state.isConnected else {
            return
        }
        do {
            try headsetSettings.applyTeam(preset: preset)
        } catch { }
    }
    
    private var selectedRegion: Region {
        Region(rawValue: selectedRegionRaw) ?? .northAmerica
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            if (session.state.isConnected) {
                let selectedTeam = headsetSettings.settings.activePredefinedTeam
                
                VStack(spacing: 10) {
                    Text("Determines who you can talk to with Local Teams Comms (LTC).")
                        .font(.ibmPlexSans(size: 18))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 16)
                        .padding(.bottom, 16)
                    
                    HStack(spacing: 10){
                        SelectionButton(
                            label: "Alpha",
                            selected: selectedTeam == Team.alpha,
                            action: { joinPreset(Team.alpha) }
                        )
                        
                        SelectionButton(
                            label: "Bravo",
                            selected: selectedTeam == Team.bravo,
                            action: { joinPreset(Team.bravo) }
                        )
                    }
                    
                    HStack(spacing: 10) {
                        SelectionButton(
                            label: "Charlie",
                            selected: selectedTeam == Team.charlie,
                            action: { joinPreset(Team.charlie) }
                        )

                        SelectionButton(
                            label: "Delta",
                            selected: selectedTeam == Team.delta,
                            action: { joinPreset(Team.delta) }
                        )
                    }
                    
                    HStack(spacing: 10) {
                        SelectionButton(
                            label: "Joint Ops",
                            selected: selectedTeam == Team.jointOps,
                            action: { joinPreset(Team.jointOps) }
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
    TeamsView()
        .environment(session)
        .environment(sync)
}
