//
//  AppearanceSettingsView.swift
//  AMP2_App_iOS
//
//  Created by aaron stockdale on 6/23/26.
//

import SwiftUI

enum AppearanceMode: String, CaseIterable, Codable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
}

struct AppearanceSettingsView: View {
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text("Adjusts the colors used in the app's user interface")
                    .font(.ibmPlexSans(size: 18))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 16)
                
                HStack(spacing: 10){
                    SelectionButton(
                        label: "System",
                        selected: appearanceMode == .system,
                        action: { appearanceMode = .system }
                    )
                    
                    SelectionButton(
                        label: "Light Mode",
                        selected: appearanceMode == .light,
                        action: { appearanceMode = .light }
                    )
                }
                
                HStack(spacing: 10) {
                    SelectionButton(
                        label: "Dark Mode",
                        selected: appearanceMode == .dark,
                        action: { appearanceMode = .dark }
                    )

                    Spacer()
                        .frame(maxWidth: .infinity)
                        .padding(.trailing)
                }
            }
            .frame(
                maxWidth: .infinity,
                alignment: .top
            )
            .padding(
                .horizontal, 16
            )
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Appearance")
                    .font(.ibmPlexSans(size: 28, weight: .bold))
            }
        }
        
    }
}

#Preview {
    NavigationStack {
        AppearanceSettingsView()
    }
}
