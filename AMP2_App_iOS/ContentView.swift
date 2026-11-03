//
//  ContentView.swift
//  AMP2_App_iOS
//
//  Created by aaron stockdale on 6/18/26.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("orientationMode") private var orientationMode: OrientationMode = .portrait
    @State private var showDisconnectedAlert = false
    @Environment(HeadsetSession.self) private var headsetSession
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            Group {
                if headsetSession.state.isConnected {
                    ConnectedView()
                } else {
                    DisconnectedView()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: headsetSession.state) { previous, current in
            handleConnectionChange(from: previous, to: current)
        }
        .onChange(of: scenePhase) { _, _ in
            // Restarts discovery when the app returns to the foreground
            headsetSession.startDiscovery()
        }
        .alert("Headset disconnected", isPresented: $showDisconnectedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(
                """
                The link to your headset dropped. The app is looking for \
                it again and reconnects on its own once the headset is \
                back in range.
                """
            )
        }
    }

    // MARK: - Losing the headset

    /// Alerts on an unplanned disconnect and pops headset-only screens.
    /// Disconnecting from the packet console is intentional and skips the alert.
    private func handleConnectionChange(
        from previous: HeadsetConnectionState,
        to current: HeadsetConnectionState
    ) {
        guard previous.isConnected, !current.isConnected else { return }
        guard !headsetSession.isIntentionallyDisconnected else { return }
        
        showDisconnectedAlert = true
    }

    private func usesLandscapeLayout(for size: CGSize) -> Bool {
        switch orientationMode {
        case .system: return size.width > size.height
        case .portrait: return false
        case .landscape: return true
        }
    }
}

#Preview {
    let session = HeadsetSession()
    let sync = HeadsetSettingsSync(transport: session)
    ContentView()
        .environment(session)
        .environment(sync)
}
