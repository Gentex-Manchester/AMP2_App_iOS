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
        ScrollView {
            VStack(spacing: 0) {
                headerSection
                ltcModeSection
                settingsLinks
                Spacer(minLength: 40)
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .padding(.top, 10)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()

                Image("Ops-Core")
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 35)

                Text("|")
                    .font(.ibmPlexSans(size: 50))
                    .foregroundColor(Color.opsCoreRed)

                Text("AMP 2.0 Elite")
                    .font(.ibmPlexSans(size: 20))

                Spacer()
            }
            .frame(maxWidth: .infinity)

            Image("Device Connected (Dark)")
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 250)
        }
    }

    // MARK: - LTC Mode

    /// Inline per the 07/07 mock-ups.
    private var ltcModeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("LTC Mode")
                .font(.ibmPlexSans(size: 18, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            HStack(spacing: 10) {
                ForEach(LTCMode.allCases, id: \.self) { mode in
                    modeButton(mode)
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 10)
    }

    private func modeButton(_ mode: LTCMode) -> some View {
        Button {
            settings.write(.ltcMode, value: mode.rawValue)
        } label: {
            Text(mode.displayName)
                .font(.ibmPlexSans(size: 18))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .foregroundColor(.white)
                .padding(.vertical, 20)
                .padding(.horizontal, 6)
                .frame(maxWidth: .infinity)
                .background(
                    settings.settings.ltcMode == mode
                        ? Color.opsCoreRed
                        : Color.opsCoreRed.opacity(0.50)
                )
                .cornerRadius(16)
        }
    }

    // MARK: - Setting Links

    private var settingsLinks: some View {
        VStack(spacing: 0) {
            SettingRow(title: LTCSetting.ltcVolume.displayName, route: .ltcVolume)
            SettingRow(title: LTCSetting.txPower.displayName, route: .txPower)

            // Hidden on region-locked headsets, which reject zone changes.
            if session.regionLock == nil {
                SettingRow(title: LTCSetting.zone.displayName, route: .regions)
            }
            
            if settings.settings.ltcMode == .vad {
                SettingRow(title: LTCSetting.vadThreshold.displayName, route: .vadThreshold)
            }
        }
    }
}

#Preview {
    let session = HeadsetSession()
    NavigationStack {
        ConnectedView()
            .environment(session)
            .environment(HeadsetSettingsSync(transport: session))
    }
}
