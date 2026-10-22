//
//  ContentView.swift
//  AMP2_App_iOS
//
//  Created by aaron stockdale on 6/18/26.
//

import SwiftUI

struct AppSettingsView: View {
    @Binding private var navigationPath: [SettingsRoute]

    init(navigationPath: Binding<[SettingsRoute]> = .constant([])) {
        _navigationPath = navigationPath
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack {
                
                    SettingRow(
                        title: "Appearance",
                        route: SettingsRoute.appearance
                    )

                    SettingRow(
                        title: "Orientation",
                        route: SettingsRoute.orientation
                    )
            
                    #if DEBUG
                    SettingRow(
                        title: "DEBUG: Packet Console",
                        route: SettingsRoute.packetConsole
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
            .navigationDestination(for: SettingsRoute.self) { route in
                switch route {
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
