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
                    ltcModeSection
                    settingsLinks
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
                AppText("My AMP®", style: .header3)
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

    var unusedBody: some View {
        ScrollView {
            
        }
        .navigationTitle("My AMP®")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                AppText("My AMP®", style: .header3)
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

            AppText("AMP 2.0 Elite", style: .header1)
            
            Spacer()
        }
    }

    // MARK: - LTC Mode

    /// Inline per the 07/07 mock-ups.
    private var ltcModeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            AppText("LTC Mode", style: .header3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

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
        .padding(.bottom, 10)
    }

    // MARK: - Setting Links

    private var settingsLinks: some View {
        VStack(spacing: 0) {
            if settings.settings.ltcMode == .vad {
                SettingRow(title: LTCSetting.vadThreshold.displayName) {
                    VADThresholdView()
                }
            }
            
            SettingRow(title: "LTC Team") {
                TeamsView()
            }
            SettingRow(title: "LTC Key") {
                LTCKeyView()
            }
            SettingRow(title: "LTC Volume") {
                LTCVolumeView()
            }
            SettingRow(title: "LTC Power") {
                TxPowerView()
            }

            // Hidden on region-locked headsets, which reject zone changes.
            if session.regionLock == nil {
                SettingRow(title: LTCSetting.zone.displayName) {
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
