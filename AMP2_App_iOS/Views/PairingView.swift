//
//  PairingView.swift
//  AMP2_App_iOS
//

import SwiftUI

struct PairingView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(HeadsetSession.self) private var session

    private var isLandscape: Bool { verticalSizeClass == .compact }

    var body: some View {
        VStack(spacing: 24) {
            Text("Once the headset has been connected to your system, select it from the list below.")
                .appTextStyle(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                .foregroundStyle(Color("OnBackground"))
            
            ForEach(session.discoveredHeadsets) { headset in
                DiscoveredHeadsetButton(
                    discoveredHeadset: headset,
                    action: {
                        session.connect(headset)
                    }
                )
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal)
        // Connecting closes this screen
        // .onChange(of: session.state) { _, newState in
            // if newState.isConnected { dismiss() }
        // }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Select Device")
                    .appTextStyle(.header3)
                    .foregroundStyle(Color("OnBackground"))
            }
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
            }
        }
        .navigationTitle("Select Device")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        PairingView()
            .environment(HeadsetSession())
    }
}
