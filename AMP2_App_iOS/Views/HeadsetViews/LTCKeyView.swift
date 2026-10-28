//
//  LTCKeyView.swift
//  AMP2_App_iOS
//

import SwiftUI

struct LTCKeyView: View {
    @Environment(HeadsetSession.self) private var session
    @Environment(HeadsetSettingsSync.self) private var headsetSettings
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            if (session.state.isConnected) {
                let selectedKey = headsetSettings.settings.securityKey
                
                VStack(spacing: 10) {
                    Text("Determines how LTC communications are encrypted.")
                        .font(.ibmPlexSans(size: 18))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 16)
                        .padding(.bottom, 16)
                    
                    HStack(spacing: 10) {
                        SelectionButton(
                            label: "Mike",
                            selected: selectedKey == SecurityKey.MIKE,
                            action: { headsetSettings.write(LTCSetting.securityKey, value: SecurityKey.MIKE.ltcByte) }
                        )
                        
                        SelectionButton(
                            label: "November",
                            selected: selectedKey == SecurityKey.NOVEMBER,
                            action: { headsetSettings.write(LTCSetting.securityKey, value: SecurityKey.NOVEMBER.ltcByte) }
                        )
                    }
                    
                    HStack(spacing: 10) {
                        SelectionButton(
                            label: "Oscar",
                            selected: selectedKey == SecurityKey.OSCAR,
                            action: { headsetSettings.write(LTCSetting.securityKey, value: SecurityKey.OSCAR.ltcByte) }
                        )
                        
                        SelectionButton(
                            label: "Papa",
                            selected: selectedKey == SecurityKey.PAPA,
                            action: { headsetSettings.write(LTCSetting.securityKey, value: SecurityKey.PAPA.ltcByte) }
                        )
                    }
                    
                    HStack(spacing: 10) {
                        SelectionButton(
                            label: "Quebec",
                            selected: selectedKey == SecurityKey.QUEBEC,
                            action: { headsetSettings.write(LTCSetting.securityKey, value: SecurityKey.QUEBEC.ltcByte) }
                        )
                        
                        SelectionButton(
                            label: "Romeo",
                            selected: selectedKey == SecurityKey.ROMEO,
                            action: { headsetSettings.write(LTCSetting.securityKey, value: SecurityKey.ROMEO.ltcByte) }
                        )
                    }
                    
                    HStack(spacing: 10) {
                        SelectionButton(
                            label: "Sierra",
                            selected: selectedKey == SecurityKey.SIERRA,
                            action: { headsetSettings.write(LTCSetting.securityKey, value: SecurityKey.SIERRA.ltcByte) }
                        )
                        
                        SelectionButton(
                            label: "Tango",
                            selected: selectedKey == SecurityKey.TANGO,
                            action: { headsetSettings.write(LTCSetting.securityKey, value: SecurityKey.TANGO.ltcByte) }
                        )
                    }
                    
                    HStack(spacing: 10) {
                        SelectionButton(
                            label: "Uniform",
                            selected: selectedKey == SecurityKey.UNIFORM,
                            action: { headsetSettings.write(LTCSetting.securityKey, value: SecurityKey.UNIFORM.ltcByte) }
                        )
                        
                        SelectionButton(
                            label: "Victory",
                            selected: selectedKey == SecurityKey.VICTOR,
                            action: { headsetSettings.write(LTCSetting.securityKey, value: SecurityKey.VICTOR.ltcByte) }
                        )
                    }
                    
                    HStack(spacing: 10) {
                        SelectionButton(
                            label: "Custom",
                            selected: selectedKey == SecurityKey.CUSTOM,
                            action: { headsetSettings.write(LTCSetting.securityKey, value: SecurityKey.CUSTOM.ltcByte) }
                        )
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
        }
        .navigationTitle("LTC Key")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("LTC Key")
                    .font(.ibmPlexSans(size: 28, weight: .bold))
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(value: Route.customKey) {
                    Image("tuning_24px")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
            }
        }
    }
}

#Preview {
    let session = HeadsetSession()
    let sync = HeadsetSettingsSync(transport: session)
    TeamsView()
        .environment(session)
        .environment(sync)
}
