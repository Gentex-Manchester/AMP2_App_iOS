//
//  PairingTutorialView.swift
//  AMP2_App_iOS
//

import SwiftUI

struct PairingTutorialView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(HeadsetSession.self) private var session
    
    @State private var currentStep = 0
    @State private var showPairingScreen = false

    private var isLandscape: Bool { verticalSizeClass == .compact }
    private var steps: [TutorialStep] { pairingSteps }

    var body: some View {
        VStack(spacing: 0) {
            stepContent(steps[currentStep], isLandscape: isLandscape)
                .frame(maxHeight: .infinity)
                .scrollBounceBehavior(.basedOnSize)
            Spacer(minLength: 0)
            BottomControls(
                type: steps[currentStep].controls,
                goBack: goBack,
                goForward: {
                    if (currentStep < pairingSteps.count - 1) {
                        currentStep += 1
                    } else { // Last step
                        showPairingScreen = true
                    }
                }
            )
            .padding(.horizontal, 26)
        }
        // Connecting ends the tutorial, as on Android.
        .onChange(of: session.state) { _, newState in
            if newState.isConnected { dismiss() }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Bluetooth Pairing")
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
        .fullScreenCover(isPresented: $showPairingScreen) {
            NavigationStack {
                SelectDeviceView()
            }
        }
        .navigationTitle("Bluetooth Pairing")
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
        PairingTutorialView()
            .environment(HeadsetSession())
    }
}
