//
//  DisconnectedView.swift
//  AMP2_App_iOS
//
//  Created by aaron stockdale on 6/18/26.
//

import SwiftUI

struct DisconnectedView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(HeadsetSession.self) private var session
    @State private var showTutorial = false
    @State private var showConnectionIssuePopup = false

    var isLandscape: Bool { verticalSizeClass == .compact }

    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 16) {
                    Image("headset_silhouette")
                        .resizable()
                        .scaledToFit()
                        // Smaller in landscape so the text fits without scrolling.
                        .frame(maxHeight: isLandscape ? 130 : 250)
                    
                    // Without padding the text clips beside the landscape sidebar.
                    AppText("No AMP connected", style: .header2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    AppText("To use this app, you must connect to an AMP 2.0 headset, like the AMP 2.0 Elite headset.", style: .body)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    // No scan-failure hint: it flickered with each background
                    // retry, and the walkthrough covers it.
                }
                .frame(maxWidth: . infinity, alignment: .top)
                .padding(.top, 10)
            }
            // 30% of the spare space above, 70% below. Taller content scrolls.
            .defaultScrollAnchor(UnitPoint(x: 0.5, y: 0.3), for: .alignment)
            .scrollBounceBehavior(.basedOnSize)
            
            Spacer()
            
            PrimaryButton(
                label: buttonTitle,
                action: {
                    if (radioFault == nil) {
                        showTutorial = true
                    } else {
                        showConnectionIssuePopup = true
                    }
                }
            )
            .padding(.horizontal, 26)
            .padding(.bottom, isLandscape ? 16 : 40)
        }
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                AppText("Home", style: .header3)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    AppSettingsView()
                } label: {
                    Image("settings_24px")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
            }
        }
        .fullScreenCover(isPresented: $showTutorial) {
            NavigationStack {
                if session.savedHeadset != nil {
                    // If a headset has been connected to the app before
                    // May not necessarily still be paired with the phone
                    ReconnectingTutorialView()
                } else {
                    PairingTutorialView()
                }
            }
        }
        .alert("Unable to connect", isPresented: $showConnectionIssuePopup) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(radioFault?.localizedDescription ?? "") +
            Text("\n") +
            Text(radioFault?.recoverySuggestion ?? "")
        }
        #if DEBUG
        .onAppear {
            // See `UITestFlags`: without a Bluetooth radio the button above is
            // disabled, so an automated run has no other way in.
            if UITestFlags.isSet(UITestFlags.openPairingTutorial) {
                showTutorial = true
            }
        }
        #endif
    }

    // MARK: - Bluetooth radio state

    /// Bluetooth itself unusable, as opposed to no headset nearby.
    /// Leads the screen so users don't hunt for a headset problem.
    private var radioFault: HeadsetError? {
        guard case .failed(let error) = session.state else { return nil }
        switch error {
        case .bluetoothPoweredOff, .bluetoothUnauthorized, .bluetoothUnsupported:
            return error
        default:
            return nil
        }
    }

    private var buttonTitle: String {
        if radioFault != nil { return "Bluetooth unavailable" }
        return "Connect over Bluetooth"
    }
}


#Preview {
    let session = HeadsetSession()
    let sync = HeadsetSettingsSync(transport: session)
    ContentView()
        .environment(session)
        .environment(sync)
}
