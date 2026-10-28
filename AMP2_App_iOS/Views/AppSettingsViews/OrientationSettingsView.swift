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
    @AppStorage("sidebarSide") private var sidebarSide: String = "left"

    var body: some View {
        ScrollView {
            VStack {
                Text("Screen Orientation")
                    .font(.ibmPlexSans(size: 28, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 50)
                    .padding(.bottom, 10)
                    .padding(.leading, 22)
                
                HStack(spacing: 10) {
                    Button(action: { setOrientation(.system) }) {
                        HStack {
                            Spacer()
                            Text("System")
                                .font(.ibmPlexSans(size: 20))
                            Spacer()
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 16)
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity)
                        .background(orientationMode == .system ? Color.opsCoreRed : Color.opsCoreRed.opacity(0.50))
                        .cornerRadius(16)
                    }
                    .padding(.leading)
                    .padding(.bottom, 10)
                    
                    Button(action: { setOrientation(.portrait) }) {
                        HStack {
                            Spacer()
                            Text("Portrait")
                                .font(.ibmPlexSans(size: 20))
                            Spacer()
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 16)
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity)
                        .background(orientationMode == .portrait ? Color.opsCoreRed : Color.opsCoreRed.opacity(0.50))
                        .cornerRadius(16)
                    }
                    .padding(.trailing)
                    .padding(.bottom, 10)
                }

                HStack(spacing: 10) {
                    Button(action: { setOrientation(.landscape) }) {
                        HStack {
                            Spacer()
                            Text("Landscape")
                                .font(.ibmPlexSans(size: 20))
                            Spacer()
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 16)
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity)
                        .background(orientationMode == .landscape ? Color.opsCoreRed : Color.opsCoreRed.opacity(0.50))
                        .cornerRadius(16)
                    }
                    .padding(.leading)

                    Spacer()
                        .frame(maxWidth: .infinity)
                        .padding(.trailing)
                }
                .padding(.bottom, 10)

                Text("Landscape Navigation")
                    .font(.ibmPlexSans(size: 28, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 30)
                    .padding(.bottom, 10)
                    .padding(.leading, 22)
                
                HStack(spacing: 10) {
                    Button(action: { sidebarSide = "left" }) {
                        HStack {
                            Spacer()
                            Text("Left")
                                .font(.ibmPlexSans(size: 20))
                            Spacer()
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 16)
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity)
                        .background(sidebarSide == "left" ? Color.opsCoreRed : Color.opsCoreRed.opacity(0.50))
                        .cornerRadius(16)
                    }
                    .padding(.leading)

                    Button(action: { sidebarSide = "right" }) {
                        HStack {
                            Spacer()
                            Text("Right")
                                .font(.ibmPlexSans(size: 20))
                            Spacer()
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 16)
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity)
                        .background(sidebarSide == "right" ? Color.opsCoreRed : Color.opsCoreRed.opacity(0.50))
                        .cornerRadius(16)
                    }
                    .padding(.trailing)
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)
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
