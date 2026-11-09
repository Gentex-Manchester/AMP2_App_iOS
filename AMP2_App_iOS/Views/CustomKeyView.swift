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
    
    @State private var password = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                AppText("By setting LTC Key to “Custom”, a custom AES-256 key will be used to encrypt LTC. Enter a passphrase below to create this key.", style: .body)
                    .foregroundStyle(Color("OnBackground"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                AppText("Once the custom encryption key has been created, the app will forget this passphrase. If you forget it, you can create a new key at any time.", style: .subbody)
                    .foregroundStyle(Color("OnBackground"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 16)
                
                TextField(
                    "Enter passphrase...",
                    text: Binding(
                        get: { password },
                        set: { newValue in
                            password = newValue
                                .uppercased()
                                .filter { !$0.isWhitespace }
                        }
                    )
                )
                .font(AppTextStyle.body.font)
                .textInputAutocapitalization(.characters) // TODO: Replace with custom text field
                .autocorrectionDisabled()
                .padding(12)
                .background(Color("Surface"))
                .foregroundStyle(Color("OnSurface"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                PrimaryButton(
                    label: "Set",
                    enabled: password.isEmpty == false && session.state.isConnected,
                    action: {
                        guard !password.isEmpty else { return }
                        if let encryptedData = encrypt(password) {
                            let encryptedBytes: [UInt8] = Array(encryptedData)
                            headsetSettings.write(LTCSetting.customSecurityKey, value: encryptedBytes)
                        }
                        password = ""
                    }
                )
                .padding(.vertical, 12)
                
                let customKeyString = headsetSettings.settings.customSecurityKey?.prefix(4).map { String(format: "%02X ", $0) }.joined() ?? "—"
                AppText("Current custom key: " + customKeyString + "...", style: .subbody)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(Color("OnBackground"))
            }
            .frame(
                maxWidth: .infinity,
                alignment: .top
            )
            .padding(
                .horizontal, 16
            )
        }
        .navigationTitle("Edit Custom Key")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                AppText("Edit Custom Key", style: .header3)
                    .foregroundStyle(Color("OnBackground"))
            }
        }
    }
}

#Preview {
    let session = HeadsetSession()
    let settings = HeadsetSettingsSync(transport: session)
    
    CustomKeyView()
        .environment(session)
        .environment(settings)
}

