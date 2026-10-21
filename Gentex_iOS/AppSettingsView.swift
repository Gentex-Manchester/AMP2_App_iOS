//
//  ContentView.swift
//  Gentex_iOS
//
//  Created by aaron stockdale on 6/18/26.
//

import SwiftUI

enum SettingsRoute: Hashable {
    case appearance
    case orientation
    case permissions
    case userManuals
    case regions
    case vadThreshold
    case ltcVolume
    case txPower
    #if DEBUG
    /// Bluetooth bring-up diagnostics. Debug builds only.
    case packetConsole
    #endif

    /// Screens popped when the headset disconnects.
    var requiresHeadset: Bool {
        switch self {
        case .appearance, .orientation, .permissions, .userManuals:
            return false
        case .regions, .vadThreshold, .ltcVolume, .txPower:
            return true
        #if DEBUG
        // Survives a disconnect; it's where disconnects get diagnosed.
        case .packetConsole:
            return false
        #endif
        }
    }
}

extension Array where Element == SettingsRoute {

    /// Pops the first headset-only screen and everything above it.
    mutating func popHeadsetOnlyScreens() {
        guard let first = firstIndex(where: \.requiresHeadset) else { return }
        removeSubrange(first...)
    }
}

struct AppSettingsView: View {
    @Binding private var navigationPath: [SettingsRoute]

    init(navigationPath: Binding<[SettingsRoute]> = .constant([])) {
        _navigationPath = navigationPath
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack {
                
                    NavigationLink(value: SettingsRoute.appearance) {
                        HStack {
                        
                            Text("Appearance")
                            .font(.ibmPlexSans(size: 20))

                            Spacer()

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

            
                    NavigationLink(value: SettingsRoute.orientation) {
                        HStack {
                    
                            Text("Orientation")
                                .font(.ibmPlexSans(size: 20))

                            Spacer()

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

                    NavigationLink(value: SettingsRoute.permissions) {
                        HStack {
                            Text("Permissions")
                                .font(.ibmPlexSans(size: 20))

                            Spacer()

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
            
                    NavigationLink(value: SettingsRoute.userManuals) {
                        HStack {
                            Text("User Manual")
                                .font(.ibmPlexSans(size: 20))

                            Spacer()

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
            
                    #if DEBUG
                    NavigationLink(value: SettingsRoute.packetConsole) {
                        HStack {
                            Text("Packet Console")
                                .font(.ibmPlexSans(size: 20))

                            Spacer()

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
                    #endif

                    Link(destination: URL(string: "https://www.gentexcorp.com/privacy-policies/")!) {
                        HStack {
                            Text("Privacy")
                                .font(.ibmPlexSans(size: 20))

                            Spacer()

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
            
                    Link(destination: URL(string: "https://www.gentexcorp.com/privacy-policies/")!) {
                        HStack {
                            Text("Contact Us")
                                .font(.ibmPlexSans(size: 20))

                            Spacer()

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
                case .permissions:
                    PermissionsListView()
                case .userManuals:
                    UserManualsView()
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
