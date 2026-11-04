//
//  PairiutorialView.swift
//  AMP2_App_iOS
//

import SwiftUI

struct PairingTutorialView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(HeadsetSession.self) private var session

    @State private var currentStep = 0

    private var isLandscape: Bool { verticalSizeClass == .compact }
    private var steps: [TutorialStep] { pairingSteps }

    /// Last step: send the user to Settings and wait for a connection.
    private var isPairingStep: Bool { currentStep == steps.count - 1 }

    var body: some View {
        VStack(spacing: 0) {
            stepContent
                .frame(maxHeight: .infinity)
                .scrollBounceBehavior(.basedOnSize)
            Spacer(minLength: 0)
            BottomControls(
                type: steps[currentStep].controls,
                goBack: goBack,
                goForward: { currentStep += 1 }
            )
            .padding(.horizontal, 26)
        }
        // Connecting ends the tutorial, as on Android.
        .onChange(of: session.state) { _, newState in
            if newState.isConnected { dismiss() }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                AppText("Bluetooth Pairing", style: .header3)
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
        .navigationTitle("Bluetooth Pairing")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        let step = steps[currentStep]

        if isLandscape {
            landscapeLayout(step)
        } else {
            portraitLayout(step)
        }
    }

    private func portraitLayout(_ step: TutorialStep) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                if step.media.type == .image {
                    ImageView(
                        media: step.media,
                        configuration: MediaConfiguration(
                            contentMode: .fit,
                            height: 250
                        )
                    )
                }

                AppText(step.title, style: .header2)
                    .multilineTextAlignment(.center)

                if !step.description.isEmpty {
                    AppText(step.description, style: .body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal)
        }
    }

    private func landscapeLayout(_ step: TutorialStep) -> some View {
        ScrollView {
            HStack(spacing: 32) {
                if step.media.type == .image {
                    ImageView(
                        media: step.media,
                        configuration: MediaConfiguration(
                            contentMode: .fit,
                            height: 200
                        )
                    )
                }

                VStack(spacing: 16) {
                    AppText(step.title, style: .header2)
                        .multilineTextAlignment(.center)

                    if !step.description.isEmpty {
                        AppText(step.description, style: .body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal)
        }
    }

    private func goBack() {
        if currentStep > 0 {
            currentStep -= 1
        } else {
            dismiss()
        }
    }
}

#Preview {
    NavigationStack {
        PairingTutorialView()
            .environment(HeadsetSession())
    }
}
