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
            VStack {
            Text("Adjusts the colors used in the app's user interface")
                .font(.ibmPlexSans(size: 18))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 50)
                .padding(.bottom, 10)
                .padding(.leading, 22)
            
            HStack(spacing: 10){
                Button(action: { appearanceMode = .system }) {
                    HStack {
                        Spacer()
                        Text("System")
                            .font(.ibmPlexSans(size: 20))
                        Spacer()
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 16)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity)
                    .background(appearanceMode == .system ? Color.opsCoreRed : Color.opsCoreRed.opacity(0.50))
                    .cornerRadius(16)
                }
                .padding(.leading)
                .padding(.bottom, 10)

                Button(action: { appearanceMode = .light }) {
                    HStack {
                        Spacer()
                        Text("Light Mode")
                            .font(.ibmPlexSans(size: 20))
                        Spacer()
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 16)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity)
                    .background(appearanceMode == .light ? Color.opsCoreRed : Color.opsCoreRed.opacity(0.50))
                    .cornerRadius(16)
                }
                .padding(.trailing)
                .padding(.bottom, 10)
            }
            
            HStack(spacing: 10) {
                Button(action: { appearanceMode = .dark }) {
                    HStack {
                        Spacer()
                        Text("Dark Mode")
                            .font(.ibmPlexSans(size: 20))
                        Spacer()
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 16)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity)
                    .background(appearanceMode == .dark ? Color.opsCoreRed : Color.opsCoreRed.opacity(0.50))
                    .cornerRadius(16)
                }
                .padding(.leading)

                Spacer()
                    .frame(maxWidth: .infinity)
                    .padding(.trailing)
            }

            }
            .frame(maxWidth: .infinity, alignment: .top)
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
