//
//  ContentView.swift
//  AMP2_App_iOS
//
//  Created by aaron stockdale on 6/18/26.
//

import SwiftUI

struct AppSettingsView: View {
    var body: some View {
        ScrollView {
            VStack {
                SettingRow(title: "Appearance") {
                    AppearanceSettingsView()
                }

                SettingRow(
                    title: "Orientation"
                ) {
                    OrientationSettingsView()
                }
        
                #if DEBUG
                SettingRow(
                    title: "DEBUG: Packet Console"
                ) {
                    PacketConsoleView()
                }
                #endif
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .padding(.top, 20)
            .padding(.horizontal, 10)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                AppText("App Settings", style: .header3)
                    .foregroundStyle(Color("OnBackground"))
            }
        }
    }
}

#Preview {
    NavigationStack {
        AppSettingsView()
    }
}
