//
//  OrientationMode.swift
//  AMP2_App_iOS
//
//  Created by Peter Sargent on 11/4/26.
//

import SwiftUI

enum OrientationMode: String, CaseIterable, Codable {
    case system
    case portrait
    case landscape
    
    var displayName: String {
        switch self {
        case .system:
            String(localized: "System")
        case .portrait:
            String(localized: "Portrait")
        case .landscape:
            String(localized: "Landscape")
        }
    }
    
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
