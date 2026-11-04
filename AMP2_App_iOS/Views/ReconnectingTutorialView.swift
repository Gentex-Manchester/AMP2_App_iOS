//
//  ReconnectingTutorialView.swift
//  AMP2_App_iOS
//

import SwiftUI

struct ReconnectingTutorialView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(HeadsetSession.self) private var session

    @State private var currentStep = 0

    private var isLandscape: Bool { verticalSizeClass == .compact }
    private var steps: [TutorialStep] { reconnectingSteps }

    var body: some View {
        VStack(spacing: 0) {
            stepContent(steps[currentStep], isLandscape: isLandscape)
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
                AppText("Reconnect Bluetooth", style: .header3)
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
        .navigationTitle("Reconnect Bluetooth")
        .navigationBarTitleDisplayMode(.inline)
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
        ReconnectingTutorialView()
            .environment(HeadsetSession())
    }
}
