//
//  TeamsDetailsView.swift
//  Gentex_iOS
//
//  Create/edit form for a custom team.
//  Pass `team: nil` to create a new team, or an existing team to edit.
//

import SwiftUI

struct TeamsDetailsView: View {
    let existingTeam: Team?

    @Environment(\.dismiss) private var dismiss
    @Environment(HeadsetSession.self) private var session
    @Environment(HeadsetSettingsSync.self) private var headsetSettings
    @AppStorage("selectedRegion") private var selectedRegionRaw: String = Region.northAmerica.rawValue

    // MARK: - Form State

    @State private var name: String = ""
    @State private var region: Region = .northAmerica
    @State private var rfChannel: Int = 1
    @State private var networkIdText: String = "1"
    @State private var securityKey: String = "Mike"

    @State private var validationError: String?
    @State private var isSaving: Bool = false
    @State private var showQRExport = false
    @State private var showDeleteConfirmation = false
    @State private var showDiscardConfirmation = false
    @State private var isFavorited: Bool = false

    /// Existing teams open read-only until the pencil is tapped. Create is always editable.
    @State private var editModeActive = false

    // MARK: - Derived

    private var isExistingTeam: Bool { existingTeam != nil }

    /// `-1` when empty or non-numeric; 0 is a valid ID, so it can't be the sentinel.
    private var networkId: Int {
        Int(networkIdText) ?? -1
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && networkId >= 0 && networkId <= 255
            && !isSaving
    }

    /// Drives the discard prompt when leaving Edit Mode.
    private var hasChanges: Bool {
        guard let team = existingTeam else { return false }
        let originalRegion = Region(from: team.region) ?? .northAmerica
        return name != team.name
            || region != originalRegion
            || rfChannel != team.rfChannel
            || networkId != team.networkId
            || securityKey != team.securityKey
    }

    private var navigationTitle: String {
        if !isExistingTeam { return "New Team" }
        return editModeActive ? "Edit Team" : "Team Details"
    }

    private var settingsEnabled: Bool {
        !isExistingTeam || editModeActive
    }

    // MARK: - Headset

    /// Matches on live key, channel, and network ID. The predefined-team byte
    /// goes stale once a custom team overwrites those settings.
    private var isActiveOnHeadset: Bool {
        let live = headsetSettings.settings
        guard let liveKey = live.securityKey,
              let liveChannel = live.rfChannel,
              let liveNetworkId = live.networkId,
              let teamKey = SecurityKey(rawValue: securityKey) else { return false }

        return teamKey == liveKey && rfChannel == liveChannel && networkId == liveNetworkId
    }

    private var canJoin: Bool {
        session.state.isConnected && !isActiveOnHeadset
    }

    /// Writes key, channel, and network ID in the order Gentex documents.
    private func joinTeam() {
        guard let key = SecurityKey(rawValue: securityKey) else {
            validationError = "\"\(securityKey)\" is not a recognized security key."
            return
        }
        do {
            try headsetSettings.applyTeam(
                securityKey: key, rfChannel: rfChannel, networkId: networkId
            )
            validationError = nil
        } catch {
            validationError = error.localizedDescription
        }
    }

