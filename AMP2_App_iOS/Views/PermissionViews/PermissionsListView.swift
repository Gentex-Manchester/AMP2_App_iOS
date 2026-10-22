//
//  PermissionsListView.swift
//  AMP2_App_iOS
//

import SwiftUI

struct PermissionsListView: View {
    @State private var selectedPermission: PermissionType?
    /// Snapshot refreshed on appear; the status reads aren't observable.
    @State private var statuses: [PermissionType: PermissionStatus] = [:]
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {


                Text("This app requires the following permissions to function properly.")
                    .font(.ibmPlexSans(size: 15))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 22)
                    .padding(.bottom, 30)

                ForEach(PermissionType.allCases, id: \.self) { permission in
                    Button {
                        selectedPermission = permission
                    } label: {
                        HStack {
                            Text(permission.buttonTitle)
                                .font(.ibmPlexSans(size: 20))

                            Spacer()

                            statusBadge(for: permission)

                            Image(systemName: "chevron.right")
                        }
                        .foregroundColor(.primary)
                        .padding(.vertical, 16)
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray4))
                        .cornerRadius(16)
                    }
                    .padding(.horizontal)
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Permissions")
                    .font(.ibmPlexSans(size: 28, weight: .bold))
            }
        }
        .sheet(item: $selectedPermission) { permission in
            PermissionRequirementView(permissionType: permission)
                .presentationCornerRadius(16)
        }
        .onAppear(perform: refreshStatuses)
        // Permissions change in Settings while backgrounded.
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { refreshStatuses() }
        }
        .onChange(of: selectedPermission) { _, permission in
            if permission == nil { refreshStatuses() }
        }
    }

    // MARK: - Status

    private func statusBadge(for permission: PermissionType) -> some View {
        let status = statuses[permission] ?? permission.status

        return Text(status.label)
            .font(.ibmPlexSans(size: 15))
            .foregroundColor(status.isUsable ? .secondary : .opsCoreRed)
            .padding(.trailing, 6)
    }

    private func refreshStatuses() {
        statuses = Dictionary(
            uniqueKeysWithValues: PermissionType.allCases.map { ($0, $0.status) }
        )
    }
}

#Preview {
    NavigationStack {
        PermissionsListView()
    }
}
