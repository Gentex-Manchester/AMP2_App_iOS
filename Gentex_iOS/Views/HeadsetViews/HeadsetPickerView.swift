//
//  HeadsetPickerView.swift
//  Gentex_iOS
//
//  Shown when more than one legitimate AMP 2.0 headset is available, so the
//  user can choose which one the app should use. Required by the Gentex BLE
//  documentation.
//

import SwiftUI

struct HeadsetPickerView: View {
    let headsets: [DiscoveredHeadset]
    var onSelect: (DiscoveredHeadset) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                descriptionSection

                ForEach(headsets) { headset in
                    headsetRow(headset)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Select Headset")
                    .font(.ibmPlexSans(size: 28, weight: .bold))
            }
        }
    }

    // MARK: - Subviews

    private var descriptionSection: some View {
        Text("More than one AMP 2.0 headset is available. Choose the one you'd like to use with the app.")
            .font(.ibmPlexSans(size: 18, weight: .bold))
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 40)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
    }

    private func headsetRow(_ headset: DiscoveredHeadset) -> some View {
        Button {
            onSelect(headset)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(headset.name)
                        .font(.ibmPlexSans(size: 20))

                    if headset.source == .systemConnected {
                        Text("Paired")
                            .font(.ibmPlexSans(size: 14))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
            }
            .foregroundColor(.primary)
            .padding(.vertical, 16)
            .padding(.horizontal)
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray4))
            .cornerRadius(16)
        }
    }
}

#Preview {
    NavigationStack {
        HeadsetPickerView(headsets: [
            DiscoveredHeadset(id: UUID(), name: "AMP 2.0", source: .systemConnected),
            DiscoveredHeadset(id: UUID(), name: "AMP 2.0 Elite", source: .advertised)
        ]) { _ in }
    }
}
