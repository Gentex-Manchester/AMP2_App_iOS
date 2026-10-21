//
//  LockedTeamDetailsView.swift
//  Gentex_iOS
//
//  Read-only view for a locked custom team.
//  Displays all team details as non-editable text with a lock indicator.
//

import SwiftUI

struct LockedTeamDetailsView: View {
    let team: Team

    @Environment(\.dismiss) private var dismiss

    private var displayRegion: String {
        Region(rawValue: team.region)?.displayName ?? team.region
    }

    private var displaySecurityKey: String {
        SecurityKey(rawValue: team.securityKey)?.rawValue ?? team.securityKey
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    lockHeader
                        .padding(.top, 30)
                        .padding(.bottom, 24)

                    detailRows
                        .padding(.horizontal, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Team Details")
                        .font(.ibmPlexSans(size: 28, weight: .bold))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .font(.ibmPlexSans(size: 18))
                    .foregroundColor(.opsCoreRed)
                }
            }
        }
    }

    // MARK: - Lock Header

    private var lockHeader: some View {
        VStack(spacing: 8) {
            Image("Lock")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .foregroundColor(.secondary)

            Text("Locked")
                .font(.ibmPlexSans(size: 20, weight: .bold))
                .foregroundColor(.secondary)

            Text(team.name)
                .font(.ibmPlexSans(size: 28, weight: .bold))
                .foregroundColor(.primary)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Detail Rows

    private var detailRows: some View {
        VStack(spacing: 0) {
            detailRow(label: "Region", value: displayRegion)
            Divider()
                .padding(.leading, 16)
            detailRow(label: "RF Channel", value: "Channel \(team.rfChannel)")
            Divider()
                .padding(.leading, 16)
            detailRow(label: "Network ID", value: String(team.networkId))
            Divider()
                .padding(.leading, 16)
            detailRow(label: "Security Key", value: displaySecurityKey)
        }
        .background(Color(.systemGray5))
        .cornerRadius(16)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.ibmPlexSans(size: 18, weight: .bold))
                .foregroundColor(.primary)
                .frame(width: 130, alignment: .leading)

            Spacer()

            Text(value)
                .font(.ibmPlexSans(size: 18))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
    }
}

#Preview {
    LockedTeamDetailsView(team: Team(
        id: 1,
        region: Region.northAmerica.rawValue,
        rfChannel: 3,
        securityKey: "MIKE",
        networkId: 42,
        name: "Alpha Squad",
        isFavorited: false,
        isLocked: true
    ))
}
