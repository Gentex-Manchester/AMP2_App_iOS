//
//  QRExportView.swift
//  AMP2_App_iOS
//
//  Displays a QR code for a single custom team so another iOS device
//  can scan and import it. The QR payload is AES-256-GCM encrypted
//  with the app-embedded key.
//

import SwiftUI

struct QRExportView: View {
    let team: Team

    @State private var qrCodeImage: UIImage?
    @State private var errorMessage: String?
    @State private var isGenerating = true

    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                titleSection

                if let error = errorMessage {
                    errorBanner(error)
                }

                qrCodeSection

                teamInfoSection

                instructionsSection

                Spacer(minLength: 40)
            }
            .padding(.horizontal)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Share Team")
                    .font(.ibmPlexSans(size: 28, weight: .bold))
            }
        }
        .task {
            await generateQR()
        }
    }

    // MARK: - Title

    private var titleSection: some View {
        Text("Share \"\(team.name)\"")
            .font(.ibmPlexSans(size: 28, weight: .bold))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 10)
            .padding(.bottom, 8)
    }

    // MARK: - Error Banner

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.opsCoreRed)
            Text(message)
                .font(.ibmPlexSans(size: 14))
                .foregroundColor(.opsCoreRed)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.opsCoreRed.opacity(0.10))
        .cornerRadius(16)
        .padding(.top, 12)
    }

    // MARK: - QR Code

    private var qrCodeSection: some View {
        VStack(spacing: 0) {
            if isGenerating {
                ProgressView()
                    .scaleEffect(1.5)
                    .padding(.vertical, 60)
            } else if let image = qrCodeImage {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(maxWidth: 300, maxHeight: 300)
                    .padding(.vertical, 30)
                    .background(Color.white)
                    .cornerRadius(16)
                    .padding(.top, 20)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Team Info

    private var teamInfoSection: some View {
        VStack(spacing: 4) {
            Text(team.name)
                .font(.ibmPlexSans(size: 20, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Ch \(team.rfChannel) · \(team.securityKey) · \(team.region)")
                .font(.ibmPlexSans(size: 14))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Color(.systemGray5))
        .cornerRadius(16)
        .padding(.top, 16)
    }

    // MARK: - Instructions

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How to share")
                .font(.ibmPlexSans(size: 18, weight: .bold))
                .padding(.top, 20)

            instructionRow(number: "1", text: "Show this QR code to another Gentex app user.")
            instructionRow(number: "2", text: "They can scan it using the \"Import Team\" option in their Teams tab.")
            instructionRow(number: "3", text: "The team settings will be imported to their device.")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func instructionRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(number)
                .font(.ibmPlexSans(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 22, height: 22)
                .background(Color.opsCoreRed)
                .clipShape(Circle())

            Text(text)
                .font(.ibmPlexSans(size: 14))
                .foregroundColor(.secondary)
        }
    }

    // MARK: - QR Generation

    private func generateQR() async {
        isGenerating = true
        errorMessage = nil

        do {
            let base64String = try QRPayload.exportTeam(team)

            guard let qrFilter = CIFilter(name: "CIQRCodeGenerator") else {
                errorMessage = "Unable to create QR code generator."
                isGenerating = false
                return
            }

            let data = Data(base64String.utf8)
            qrFilter.setValue(data, forKey: "inputMessage")
            qrFilter.setValue("H", forKey: "inputCorrectionLevel")

            guard let ciImage = qrFilter.outputImage else {
                errorMessage = "Failed to generate QR code image."
                isGenerating = false
                return
            }

            // Scale up the QR code for display (CIFilter produces tiny images)
            let scaleX: CGFloat = 10
            let scaleY: CGFloat = 10
            let transformed = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

            let context = CIContext()
            guard let cgImage = context.createCGImage(transformed, from: transformed.extent) else {
                errorMessage = "Failed to render QR code image."
                isGenerating = false
                return
            }

            let uiImage = UIImage(cgImage: cgImage)
            await MainActor.run {
                qrCodeImage = uiImage
                isGenerating = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isGenerating = false
            }
        }
    }
}

#Preview {
    NavigationStack {
        QRExportView(
            team: Team(
                id: 1,
                region: "North America",
                rfChannel: 3,
                securityKey: "MIKE",
                networkId: 42,
                name: "Alpha Team"
            )
        )
    }
}
