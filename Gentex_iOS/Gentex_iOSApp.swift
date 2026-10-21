//
//  Gentex_iOSApp.swift
//  Gentex_iOS
//
//  Created by aaron stockdale on 6/18/26.
//

import SwiftUI

// MARK: - Orientation Manager

final class OrientationLock {
    static var supportedOrientations: UIInterfaceOrientationMask = .all
}

// MARK: - App Delegate

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        return OrientationLock.supportedOrientations
    }
}

// MARK: - UI test hooks

#if DEBUG
/// UI-test launch arguments for states the simulator can't reach. With no
/// Bluetooth radio, the Connect button that opens the walkthrough stays disabled.
enum UITestFlags {
    /// Opens the pairing walkthrough as soon as the disconnected screen appears.
    static let openPairingTutorial = "-uiTestOpenPairingTutorial"

    static var isSet: (String) -> Bool {
        { ProcessInfo.processInfo.arguments.contains($0) }
    }
}
#endif

// MARK: - App

@main
struct Gentex_iOSApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    @AppStorage("orientationMode") private var orientationMode: OrientationMode = .portrait

    /// The app's only observable objects; see requirements/ble-parity-plan.md
    /// decision 0.4.
    @State private var headsetSession: HeadsetSession
    @State private var headsetSettings: HeadsetSettingsSync

    init() {
        // UIKit chrome ignores SwiftUI font modifiers.
        GentexAppearance.apply()

        let session = HeadsetSession()
        _headsetSession = State(initialValue: session)
        _headsetSettings = State(initialValue: HeadsetSettingsSync(transport: session))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(headsetSession)
                .environment(headsetSettings)
                .preferredColorScheme(colorScheme)
                .onAppear {
                    applyOrientation()
                    headsetSession.startDiscovery()
                }
                // Pairing happens in Settings, so returning to the app is when a
                // newly paired headset first becomes visible.
                .onChange(of: scenePhase) { _, phase in
                    guard phase == .active,
                          headsetSession.state != .connected,
                          headsetSession.state != .connecting,
                          !headsetSession.isDiscovering,
                          !headsetSession.isIntentionallyDisconnected
                    else { return }
                    headsetSession.startDiscovery()
                }
                .onChange(of: orientationMode) { _, _ in
                    applyOrientation()
                }
        }
    }
    
    private var colorScheme: ColorScheme? {
        switch appearanceMode {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
    
    private func applyOrientation() {
        OrientationLock.supportedOrientations = orientationMode.supportedOrientations
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        
        windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: orientationMode.supportedOrientations))
        
        windowScene.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
    }
}
