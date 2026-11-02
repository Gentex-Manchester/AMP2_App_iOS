//
//  OrientationSettingsView.swift
//  AMP2_App_iOS
//
//  Created by aaron stockdale on 6/23/26.
//

import SwiftUI

enum OrientationMode: String, CaseIterable, Codable {
    case system = "System"
    case portrait = "Portrait"
    case landscape = "Landscape"
    
    var supportedOrientations: UIInterfaceOrientationMask {
        switch self {
        case .system: return .all
        case .portrait: return .portrait
        case .landscape: return .landscape
        }
    }
    
    var lockedInterfaceOrientation: UIInterfaceOrientation? {
        switch self {
        case .system: return nil
        case .portrait: return .portrait
        case .landscape: return .landscapeRight
        }
    }
}

struct OrientationSettingsView: View {
    @AppStorage("orientationMode") private var orientationMode: OrientationMode = .portrait

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                HStack(spacing: 10){
                    SelectionButton(
                        label: "System",
                        selected: orientationMode == .system,
                        action: { setOrientation(.system) }
                    )
                    
                    SelectionButton(
                        label: "Portrait",
                        selected: orientationMode == .portrait,
                        action: { setOrientation(.portrait) }
                    )
                }
                
                HStack(spacing: 10) {
                    SelectionButton(
                        label: "Landscape",
                        selected: orientationMode == .landscape,
                        action: { setOrientation(.landscape) }
                    )
                    
                    Spacer()
                        .frame(maxWidth: .infinity)
                        .padding(.trailing)
                }
            }
            .frame(
                maxWidth: .infinity,
                alignment: .top
            )
            .padding(
                .horizontal, 16
            )
        }
        .navigationTitle("Orientation")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Orientation")
                    .font(.ibmPlexSans(size: 28, weight: .bold))
            }
        }
    }
    
    private func setOrientation(_ mode: OrientationMode) {
        orientationMode = mode
        OrientationLock.supportedOrientations = mode.supportedOrientations
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        
        windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: mode.supportedOrientations))
        windowScene.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
        
        if let interfaceOrientation = mode.lockedInterfaceOrientation {
            // Legacy fallback.
            UIDevice.current.setValue(interfaceOrientation.rawValue, forKey: "orientation")
        } else {
            windowScene.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
        }
    }
}

#Preview {
    NavigationStack {
        OrientationSettingsView()
    }
}