    private func resetForm() {
        guard let team = existingTeam else { return }
        name = team.name
        region = Region(from: team.region) ?? .northAmerica
        rfChannel = team.rfChannel
        networkIdText = String(team.networkId)
        securityKey = team.securityKey
        validationError = nil
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                
                VStack(spacing: 20) {
                    
                    teamNameField

                    VStack(alignment: .leading, spacing: 6) {
                        
                        Text("RF Channel")
                            .font(.ibmPlexSans(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(.bottom, 10)
                            .padding(.leading, 20)
                            
                        HStack(spacing: 10) {
                            Button(action: { rfChannel = 1 }) {
                                HStack {
                                    Spacer()
                                    Text("Channel 1")
                                        .font(.ibmPlexSans(size: 20))
                                    Spacer()
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 24)
                                .padding(.horizontal, 8)
                                .frame(maxWidth: .infinity)
                                .background(rfChannel == 1 ? Color.opsCoreRed : Color.opsCoreRed.opacity(0.50))
                                .cornerRadius(16)
                            }
                            .padding(.leading)
                            .padding(.bottom, 10)

                            Button(action: { rfChannel = 2 }) {
                                HStack {
                                    Spacer()
                                    Text("Channel 2")
                                        .font(.ibmPlexSans(size: 20))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                    Spacer()
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 24)
                                .padding(.horizontal, 6)
                                .frame(maxWidth: .infinity)
                                .background(rfChannel == 2 ? Color.opsCoreRed : Color.opsCoreRed.opacity(0.50))
                                .cornerRadius(16)
                            }
                            .padding(.trailing)
                            .padding(.bottom, 10)
                        }
                        
                        HStack(spacing: 10) {
                            Button(action: { rfChannel = 3 }) {
                                HStack {
                                    Spacer()
                                    Text("Channel 3")
                                        .font(.ibmPlexSans(size: 20))
                                    Spacer()
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 24)
                                .padding(.horizontal, 8)
                                .frame(maxWidth: .infinity)
                                .background(rfChannel == 3 ? Color.opsCoreRed : Color.opsCoreRed.opacity(0.50))
                                .cornerRadius(16)
                            }
                            .padding(.leading)
                            .padding(.bottom, 10)

                            Button(action: { rfChannel = 4 }) {
                                HStack {
                                    Spacer()
                                    Text("Channel 4")
                                        .font(.ibmPlexSans(size: 20))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                    Spacer()
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 24)
                                .padding(.horizontal, 6)
                                .frame(maxWidth: .infinity)
                                .background(rfChannel == 4 ? Color.opsCoreRed : Color.opsCoreRed.opacity(0.50))
                                .cornerRadius(16)
                            }
                            .padding(.trailing)
                            .padding(.bottom, 10)
                        }

                        HStack(spacing: 10) {
                            Button(action: { rfChannel = 5 }) {
                                HStack {
                                    Spacer()
                                    Text("Channel 5")
                                        .font(.ibmPlexSans(size: 20))
                                    Spacer()
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 24)
                                .padding(.horizontal)
                                .frame(maxWidth: .infinity)
                                .background(rfChannel == 5 ? Color.opsCoreRed : Color.opsCoreRed.opacity(0.50))
                                .cornerRadius(16)
                            }
                            .padding(.leading)

                            Spacer()
                                .frame(maxWidth: .infinity)
                                .padding(.trailing)
                        }
                        .padding(.bottom, 10)

                    }
                    .frame(maxWidth: .infinity, alignment: .top)
                    .disabled(!settingsEnabled)
                    
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Security Key")
                            .font(.ibmPlexSans(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(.bottom, 10)
                            .padding(.leading, 20)

                        HStack(spacing: 10) {
                            Button(action: { securityKey = "Mike" }) {
                                HStack {
                                    Spacer()
                                    Text("Mike")
                                        .font(.ibmPlexSans(size: 20))
                                    Spacer()
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 24)
                                .padding(.horizontal, 8)
                                .frame(maxWidth: .infinity)
                                .background(securityKey == "Mike" ? Color.opsCoreRed : Color.opsCoreRed.opacity(0.50))
                                .cornerRadius(16)
                            }
                            .padding(.leading)
                            .padding(.bottom, 10)

                            Button(action: { securityKey = "November" }) {
                                HStack {
                                    Spacer()
                                    Text("November")
                                        .font(.ibmPlexSans(size: 20))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                    Spacer()
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 24)
                                .padding(.horizontal, 6)
                                .frame(maxWidth: .infinity)
                                .background(securityKey == "November" ? Color.opsCoreRed : Color.opsCoreRed.opacity(0.50))
                                .cornerRadius(16)
                            }
                            .padding(.trailing)
                            .padding(.bottom, 10)
                        }
                        
                        HStack(spacing: 10) {
                            Button(action: { securityKey = "Oscar" }) {
                                HStack {
                                    Spacer()
                                    Text("Oscar")
                                        .font(.ibmPlexSans(size: 20))
                                    Spacer()
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 24)
                                .padding(.horizontal, 8)
                                .frame(maxWidth: .infinity)
                                .background(securityKey == "Oscar" ? Color.opsCoreRed : Color.opsCoreRed.opacity(0.50))
                                .cornerRadius(16)
                            }
                            .padding(.leading)
                            .padding(.bottom, 10)

                            Button(action: { securityKey = "Papa" }) {
                                HStack {
                                    Spacer()
                                    Text("Papa")
                                        .font(.ibmPlexSans(size: 20))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                    Spacer()
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 24)
                                .padding(.horizontal, 6)
                                .frame(maxWidth: .infinity)
                                .background(securityKey == "Papa" ? Color.opsCoreRed : Color.opsCoreRed.opacity(0.50))
                                .cornerRadius(16)
                            }
                            .padding(.trailing)
                            .padding(.bottom, 10)
                        }
                        
                        HStack(spacing: 10) {
                            Button(action: { securityKey = "Quebec" }) {
                                HStack {
                                    Spacer()
                                    Text("Quebec")
                                        .font(.ibmPlexSans(size: 20))
                                    Spacer()
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 24)
                                .padding(.horizontal, 8)
                                .frame(maxWidth: .infinity)
                                .background(securityKey == "Quebec" ? Color.opsCoreRed : Color.opsCoreRed.opacity(0.50))
                                .cornerRadius(16)
                            }
                            .padding(.leading)
                            .padding(.bottom, 10)

                            Button(action: { securityKey = "Romeo" }) {
                                HStack {
                                    Spacer()
                                    Text("Romeo")
                                        .font(.ibmPlexSans(size: 20))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                    Spacer()
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 24)
                                .padding(.horizontal, 6)
                                .frame(maxWidth: .infinity)
                                .background(securityKey == "Romeo" ? Color.opsCoreRed : Color.opsCoreRed.opacity(0.50))
                                .cornerRadius(16)
                            }
                            .padding(.trailing)
                            .padding(.bottom, 10)
                        }
                        
                        HStack(spacing: 10) {
                            Button(action: { securityKey = "Sierra" }) {
                                HStack {
                                    Spacer()
                                    Text("Sierra")
                                        .font(.ibmPlexSans(size: 20))
                                    Spacer()
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 24)
                                .padding(.horizontal, 8)
                                .frame(maxWidth: .infinity)
                                .background(securityKey == "Sierra" ? Color.opsCoreRed : Color.opsCoreRed.opacity(0.50))
                                .cornerRadius(16)
                            }
                            .padding(.leading)
                            .padding(.bottom, 10)

                            Button(action: { securityKey = "Tango" }) {
                                HStack {
                                    Spacer()
                                    Text("Tango")
                                        .font(.ibmPlexSans(size: 20))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                    Spacer()
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 24)
                                .padding(.horizontal, 6)
                                .frame(maxWidth: .infinity)
                                .background(securityKey == "Tango" ? Color.opsCoreRed : Color.opsCoreRed.opacity(0.50))
                                .cornerRadius(16)
                            }
                            .padding(.trailing)
                            .padding(.bottom, 10)
                        }
                        
                        HStack(spacing: 10) {
                            Button(action: { securityKey = "Uniform" }) {
                                HStack {
                                    Spacer()
                                    Text("Uniform")
                                        .font(.ibmPlexSans(size: 20))
                                    Spacer()
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 24)
                                .padding(.horizontal, 8)
                                .frame(maxWidth: .infinity)
                                .background(securityKey == "Uniform" ? Color.opsCoreRed : Color.opsCoreRed.opacity(0.50))
                                .cornerRadius(16)
                            }
                            .padding(.leading)
                            .padding(.bottom, 10)

                            Button(action: { securityKey = "Victor" }) {
                                HStack {
                                    Spacer()
                                    Text("Victor")
                                        .font(.ibmPlexSans(size: 20))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                    Spacer()
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 24)
                                .padding(.horizontal, 6)
                                .frame(maxWidth: .infinity)
                                .background(securityKey == "Victor" ? Color.opsCoreRed : Color.opsCoreRed.opacity(0.50))
                                .cornerRadius(16)
                            }
                            .padding(.trailing)
                            .padding(.bottom, 10)
                        }
                    }
                    .disabled(!settingsEnabled)

                    
                    formFields

                    // MARK: Bottom Button Group

                    if isExistingTeam {
                        if editModeActive {
                            Button {
                                saveTeam()
                            } label: {
                                Text(isSaving ? "Saving…" : "Save Changes")
                                    .font(.ibmPlexSans(size: 20))
                                    .foregroundColor(.white)
                                    .padding(.vertical, 16)
                                    .frame(maxWidth: .infinity)
                                    .background(canSave ? Color.opsCoreRed : Color.opsCoreRed.opacity(0.50))
                                    .cornerRadius(16)
                            }
                            .disabled(!canSave)
                            .padding(.top, 20)
                        } else {
                            // View mode: join and share.
                            HStack(spacing: 12) {
                                Button {
                                    joinTeam()
                                } label: {
                                    Text(isActiveOnHeadset ? "Active" : "Join team")
                                        .font(.ibmPlexSans(size: 20))
                                        .foregroundColor(.white)
                                        .padding(.vertical, 16)
                                         .frame(maxWidth: .infinity)
                                        .background(
                                            canJoin ? Color.opsCoreRed : Color.opsCoreRed.opacity(0.50)
                                        )
                                        .cornerRadius(16)
                                }
                                .disabled(!canJoin)

                                Button {
                                    showQRExport = true
                                } label: {
                                    Image("share_48px")
                                        .renderingMode(.template)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 24, height: 24)
                                        .foregroundColor(.opsCoreRed)
                                        .padding(.vertical, 16)
                                        .padding(.horizontal, 24)
                                        .background(Color(.systemGray5))
                                        .cornerRadius(16)
                                }
                            }
                            .padding(.top, 20)
                        }
                    } else {
                        Button {
                            saveTeam()
                        } label: {
                            Text(isSaving ? "Saving…" : "Save")
                                .font(.ibmPlexSans(size: 20))
                                .foregroundColor(.white)
                                .padding(.vertical, 16)
                                .frame(maxWidth: .infinity)
                                .background(canSave ? Color.opsCoreRed : Color.opsCoreRed.opacity(0.50))
                                .cornerRadius(16)
                        }
                        .disabled(!canSave)
                        .padding(.top, 20)
                    }
                }
                .padding(.horizontal, 20)
            }
            .alert("Are you sure?", isPresented: $showDiscardConfirmation) {
                Button("Discard Changes", role: .destructive) {
                    resetForm()
                    editModeActive = false
                }
                Button("Keep Editing", role: .cancel) {}
            } message: {
                Text("Your unsaved changes will be lost.")
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 12) {
                        Spacer()

                        Text(navigationTitle)
                            .font(.ibmPlexSans(size: 28, weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)

                        Spacer()

                        if isExistingTeam && !editModeActive {
                            HStack(spacing: 16) {
                                Button {
                                    toggleFavorite()
                                } label: {
                                    Image(isFavorited ? "star_filled" : "star_empty")
                                        .renderingMode(.template)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 24, height: 24)
                                        .foregroundColor(isFavorited ? .yellow : .opsCoreRed)
                                }
                                Button {
                                    editModeActive = true
                                } label: {
                                    Image("edit_48px")
                                        .renderingMode(.template)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 24, height: 24)
                                        .foregroundColor(.opsCoreRed)
                                }
                                Button {
                                    showDeleteConfirmation = true
                                } label: {
                                    Image("delete_48px")
                                        .renderingMode(.template)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 24, height: 24)
                                        .foregroundColor(.opsCoreRed)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                if isExistingTeam && editModeActive {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            exitEditModeTapped()
                        } label: {
                            Image("close_48px")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.opsCoreRed)
                        }
                    }
                }
            }
            .navigationBarBackButtonHidden(isExistingTeam && editModeActive)
            .sheet(isPresented: $showQRExport) {
                if let team = existingTeam {
                    NavigationStack {
                        QRExportView(team: team)
                    }
                    .presentationCornerRadius(16)
                }
            }
            .alert("Delete Team", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    deleteTeam()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this team?")
            }
        }
    }

    // MARK: - Team Name Field

    private var teamNameField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Team Name")
                .font(.ibmPlexSans(size: 18, weight: .bold))
                .foregroundColor(.primary)

            TextField("Enter team name", text: $name)
                .font(.ibmPlexSans(size: 20))
                .padding(.vertical, 15)
                .padding(.horizontal, 12)
                .background(Color(.systemGray5))
                .cornerRadius(16)
        }
        .disabled(!settingsEnabled)
        .padding(.horizontal, 20)
    }

    // MARK: - Form Fields

    private var formFields: some View {
        
        VStack(spacing: 16) {

            VStack(alignment: .leading, spacing: 6) {
                Text("Network ID")
                    .font(.ibmPlexSans(size: 18, weight: .bold))
                    .foregroundColor(.primary)

                TextField("0–255", text: $networkIdText)
                    .font(.ibmPlexSans(size: 20))
                    .keyboardType(.numberPad)
                    .padding(.vertical, 15)
                    .padding(.horizontal, 12)
                    .background(Color(.systemGray5))
                    .cornerRadius(16)

                if !networkIdText.isEmpty && (networkId < 0 || networkId > 255) {
                    Text("Network ID must be between 0 and 255.")
                        .font(.ibmPlexSans(size: 14))
                        .foregroundColor(.opsCoreRed)
                }
            }
            
            if let error = validationError {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.opsCoreRed)
                    Text(error)
                        .font(.ibmPlexSans(size: 14))
                        .foregroundColor(.opsCoreRed)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.opsCoreRed.opacity(0.10))
                .cornerRadius(16)
            }
        }
        .disabled(!settingsEnabled)
        .padding(.horizontal, 20)
    }

    // MARK: - Edit Mode

    private func exitEditModeTapped() {
        if hasChanges {
            showDiscardConfirmation = true
        } else {
            editModeActive = false
        }
    }

    // MARK: - Favorite

    private func toggleFavorite() {
        guard let team = existingTeam else { return }
        do {
            let updated = try TeamStore.shared.toggleFavorite(team.id)
            isFavorited = updated.isFavorited
        } catch {
            validationError = error.localizedDescription
        }
    }

    // MARK: - Delete

    private func deleteTeam() {
        guard let team = existingTeam else { return }
        validationError = nil
        isSaving = true

        do {
            try TeamStore.shared.delete(team.id)
            dismiss()
        } catch let error as DatabaseError {
            validationError = error.localizedDescription
            isSaving = false
        } catch {
            validationError = error.localizedDescription
            isSaving = false
        }
    }

    // MARK: - Save

    private func saveTeam() {
        validationError = nil
        isSaving = true

        let team = Team(
            id: existingTeam?.id ?? 0,
            region: region.rawValue,
            rfChannel: rfChannel,
            securityKey: securityKey,
            customSecurityKey: nil,
            networkId: networkId,
            name: name.trimmingCharacters(in: .whitespaces),
            isFavorited: isFavorited,
            isLocked: existingTeam?.isLocked ?? false
        )

        do {
            if isExistingTeam {
                _ = try TeamStore.shared.update(team, in: region)
            } else {
                _ = try TeamStore.shared.create(team, in: region)
            }
            dismiss()
        } catch let error as DatabaseError {
            validationError = error.localizedDescription
            isSaving = false
        } catch {
            validationError = error.localizedDescription
            isSaving = false
        }
    }

    // MARK: - Init

    init(team: Team? = nil) {
        self.existingTeam = team

        if let team = team {
            _name = State(initialValue: team.name)
            _region = State(initialValue: Region(from: team.region) ?? .northAmerica)
            _rfChannel = State(initialValue: team.rfChannel)
            _networkIdText = State(initialValue: String(team.networkId))
            _securityKey = State(initialValue: team.securityKey)
            _isFavorited = State(initialValue: team.isFavorited)
        } else {
            // New teams default to the persisted operating region.
            let stored = UserDefaults.standard.string(forKey: "selectedRegion")
            _region = State(initialValue: Region(rawValue: stored ?? "") ?? .northAmerica)
        }
    }
}

#Preview("Create New Team") {
    let session = HeadsetSession()
    let sync = HeadsetSettingsSync(transport: session)
    TeamsDetailsView(team: nil)
        .environment(session)
        .environment(sync)
}

#Preview("Edit Existing Team") {
    let session = HeadsetSession()
    let sync = HeadsetSettingsSync(transport: session)
    TeamsDetailsView(team: Team(
        id: 1,
        region: Region.northAmerica.rawValue,
        rfChannel: 3,
        securityKey: "MIKE",
        networkId: 42,
        name: "Alpha Squad",
        isFavorited: true,
        isLocked: false
    ))
        .environment(session)
        .environment(sync)
}
