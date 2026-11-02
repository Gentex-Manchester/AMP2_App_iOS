//
//  PermissionData.swift
//  AMP2_App_iOS
//

import AVFoundation
import CoreBluetooth
import Foundation

enum PermissionType: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case bluetooth

    var buttonTitle: String {
        switch self {
        case .bluetooth: return "Bluetooth Permissions"
        }
    }

    var data: PermissionData {
        switch self {
        case .bluetooth:
            return PermissionData(
                imageName: "Bluetooth (Dark)",
                title: "This app needs permission to use Bluetooth",
                description: ""
            )
        }
    }

    /// Read live, not cached; the user can change it in Settings while backgrounded.
    var status: PermissionStatus {
        switch self {
        case .bluetooth:
            switch CBManager.authorization {
            case .allowedAlways: return .allowed
            case .denied: return .denied
            case .restricted: return .restricted
            case .notDetermined: return .notRequested
            @unknown default: return .notRequested
            }
        }
    }
}

/// Bluetooth and camera authorization flattened into one type for the badge.
enum PermissionStatus {
    case allowed
    case denied
    case restricted
    case notRequested

    var label: String {
        switch self {
        case .allowed: return "Allowed"
        case .denied: return "Not allowed"
        case .restricted: return "Restricted"
        case .notRequested: return "Not requested"
        }
    }

    var isUsable: Bool { self == .allowed }
}

struct PermissionData {
    let imageName: String
    let title: String
    let description: String
}
