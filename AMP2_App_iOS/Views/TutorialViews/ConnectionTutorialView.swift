//
//  ConnectionTutorialView.swift
//  AMP2_App_iOS
//

import SwiftUI

struct ConnectionTutorialView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(HeadsetSession.self) private var session

    @State private var currentStep = 0

    private var isLandscape: Bool { verticalSizeClass == .compact }
    private var steps: [TutorialStep] { tutorialSteps }

    /// Last step: send the user to Settings and wait for a connection.
    private var isPairingStep: Bool { currentStep == steps.count - 1 }

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

            stepContent
                .frame(maxHeight: .infinity)

            Spacer(minLength: 0)

            bottomControls
                .padding(.horizontal, 26)
        }
        // Connecting ends the tutorial, as on Android.
        .onChange(of: session.state) { _, newState in
            if newState.isConnected { dismiss() }
        }
        // Scan from the pairing step so it's running on return from Settings.
        .onChange(of: currentStep) { _, _ in
            startLookingIfPairing()
        }
        // Also on appear: `onChange` never fires when opening at the pairing step.
        .onAppear {
            startLookingIfPairing()
        }
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
                if !step.imageName.isEmpty {
                    Image(step.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 250)
                }

                Text(step.title)
                    .font(.ibmPlexSans(size: 22, weight: .bold))
                    .multilineTextAlignment(.center)

                if !step.description.isEmpty {
                    Text(step.description)
                        .font(.ibmPlexSans(size: 18))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal)
        }
    }

    private func landscapeLayout(_ step: TutorialStep) -> some View {
        ScrollView {
            if step.imageName.isEmpty {
                VStack(spacing: 16) {
                    Text(step.title)
                        .font(.ibmPlexSans(size: 22, weight: .bold))
                        .multilineTextAlignment(.center)

                    if !step.description.isEmpty {
                        Text(step.description)
                            .font(.ibmPlexSans(size: 18))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal)
            } else {
                HStack(spacing: 32) {
                    Image(step.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 250)

                    VStack(spacing: 16) {
                        Text(step.title)
                            .font(.ibmPlexSans(size: 22, weight: .bold))
                            .multilineTextAlignment(.center)

                        if !step.description.isEmpty {
                            Text(step.description)
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

    // MARK: - Bottom Controls

    @ViewBuilder
    private var bottomControls: some View {
        if isPairingStep {
            // No Next until connected (matches Android). One row in landscape so
            // the instructions aren't cut off; AnyLayout keeps identity on rotation.
            let layout = isLandscape
                ? AnyLayout(HStackLayout(spacing: 18))
                : AnyLayout(VStackLayout(spacing: 18))

            layout {
                waitingForHeadset

                HStack(spacing: 18) {
                    secondaryButton("Back") {
                        goBack()
                    }

                    secondaryButton(session.isDiscovering ? "Looking…" : "Check Again") {
                        session.startDiscovery()
                    }
                    .disabled(session.isDiscovering)
                }
            }
        } else {
            HStack(spacing: 18) {
                secondaryButton("Back") {
                    goBack()
                }

                primaryButton("Next") {
                    currentStep += 1
                }
            }
        }
    }

    /// Replaces Next on the pairing step, so there's no dead button.
    private var waitingForHeadset: some View {
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)
                .tint(.opsCoreRed)

            Text("Waiting for your headset…")
                .font(.ibmPlexSans(size: 18))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    private func startLookingIfPairing() {
        guard isPairingStep, !session.state.isConnected, !session.isDiscovering else { return }
        session.startDiscovery()
    }

    private func goBack() {
        if currentStep > 0 {
            currentStep -= 1
        } else {
            dismiss()
        }
    }

    // MARK: - Button Styles

    // Android's primary (64dp) and secondary (56dp) buttons, margins, and gaps
    // ×1.1, since an Android dp draws ~10% larger. The heights differ there too.
    private func primaryButton(_ text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(.ibmPlexSans(size: 20))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 70)
                .background(Color.opsCoreRed)
                .cornerRadius(16)
        }
    }

    private func secondaryButton(_ text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(.ibmPlexSans(size: 20))
                .foregroundColor(.opsCoreRed)
                .frame(maxWidth: .infinity, minHeight: 62)
                .background(Color(.systemGray5))
                .cornerRadius(16)
        }
    }
}

#Preview {
    ConnectionTutorialView()
        .environment(HeadsetSession())
}
