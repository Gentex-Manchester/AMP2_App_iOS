//
//  HeadsetView.swift
//  AMP2_App_iOS
//
//  The Headset tab while connected: live settings, written back on change.
//  Per the July 7, 2026 mock-ups, LTC Mode is inline and VAD Threshold shows
//  only in VOX/VAD mode.
//

import SwiftUI

struct ConnectedView: View {
    @Environment(HeadsetSettingsSync.self) private var settings
    @Environment(HeadsetSession.self) private var session
    
    var body: some View {
        let disabledBg = MediaItem(
            name: "enabled_bg_texture",
            type: .gif,
        )
        
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            
            HeroLayout(
                primaryContent: {
                    if (isLandscape) {
                        Spacer()
                            .frame(height: 40)
                    }
                    headerSection
                    if (isLandscape) {
                        Spacer()
                            .frame(height: 32)
                    }
                },
                secondaryContent: {
                    VStack(spacing: 16) {
                        ltcModeSection
                        settingsLinks
                    }
                },
                primaryContentBg: disabledBg,
                isLandscape: isLandscape
            )
        }
        .navigationTitle("My AMP®")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                // Not visible to user but needed for navigation
                Text("My AMP®")
                    .appTextStyle(.header3)
                    .foregroundStyle(.clear)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    AppSettingsView()
                } label: {
                    Image("settings_24px")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
            }
        }
    }

    // MARK: - Header

    // TODO: Adjust content based on current headset PN
    private var headerSection: some View {
        VStack(spacing: 0) {
            Image("headset_tan")
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 250)
            
            Spacer()
            
            Image("ops_core_logo")
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 35)

            Text("AMP 2.0 Elite")
                .appTextStyle(.header1)
                .foregroundStyle(Color("OnBackground"))
            
            Spacer()
        }
    }

    // MARK: - LTC Mode

    /// Inline per the 07/07 mock-ups.
    private var ltcModeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("LTC Mode")
                .appTextStyle(.header3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .foregroundStyle(Color("OnBackground"))

            HStack(spacing: 10) {
                ForEach(LTCMode.allCases, id: \.self) { mode in
                    SelectionButton(
                        label: mode.displayName,
                        selected: settings.settings.ltcMode == mode,
                        action: {
                            settings.write(.ltcMode, value: mode.rawValue)
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Setting Links

    private var settingsLinks: some View {
        VStack(spacing: 16) {
            if settings.settings.ltcMode == .vad {
                SettingRow(title: LTCSetting.vadThreshold.displayName) {
                    VADThresholdView()
                }
            }
            
            SettingRow(title: String(localized: "LTC Team")) {
                TeamsView()
            }
            SettingRow(title: String(localized: "LTC Key")) {
                LTCKeyView()
            }
            SettingRow(title: String(localized: "LTC Volume")) {
                LTCVolumeView()
            }
            SettingRow(title: String(localized: "LTC Power")) {
                TxPowerView()
            }

            // Hidden on region-locked headsets, which reject zone changes.
            if session.regionLock == nil {
                SettingRow(title: String(localized: "LTC Zone")) {
                    RegionsView()
                }
            }
        }
    }
}

#Preview {
    let session = HeadsetSession()
    let settings = HeadsetSettingsSync(transport: session)
    
    ConnectedView()
        .environment(session)
        .environment(settings)
}
