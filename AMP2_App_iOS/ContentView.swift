//
//  ContentView.swift
//  AMP2_App_iOS
//
//  Created by aaron stockdale on 6/18/26.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("orientationMode") private var orientationMode: OrientationMode = .portrait
    @State private var headsetNavigationPath: [Route] = []
    @State private var showDisconnectedAlert = false
    @Environment(HeadsetSession.self) private var headsetSession

    var body: some View {
        GeometryReader { outer in
            let landscape = usesLandscapeLayout(for: outer.size)

            // Safe area only
            GeometryReader { inner in
                let insets = inner.safeAreaInsets

                // Content keeps one structural position
                // A VStack/HStack branch would reset state on every rotation
                // (Gentex lost their place in the pairing flow).
                HeadsetView(headsetNavigationPath: $headsetNavigationPath)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .onChange(of: headsetSession.state) { previous, current in
                handleConnectionChange(from: previous, to: current)
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

        headsetNavigationPath.popHeadsetOnlyScreens()
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
