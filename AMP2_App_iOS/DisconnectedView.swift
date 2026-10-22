//
//  ContentView.swift
//  AMP2_App_iOS
//
//  Created by aaron stockdale on 6/18/26.
//

import SwiftUI

struct DisconnectedView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(HeadsetSession.self) private var session
    @State private var showTutorial = false

    var isLandscape: Bool { verticalSizeClass == .compact }

    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 16) {
                    Image("Connect Device")
                        .resizable()
                        .scaledToFit()
                        // Smaller in landscape so the text fits without scrolling.
                        .frame(maxHeight: isLandscape ? 130 : 250)
                    
                    // Without padding the text clips beside the landscape sidebar.
                    Text(headline)
                        .font(.ibmPlexSans(size: 22, weight: .bold))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Text(explanation)
                        .font(.ibmPlexSans(size: 20))
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
            
            Spacer()
            
            Button(action: {
                // Scan first; a headset already connected in Settings needs no
                // walkthrough. Show it only when nothing turns up.
                if session.discoveredHeadsets.isEmpty && !session.isDiscovering {
                    session.startDiscovery()
                } else {
                    showTutorial = true
                }
            }) {
                Text(buttonTitle)
                    .font(.ibmPlexSans(size: 20))
                    .foregroundColor(.white)
                    // Android GentexPrimaryButton (64dp tall, 24dp margins)
                    // ×1.1, since an Android dp draws ~10% larger.
                    .frame(maxWidth: .infinity, minHeight: 70)
                    .background(Color.opsCoreRed)
                    .cornerRadius(16)
                    .padding(.horizontal, 26)
                    .padding(.bottom, isLandscape ? 16 : 40)
            }
            // Scanning with the radio down just fails; a dead button looks like an app bug.
            .disabled(radioFault != nil)
            .opacity(radioFault == nil ? 1 : 0.50)
        }
        .fullScreenCover(isPresented: $showTutorial) {
            ConnectionTutorialView()
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

    private var headline: String {
        if let description = radioFault?.errorDescription {
            return description
        }
        return session.isDiscovering ? "Looking for your headset…" : "No headset connected"
    }

    private var explanation: String {
        if let suggestion = radioFault?.recoverySuggestion {
            return suggestion
        }
        return "To use this app, you must connect to an AMP 2.0 headset, like the AMP 2.0 Elite headset."
    }

    private var buttonTitle: String {
        if radioFault != nil { return "Bluetooth unavailable" }
        return session.isDiscovering ? "Searching…" : "Connect over Bluetooth"
    }
}


#Preview {
    let session = HeadsetSession()
    let sync = HeadsetSettingsSync(transport: session)
    ContentView()
        .environment(session)
        .environment(sync)
}
