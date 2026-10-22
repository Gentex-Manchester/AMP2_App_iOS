//
//  PermissionRequirementView.swift
//  AMP2_App_iOS
//

import SwiftUI

struct PermissionRequirementView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.verticalSizeClass) var verticalSizeClass

    let permissionType: PermissionType

    private var isLandscape: Bool { verticalSizeClass == .compact }
    private var permissionData: PermissionData { permissionType.data }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top)

            permissionContent
                .frame(maxHeight: .infinity)

            Spacer(minLength: 0)

            primaryButton("Continue") {
                openSystemSettings()
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Permission Content

    @ViewBuilder
    private var permissionContent: some View {
        if isLandscape {
            landscapeLayout
        } else {
            portraitLayout
        }
    }

    private var portraitLayout: some View {
        ScrollView {
            VStack(spacing: 24) {
                if !permissionData.imageName.isEmpty {
                    Image(permissionData.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 250)
                }

                Text(permissionData.title)
                    .font(.ibmPlexSans(size: 22, weight: .bold))
                    .multilineTextAlignment(.center)

                if !permissionData.description.isEmpty {
                    Text(permissionData.description)
                        .font(.ibmPlexSans(size: 18))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal)
        }
    }

    private var landscapeLayout: some View {
        ScrollView {
            if permissionData.imageName.isEmpty {
                VStack(spacing: 16) {
                    Text(permissionData.title)
                        .font(.ibmPlexSans(size: 22, weight: .bold))
                        .multilineTextAlignment(.center)

                    if !permissionData.description.isEmpty {
                        Text(permissionData.description)
                            .font(.ibmPlexSans(size: 18))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal)
            } else {
                HStack(spacing: 32) {
                    Image(permissionData.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 250)

                    VStack(spacing: 16) {
                        Text(permissionData.title)
                            .font(.ibmPlexSans(size: 22, weight: .bold))
                            .multilineTextAlignment(.center)

                        if !permissionData.description.isEmpty {
                            Text(permissionData.description)
                                .font(.ibmPlexSans(size: 18))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Actions

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Button Style

    private func primaryButton(_ text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(.ibmPlexSans(size: 20))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.opsCoreRed)
                .cornerRadius(16)
        }
    }
}

#Preview {
    PermissionRequirementView(permissionType: .bluetooth)
}
