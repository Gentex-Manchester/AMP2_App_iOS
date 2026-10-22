//
//  TeamsView.swift
//  AMP2_App_iOS
//
//  Displays persisted custom teams, built-in headset teams (placeholder),
//  and provides access to team creation, editing, and QR import/export.
//

import SwiftUI

struct TeamsView: View {
    @State private var customTeams: [Team] = []
    @State private var favoriteTeams: [Team] = []
    @State private var showQRImport = false
    @State private var showCreateTeam = false
    @State private var joinError: String?

    /// A failed read, kept distinct from an empty team list.
    @State private var loadError: Error?
    /// Currently always nil: deleting and favoriting moved to the team page.
    /// Kept for the next store write on this screen.
    @State private var operationError: Error?
    @AppStorage("selectedRegion") private var selectedRegionRaw: String = Region.northAmerica.rawValue

    /// Favorited built-in teams by display name; presets live in firmware, not
    /// the DB (Android: `PresetFavoritesRepository`). Read-only on iOS, since a
    /// built-in team has no page to favorite it from.
    @AppStorage("favoritePresetTeams") private var favoritePresetsRaw: String = ""

    @Environment(HeadsetSession.self) private var session
    @Environment(HeadsetSettingsSync.self) private var headsetSettings

    private var favoritePresets: Set<String> {
        Set(favoritePresetsRaw.split(separator: "\n").map(String.init))
    }

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
            joinError = "Connect a headset to join a team."
            return
        }
        do {
            try headsetSettings.applyTeam(
                securityKey: securityKey, rfChannel: rfChannel, networkId: networkId
            )
            joinError = nil
        } catch {
            joinError = error.localizedDescription
        }
    }

    private var selectedRegion: Region {
        Region(rawValue: selectedRegionRaw) ?? .northAmerica
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    titleSection
                    errorSection
                    favoritesSection
                    builtInTeamsSection
                    customTeamsSection
                    Spacer(minLength: 40)
                }
                .padding(.horizontal)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showQRImport = true
                    } label: {
                        Image("qr_code")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.opsCoreRed)
                    }
                }
            }
            .sheet(isPresented: $showQRImport) {
                NavigationStack {
                    QRImportView {
                        refreshTeams()
                    }
                }
                // The system default is smaller and continuous; match the 16pt circular corners.
                .presentationCornerRadius(16)
            }
            .onAppear {
                refreshTeams()
            }
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

    // MARK: - Errors

    @ViewBuilder
    private var errorSection: some View {
        if let loadError {
            ErrorBanner(title: "Couldn't load your teams", error: loadError) {
                refreshTeams()
            }
            .padding(.bottom, 12)
        }

        if let operationError {
            ErrorBanner(title: "That didn't work", error: operationError)
                .padding(.bottom, 12)
        }

        if let joinError {
            ErrorBanner(title: "Couldn't join team", message: joinError)
                .padding(.bottom, 12)
        }

    }

    // MARK: - Favorites

    private var favoritesSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image("star_filled")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)

                Text("Favorited Teams")
                    .font(.ibmPlexSans(size: 18, weight: .bold))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 20)
            .padding(.bottom, 8)

            if favoriteTeams.isEmpty {
                Text("No favorited teams")
                    .font(.ibmPlexSans(size: 16))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
            } else {
                ForEach(favoriteTeams) { team in
                    teamRow(team)
                }
            }
        }
    }

    // MARK: - Built-in Teams

    private var builtInTeamsSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image("headset")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)

                Text("Teams built into the headset")
                    .font(.ibmPlexSans(size: 18, weight: .bold))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 20)
            .padding(.bottom, 8)

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
                if favoritePresets.contains(preset.displayName) {
                    Image("star_filled")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .foregroundColor(.yellow)
                }

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

    // MARK: - Custom Teams

    private var customTeamsSection: some View {
        VStack(spacing: 0) {
            Text("Teams saved in this application")
                .font(.ibmPlexSans(size: 18, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 20)
                .padding(.bottom, 8)

            ForEach(customTeams) { team in
                teamRow(team)
            }

            Button {
                showCreateTeam = true
            } label: {
                HStack {
                    Text("Add New Team")
                        .font(.ibmPlexSans(size: 20))
                    Spacer()
                    Image(systemName: "plus")
                }
                .foregroundColor(.primary)
                .padding(.vertical, 16)
                .padding(.horizontal)
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray4))
                .cornerRadius(16)
            }
            .padding(.top, 8)
            .navigationDestination(isPresented: $showCreateTeam) {
                TeamsDetailsView(team: nil)
            }
        }
    }

    // MARK: - Team Row

    private func teamRow(_ team: Team) -> some View {
        NavigationLink {
            if team.isLocked {
                LockedTeamDetailsView(team: team)
            } else {
                TeamsDetailsView(team: team)
            }
        } label: {
            HStack {
                if team.isFavorited {
                    Image("star_filled")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .foregroundColor(.yellow)
                }

                Text(team.name)
                    .font(.ibmPlexSans(size: 20))

                Spacer()

                if isActive(team) {
                    Text("Active")
                        .font(.ibmPlexSans(size: 14, weight: .bold))
                        .foregroundColor(.opsCoreRed)
                }

                Image(systemName: "chevron.right")
            }
            .foregroundColor(.primary)
            .padding(.vertical, 16)
            .padding(.horizontal)
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray4))
            .cornerRadius(16)
        }
        // Same spacing as presetRow.
        .padding(.bottom, 8)
    }

    // MARK: - Actions

    private func refreshTeams() {
        do {
            let all = try TeamStore.shared.fetchAll()
            customTeams = all
            favoriteTeams = all.filter { $0.isFavorited }
            loadError = nil
        } catch {
            // Keep the stale list; blanking it would claim there are no teams.
            loadError = error
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
