//
//  HeadsetView.swift
//  AMP2_App_iOS
//
//  Created by Peter Sargent on 10/22/26.
//

import SwiftUI
struct HeadsetView: View {
    @Environment(HeadsetSession.self) private var headsetSession
    @Binding private var headsetNavigationPath: [Route]

    init(headsetNavigationPath: Binding<[Route]> = .constant([])) {
        _headsetNavigationPath = headsetNavigationPath
    }

    /// Live controls when connected, connection help otherwise.
    var body: some View {
        NavigationStack(path: $headsetNavigationPath) {
            Group {
                if headsetSession.state.isConnected {
                    ConnectedView()
                } else {
                    DisconnectedView()
                }
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .settings: AppSettingsView()
                case .appearance: AppearanceSettingsView()
                case .orientation: OrientationSettingsView()
                case .regions: RegionsView()
                case .teams: TeamsView()
                case .vadThreshold: VADThresholdView()
                case .ltcVolume: LTCVolumeView()
                case .txPower: TxPowerView()
                #if DEBUG
                case .packetConsole: PacketConsoleView()
                #endif
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        headsetNavigationPath.append(.settings)
                    } label: {
                        Image("settings")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.opsCoreRed)
                    }
                }
            }
        }
    }
}
