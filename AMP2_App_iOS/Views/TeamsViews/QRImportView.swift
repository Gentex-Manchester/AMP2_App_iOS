//
//  QRImportView.swift
//  AMP2_App_iOS
//
//  Import a custom team from a QR code using the camera scanner, with
//  a manual Base64 entry fallback. Detected codes are decrypted, decoded,
//  validated, previewed, and saved to the local encrypted database.
//

import SwiftUI
import AVFoundation

struct QRImportView: View {
    /// Called after a successful import so the parent list can refresh.
    var onUpdate: (() -> Void)?

    // MARK: - State

    @State private var permissionState: CameraPermissionState = .notDetermined
    @State private var isScanning = true
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var previewTeam: Team?
    @State private var importSuccess = false
    @State private var showManualEntry = false
    @State private var base64Input: String = ""
    @State private var decodedCode: String?

    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                cameraArea
                bottomArea
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .font(.ibmPlexSans(size: 18))
                .foregroundColor(.opsCoreRed)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showManualEntry.toggle()
                    }
                } label: {
                    Image(systemName: showManualEntry ? "camera.fill" : "doc.on.clipboard")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.opsCoreRed)
                        .frame(width: 36, height: 36)
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: previewTeam)
        .animation(.easeInOut(duration: 0.25), value: importSuccess)
    }

    // MARK: - Camera Area

    @ViewBuilder
    private var cameraArea: some View {
        switch permissionState {
        case .denied:
            permissionDeniedView
        case .restricted:
            permissionRestrictedView
        default:
            scannerView
        }
    }

    private var scannerView: some View {
        ZStack {
            CameraQRScanner(
                onDetected: { code in
                    handleDetectedCode(code)
                },
                permissionState: $permissionState,
                isScanning: isScanning && previewTeam == nil
            )
            .ignoresSafeArea()

            if permissionState == .authorized && previewTeam == nil && !importSuccess {
                scanningOverlay
            }

            if importSuccess {
                successOverlay
            }
        }
    }

    // MARK: - Scanning Overlay

    private var scanningOverlay: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                bracketOverlay

                VStack(spacing: 12) {
                    Spacer()

                    if isLoading && previewTeam == nil {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.2)
                    } else {
                        Text("Point camera at QR code")
                            .font(.ibmPlexSans(size: 18, weight: .bold))
                            .foregroundColor(.opsCoreRed.opacity(0.90))
                    }
                }
                .frame(width: 250, height: 250)
                .padding(.bottom, 30)
            }

            Spacer()
        }
    }

    private var bracketOverlay: some View {
        bracketShape
            .stroke(Color.opsCoreRed.opacity(0.80), lineWidth: 4)
            .frame(width: 250, height: 250)
    }

    private var bracketShape: some Shape {
        BracketShape()
    }

    // MARK: - Success Overlay

    private var successOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            Text("Team Imported!")
                .font(.ibmPlexSans(size: 22, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.60))
    }

    // MARK: - Permission Denied

    private var permissionDeniedView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "camera.fill")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.50))

            Text("Camera Access Denied")
                .font(.ibmPlexSans(size: 22, weight: .bold))
                .foregroundColor(.white)

            Text("Camera permission is required to scan QR codes. Enable it in Settings.")
                .font(.ibmPlexSans(size: 15))
                .foregroundColor(.white.opacity(0.70))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                openSystemSettings()
            } label: {
                Text("Open Settings")
                    .font(.ibmPlexSans(size: 18))
                    .foregroundColor(.white)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 32)
                    .background(Color.opsCoreRed)
                    .cornerRadius(16)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Permission Restricted

    private var permissionRestrictedView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "camera.fill")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.50))

            Text("Camera Unavailable")
                .font(.ibmPlexSans(size: 22, weight: .bold))
                .foregroundColor(.white)

            Text("The camera is restricted on this device. You can still import a team by pasting the QR code text.")
                .font(.ibmPlexSans(size: 15))
                .foregroundColor(.white.opacity(0.70))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                withAnimation { showManualEntry = true }
            } label: {
                Text("Paste QR Code")
                    .font(.ibmPlexSans(size: 18))
                    .foregroundColor(.white)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 32)
                    .background(Color.opsCoreRed)
                    .cornerRadius(16)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Bottom Area

    @ViewBuilder
    private var bottomArea: some View {
        if showManualEntry {
            manualEntryView
        } else if let team = previewTeam {
            previewCard(team)
        }
    }

    // MARK: - Manual Entry

    private var manualEntryView: some View {
        VStack(spacing: 0) {
            if let error = errorMessage {
                manualErrorBanner(error)
            }

            VStack(spacing: 12) {
                Text("Paste QR Code")
                    .font(.ibmPlexSans(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)

                TextField(
                    "Base64 string or QR code text",
                    text: $base64Input
                )
                .font(.ibmPlexSans(size: 14))
                .padding(.vertical, 14)
                .padding(.horizontal, 14)
                .background(Color(.systemGray5))
                .cornerRadius(16)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .onChange(of: base64Input) { _, _ in
                    if !base64Input.isEmpty {
                        errorMessage = nil
                    }
                }

                Button {
                    decodeManualInput()
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        }
                        Text("Decode & Preview")
                            .font(.ibmPlexSans(size: 18))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        base64Input.trimmingCharacters(in: .whitespaces).isEmpty || isLoading
                            ? Color.opsCoreRed.opacity(0.50)
                            : Color.opsCoreRed
                    )
                    .cornerRadius(16)
                }
                .disabled(base64Input.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
            }
            .padding(16)
            .background(.ultraThinMaterial)
        }
    }

    private func manualErrorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.opsCoreRed)
            Text(message)
                .font(.ibmPlexSans(size: 14))
                .foregroundColor(.opsCoreRed)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.opsCoreRed.opacity(0.15))
    }

    // MARK: - Preview Card

    private func previewCard(_ team: Team) -> some View {
        VStack(spacing: 0) {
            if let error = errorMessage {
                previewErrorBanner(error)
            }

            VStack(spacing: 12) {
                // Header
                HStack {
                    Text("Team Preview")
                        .font(.ibmPlexSans(size: 18, weight: .bold))
                        .foregroundColor(.primary)

                    Spacer()

                    Button {
                        resetScanner()
                    } label: {
                        Text("Rescan")
                            .font(.ibmPlexSans(size: 14))
                            .foregroundColor(.opsCoreRed)
                    }
                }

                // Team details
                VStack(spacing: 4) {
                    previewRow(label: "Name", value: team.name)
                    Divider().padding(.vertical, 2)
                    previewRow(label: "RF Channel", value: "Channel \(team.rfChannel)")
                    Divider().padding(.vertical, 2)
                    previewRow(label: "Security Key", value: team.securityKey)
                    Divider().padding(.vertical, 2)
                    previewRow(label: "Network ID", value: String(team.networkId))
                    if let csk = team.customSecurityKey {
                        Divider().padding(.vertical, 2)
                        previewRow(label: "Custom Key", value: csk)
                    }
                }
                .padding(12)
                .background(Color(.systemGray5))
                .cornerRadius(16)

                Button {
                    importTeam(team)
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        }
                        Text("Import Team")
                            .font(.ibmPlexSans(size: 20))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(isLoading ? Color.opsCoreRed.opacity(0.50) : Color.opsCoreRed)
                    .cornerRadius(16)
                }
                .disabled(isLoading)
            }
            .padding(16)
            .background(Color(.systemBackground))
            .clipShape(
                RoundedRectangle(cornerRadius: 16)
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 16)
        }
    }

    private func previewErrorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.opsCoreRed)
            Text(message)
                .font(.ibmPlexSans(size: 14))
                .foregroundColor(.opsCoreRed)
                .lineLimit(2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.opsCoreRed.opacity(0.10))
        .padding(.horizontal, 12)
    }

    private func previewRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.ibmPlexSans(size: 14))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.ibmPlexSans(size: 14, weight: .semiBold))
        }
    }

    // MARK: - Actions

    private func handleDetectedCode(_ code: String) {
        // Ignore while a team is already in preview.
        guard previewTeam == nil, !importSuccess else { return }

        isScanning = false
        isLoading = true
        errorMessage = nil
        decodedCode = code

        do {
            let team = try QRPayload.importTeam(from: code)
            previewTeam = team
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            // Pause so the error is readable, then resume scanning.
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if previewTeam == nil {
                    isScanning = true
                    errorMessage = nil
                }
            }
        }
    }

    private func decodeManualInput() {
        let trimmed = base64Input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        previewTeam = nil

        do {
            let team = try QRPayload.importTeam(from: trimmed)
            previewTeam = team
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    private func importTeam(_ team: Team) {
        isLoading = true
        errorMessage = nil

        do {
            let region = Region(rawValue: team.region) ?? .northAmerica

            if let duplicate = try TeamStore.shared.findDuplicate(of: team) {
                isLoading = false
                errorMessage = "A team with these settings already exists: \"\(duplicate.name)\"."
                return
            }

            _ = try TeamStore.shared.create(team, in: region)
            isLoading = false
            importSuccess = true
            onUpdate?()

            // Auto-dismiss after success animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                dismiss()
            }
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    private func resetScanner() {
        previewTeam = nil
        errorMessage = nil
        decodedCode = nil
        isScanning = true
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Bracket Shape

private struct BracketShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let arm: CGFloat = 32

        var path = Path()

        // Top-left
        path.move(to: CGPoint(x: 0, y: arm))
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: arm, y: 0))

        // Top-right
        path.move(to: CGPoint(x: w - arm, y: 0))
        path.addLine(to: CGPoint(x: w, y: 0))
        path.addLine(to: CGPoint(x: w, y: arm))

        // Bottom-right
        path.move(to: CGPoint(x: w, y: h - arm))
        path.addLine(to: CGPoint(x: w, y: h))
        path.addLine(to: CGPoint(x: w - arm, y: h))

        // Bottom-left
        path.move(to: CGPoint(x: arm, y: h))
        path.addLine(to: CGPoint(x: 0, y: h))
        path.addLine(to: CGPoint(x: 0, y: h - arm))

        return path
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        QRImportView()
    }
}
