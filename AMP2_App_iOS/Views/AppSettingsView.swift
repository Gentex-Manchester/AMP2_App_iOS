//
//  ContentView.swift
//  AMP2_App_iOS
//
//  Created by aaron stockdale on 6/18/26.
//

import SwiftUI

struct AppSettingsView: View {
    @AppStorage("developerOptions") private var developerOptions: Bool = false
    @State private var tapCount = 0
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 16) {
                    SettingRow(title: "Appearance") {
                        AppearanceSettingsView()
                    }

                    SettingRow(
                        title: "Orientation"
                    ) {
                        OrientationSettingsView()
                    }
            
                    if (developerOptions) {
                        SettingRow(
                            title: "Developer Options"
                        ) {
                            PacketConsoleView()
                        }
                    }
                    
                    Spacer(minLength: 0)
                    
                    VStack(spacing: 12) {
                        Button {
                            tapCount += 1
                            if tapCount >= 5 {
                                developerOptions = true
                            }
                        } label: {
                            Text(appVersion)
                                .appTextStyle(.body)
                                .foregroundStyle(Color("Surface"))
                        }
                        
                        Button {
                            // Add function
                        } label: {
                            Text("Legal")
                                .appTextStyle(.body)
                                .underline()
                                .foregroundStyle(Color("Surface"))
                        }
                    }
                }
                .frame(minHeight: geometry.size.height)
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .padding(.top, 20)
        .padding(.horizontal, 10)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("App Settings")
                    .appTextStyle(.header3)
                    .foregroundStyle(Color("OnBackground"))
            }
        }
    }
}

private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"

        return "App Version: \(version) (\(build))"
    }

#Preview {
    NavigationStack {
        AppSettingsView()
    }
}
