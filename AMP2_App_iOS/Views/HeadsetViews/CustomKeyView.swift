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
                    Text("[PH] Coming soon...")
                        .font(.ibmPlexSans(size: 18))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 16)
                        .padding(.bottom, 16)
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
