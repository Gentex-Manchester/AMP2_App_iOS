//
//  AppearanceMode.swift
//  AMP2_App_iOS
//
//  Created by Peter Sargent on 11/4/26.
//

import Foundation

enum AppearanceMode: String, CaseIterable, Codable {
    case system
    case light
    case dark
    
    var displayName: String {
        switch self {
        case .system:
            String(localized: "System")
        case .light:
            String(localized: "Light")
        case .dark:
            String(localized: "Dark")
        }
    }
}
