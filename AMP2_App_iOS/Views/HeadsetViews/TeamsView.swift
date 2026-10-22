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
    
    /// Matches on live key, channel, and network ID. The predefined-team byte
    /// goes stale once a custom team overwrites those settings.
    private func isActive(_ team: Team) -> Bool {
        let live = headsetSettings.settings
        guard let key = live.securityKey,
              let channel = live.rfChannel,
              let networkId = live.networkId,
              let teamKey = SecurityKey(rawValue: team.securityKey) else { return false }
        
        return teamKey == key && team.rfChannel == channel && team.networkId == networkId
    }
    
    private func joinPreset(_ preset: PredefinedTeam) {
        join(securityKey: preset.securityKey, rfChannel: preset.rfChannel, networkId: preset.networkId)
    }
    
    /// Writes key, channel, and network ID to the headset.
    private func join(securityKey: SecurityKey, rfChannel: Int, networkId: Int) {
        guard session.state.isConnected else {
            return
        }
        do {
            try headsetSettings.applyTeam(
                securityKey: securityKey, rfChannel: rfChannel, networkId: networkId
            )
        } catch { }
    }
    
    private var selectedRegion: Region {
        Region(rawValue: selectedRegionRaw) ?? .northAmerica
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                titleSection
                builtInTeamsSection
                Spacer(minLength: 40)
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Title
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            // No spinner: joins are optimistic, so the Active badge moves on tap.
            Text("Your Teams")
                .font(.ibmPlexSans(size: 28, weight: .bold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }
    
    // MARK: - Built-in Teams
    
    private var builtInTeamsSection: some View {
        VStack(spacing: 0) {
            if session.state.isConnected {
                ForEach(PredefinedTeam.allCases, id: \.self) { preset in
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
    }
    
    /// A built-in team. Joining writes the same three settings as a custom team.
    private func presetRow(_ preset: PredefinedTeam) -> some View {
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
