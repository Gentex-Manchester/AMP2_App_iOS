//
//  SelectDeviceView.swift
//  AMP2_App_iOS
//

import SwiftUI

struct SelectDeviceView: View {
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
            
            if (session.discoveredHeadsets.isEmpty == false) {
                ForEach(session.discoveredHeadsets) { headset in
                    DiscoveredHeadsetButton(
                        discoveredHeadset: headset,
                        action: {
                            session.connect(headset)
                        }
                    )
                }
            }
            
            ProgressView()
                .scaleEffect(1.5)
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
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
        SelectDeviceView()
            .environment(HeadsetSession())
    }
}
