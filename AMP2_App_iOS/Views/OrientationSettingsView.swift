//
//  OrientationSettingsView.swift
//  AMP2_App_iOS
//
//  Created by aaron stockdale on 6/23/26.
//

import SwiftUI

struct OrientationSettingsView: View {
    @AppStorage("orientationMode") private var orientationMode: OrientationMode = .portrait

    var body: some View {
        ScrollView {
            SelectionButtonRow(
                options: OrientationMode.allCases,
                selection: $orientationMode,
                onSelection: { selection in
                    orientationMode = selection
                },
                label: { option in
                    option.rawValue
                }
            )
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
                AppText("Orientation", style: .header3)
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
