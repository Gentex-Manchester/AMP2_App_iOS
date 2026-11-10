//
//  LTCKeyView.swift
//  AMP2_App_iOS
//

import SwiftUI

struct LTCKeyView: View {
    @Environment(HeadsetSession.self) private var session
    @Environment(HeadsetSettingsSync.self) private var headsetSettings
    
    var body: some View {
        ScrollView {
            SelectionButtonRow(
                options: SecurityKey.allCases,
                selection: Binding(
                        get: {
                            headsetSettings.settings.securityKey ?? SecurityKey.MIKE
                        },
                        set: { selection in
                            headsetSettings.write(
                                LTCSetting.securityKey,
                                value: selection.ltcByte
                            )
                        }
                    ),
                onSelection: { selection in
                    headsetSettings.write(LTCSetting.securityKey, value: selection.ltcByte)
                },
                label: { option in
                    option.rawValue
                },
                description: "Determines how LTC communications are encrypted."
            )
            .frame(
                maxWidth: .infinity,
                alignment: .top
            )
            .padding(
                .horizontal, 16
            )
        }
        .navigationTitle("LTC Key")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("LTC Key")
                    .appTextStyle(.header3)
                    .foregroundStyle(Color("OnBackground"))
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    CustomKeyView()
                } label: {
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
    LTCKeyView()
        .environment(session)
        .environment(sync)
}
