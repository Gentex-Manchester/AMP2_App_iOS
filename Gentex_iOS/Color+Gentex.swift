//
//  Color+Gentex.swift
//  Gentex_iOS
//
//  Ops-Core palette. Never use `Color.red`: it's the system red, not the
//  brand red, and shifts between OS releases. Keep in step with Android
//  `ui/graphics/color/Color.kt`.
//

import SwiftUI

extension Color {

    // MARK: - Brand

    /// Brand red #E31B23, the primary accent. Android `OpsCoreRed`.
    static let opsCoreRed = Color(red: 227 / 255, green: 27 / 255, blue: 35 / 255)

    /// #3D2525, Android `OpsCoreDarkRed`. For a solid deselected fill; most
    /// places use `opsCoreRed.opacity(0.50)` instead.
    static let opsCoreDarkRed = Color(red: 61 / 255, green: 37 / 255, blue: 37 / 255)

    /// #707372, Android `OpsCoreGray`.
    static let opsCoreGray = Color(red: 112 / 255, green: 115 / 255, blue: 114 / 255)

    // MARK: - Status

    /// #00C853, Android `ActiveGreen`.
    static let activeGreen = Color(red: 0, green: 200 / 255, blue: 83 / 255)
}
