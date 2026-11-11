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
        VStack(spacing: 12) {
            let imageAsset = session.compatibleProduct?.imageAsset ?? "headset_tan"
            let displayName = session.compatibleProduct?.displayName ?? String(localized: "No name detected")
            
            Image(imageAsset)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 250)
            
            Image("ops_core_logo")
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 35)
            
            VStack(spacing: 4) {
                Text(displayName)
                    .appTextStyle(.header1)
                    .foregroundStyle(Color("OnBackground"))
                
                Text(session.compatibleProduct?.partNumber ?? String(localized: "No serial number detected"))
                    .appTextStyle(.subbody)
                    .foregroundStyle(Color("OnBackground"))
                    .opacity(0.5)
            }
        }
    }

    // MARK: - LTC Mode

    /// Inline per the 07/07 mock-ups.
    private var ltcModeSection: some View {
        VStack(alignment: .leading) {
            Text("LTC Mode")
                .appTextStyle(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(Color("OnSurfaceVariant"))
                .padding(.horizontal, 16)

            HStack(spacing: 12) {
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
            .padding(.horizontal, 12)
        }
        .padding(.vertical, 24)
        .background(Color("SurfaceVariant"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16)
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
