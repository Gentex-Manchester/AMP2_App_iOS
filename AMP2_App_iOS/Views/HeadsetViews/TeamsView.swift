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
            VStack(spacing: 0) {
                if session.state.isConnected {
                    ForEach(Team.allCases, id: \.self) { preset in
                        presetRow(preset)
                    }
                } else {
                    Button(action: {}) {
                        HStack {
                            Text("Headset not connected")
                                .font(.ibmPlexSans(size: 20))
                            Spacer()
                        }
                        .foregroundColor(Color(.systemGray4))
                        .padding(.vertical, 16)
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity)
                        .background(Color(.gray))
                        .cornerRadius(16)
                    }
                    .disabled(true)
                }
            }
            .padding(.horizontal)
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
    
    /// A built-in team. Joining writes the same three settings as a custom team.
    private func presetRow(_ preset: Team) -> some View {
        let isActive = headsetSettings.settings.activePredefinedTeam == preset
        
        return Button {
            joinPreset(preset)
        } label: {
            HStack {
                Text(preset.displayName)
                    .font(.ibmPlexSans(size: 20))
                
                Spacer()
                
                if isActive {
                    Text("Active")
                        .font(.ibmPlexSans(size: 14, weight: .bold))
                        .foregroundColor(.opsCoreRed)
                }
            }
            .foregroundColor(.primary)
            .padding(.vertical, 16)
            .padding(.horizontal)
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray4))
            .cornerRadius(16)
        }
        .padding(.bottom, 8)
    }
}

#Preview {
    let session = HeadsetSession()
    let sync = HeadsetSettingsSync(transport: session)
    TeamsView()
        .environment(session)
        .environment(sync)
}
