//
//  OrientationMode.swift
//  AMP2_App_iOS
//
//  Created by Peter Sargent on 11/4/26.
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
