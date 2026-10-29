//
//  CustomKeyView.swift
//  AMP2_App_iOS
//
//  Created by Peter Sargent on 10/28/26.
//

import SwiftUI

struct CustomKeyView: View {
    @Environment(HeadsetSession.self) private var session
    @Environment(HeadsetSettingsSync.self) private var headsetSettings
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            if (session.state.isConnected) {
                VStack(spacing: 10) {
                    Text("By setting LTC Key to “Custom”, a custom AES-256 key will be used to encrypt LTC. Enter a passphrase below to create this key.")
                        .font(.ibmPlexSans(size: 18))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                    Text("Once the custom encryption key has been created, the app will forget this passphrase. If you forget it, you can create a new key at any time.")
                        .font(.ibmPlexSans(size: 14))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 16)
                    
                    let customKeyString = headsetSettings.settings.customSecurityKey?.prefix(4).map { String(format: "%02X ", $0) }.joined() ?? "—"
                    Text("Current custom key: " + customKeyString + "...")
                        .font(.ibmPlexSans(size: 14))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(
                    maxWidth: .infinity,
                    alignment: .top
                )
                .padding(
                    .horizontal, 16
                )
            }
        }
        .navigationTitle("Custom Key")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Custom Key")
                    .font(.ibmPlexSans(size: 28, weight: .bold))
            }
        }
    }
}
