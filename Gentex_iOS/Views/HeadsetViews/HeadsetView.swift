//
//  HeadsetView.swift
//  Gentex_iOS
//
//  The Headset tab while connected: live settings, written back on change.
//  Per the July 7, 2026 mock-ups, LTC Mode is inline and VAD Threshold shows
//  only in VOX/VAD mode.
//

import SwiftUI

struct HeadsetView: View {
    @Environment(HeadsetSettingsSync.self) private var settings
    @Environment(HeadsetSession.self) private var session

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerSection
                ltcModeSection
                settingsLinks
                if settings.settings.ltcMode == .vad {
                    vadThresholdLink
                }
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
            settingRow(.ltcVolume, route: .ltcVolume)
            settingRow(.txPower, route: .txPower)

            // Hidden on region-locked headsets, which reject zone changes.
            if session.regionLock == nil {
                settingRow(.zone, route: .regions)
            }
        }
    }

    private var vadThresholdLink: some View {
        settingRow(.vadThreshold, route: .vadThreshold)
    }

    private func settingRow(_ setting: LTCSetting, route: SettingsRoute) -> some View {
        NavigationLink(value: route) {
            HStack {
                Text(setting.displayName)
                    .font(.ibmPlexSans(size: 20))

                Spacer()

                // Dash until the first poll lands, not a fake default.
                Text(settings.settings.displayValue(for: setting) ?? "—")
                    .font(.ibmPlexSans(size: 18))
                    .foregroundColor(.secondary)

                Image(systemName: "chevron.right")
            }
            .foregroundColor(.primary)
            .padding(.vertical, 16)
            .padding(.horizontal)
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray4))
            .cornerRadius(16)
        }
        .padding(.horizontal)
        .padding(.bottom, 10)
    }
}

#Preview {
    let session = HeadsetSession()
    NavigationStack {
        HeadsetView()
            .environment(session)
            .environment(HeadsetSettingsSync(transport: session))
    }
}
