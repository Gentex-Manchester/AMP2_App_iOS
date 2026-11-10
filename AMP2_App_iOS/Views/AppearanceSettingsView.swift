//
//  AppearanceSettingsView.swift
//  AMP2_App_iOS
//
//  Created by aaron stockdale on 6/23/26.
//

import SwiftUI

struct AppearanceSettingsView: View {
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system

    var body: some View {
        ScrollView {
            SelectionButtonRow(
                options: AppearanceMode.allCases,
                selection: $appearanceMode,
                onSelection: { selection in
                    appearanceMode = selection
                },
                label: { option in
                    option.displayName
                },
                description: String(localized: "Choose the colors you’d prefer the user interface use.")
            )
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
                    .appTextStyle(.header3)
                    .foregroundStyle(Color("OnBackground"))
            }
        }
    }
}

#Preview {
    NavigationStack {
        AppearanceSettingsView()
    }
}
