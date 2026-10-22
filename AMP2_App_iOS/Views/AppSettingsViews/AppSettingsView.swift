//
//  ContentView.swift
//  AMP2_App_iOS
//
//  Created by aaron stockdale on 6/18/26.
//

import SwiftUI

struct AppSettingsView: View {
    @State private var navigationPath: [Route] = [Route.settings]

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack {
                
                    SettingRow(
                        title: "Appearance",
                        route: Route.appearance
                    )

                    SettingRow(
                        title: "Orientation",
                        route: Route.orientation
                    )
            
                    #if DEBUG
                    SettingRow(
                        title: "DEBUG: Packet Console",
                        route: Route.packetConsole
                    )
                    #endif
                }
                .frame(maxWidth: .infinity, alignment: .top)
                .padding(.top, 20)
                .padding(.horizontal, 10)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("App Settings")
                        .font(.ibmPlexSans(size: 28, weight: .bold))
                }
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .teams:
                    TeamsView()
                case .settings:
                    AppSettingsView()
                case .appearance:
                    AppearanceSettingsView()
                case .orientation:
                    OrientationSettingsView()
                case .regions:
                    RegionsView()
                case .vadThreshold:
                    VADThresholdView()
                case .ltcVolume:
                    LTCVolumeView()
                case .txPower:
                    TxPowerView()
                #if DEBUG
                case .packetConsole:
                    PacketConsoleView()
                #endif
                }
            }
        }
        
    }
    
}

#Preview {
    let session = HeadsetSession()
    let sync = HeadsetSettingsSync(transport: session)
    ContentView()
        .environment(session)
        .environment(sync)
}
