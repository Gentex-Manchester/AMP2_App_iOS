//
//  Font+IBMPlexSans.swift
//  AMP2_App_iOS
//
//  IBM Plex Sans by PostScript name, one per weight.
//

import SwiftUI

/// Raw values are **PostScript** names, not filenames. IBM abbreviates four
/// (`IBMPlexSans`, `-Medm`, `-SmBld`, `-ExtLt`); a wrong name silently falls
/// back to the system font. Check against the file, never from memory:
///
/// ```
/// python3 -c "from fontTools.ttLib import TTFont; \
///   print(TTFont('Fonts/IBMPlexSans-Regular.ttf')['name'].getDebugName(6))"
/// ```
enum IBMPlexSansWeight: String {
    case thin = "IBMPlexSans-Thin"
    case extraLight = "IBMPlexSans-ExtLt"
    case light = "IBMPlexSans-Light"
    case regular = "IBMPlexSans"
    case text = "IBMPlexSans-Text"
    case medium = "IBMPlexSans-Medm"
    case semiBold = "IBMPlexSans-SmBld"
    case bold = "IBMPlexSans-Bold"
}

extension Font {

    /// `size` is the point size at the default text setting. `relativeTo:` makes
    /// it scale with Dynamic Type, as Android's `sp` does; plain
    /// `Font.custom(_:size:)` stays fixed. `textStyle` defaults to the nearest match.
    static func ibmPlexSans(
        size: CGFloat,
        weight: IBMPlexSansWeight = .regular,
        relativeTo textStyle: Font.TextStyle? = nil
    ) -> Font {
        .custom(
            weight.rawValue,
            size: size,
            relativeTo: textStyle ?? scalingStyle(for: size)
        )
    }

    /// Bold or regular, e.g. for a selected state.
    static func ibmPlexSans(
        size: CGFloat,
        bold: Bool,
        relativeTo textStyle: Font.TextStyle? = nil
    ) -> Font {
        ibmPlexSans(
            size: size,
            weight: bold ? .bold : .regular,
            relativeTo: textStyle
        )
    }

    /// Nearest iOS text style by default point size. Styles scale at different
    /// rates, so this keeps the type hierarchy intact as text grows.
    private static func scalingStyle(for size: CGFloat) -> Font.TextStyle {
        switch size {
        case ..<12: return .caption2      // 11
        case ..<13: return .caption       // 12
        case ..<14: return .footnote      // 13
        case ..<16: return .subheadline   // 14–15
        case ..<17: return .callout       // 16
        case ..<19: return .body          // 17–18
        case ..<22: return .title3        // 19–21
        case ..<26: return .title2        // 22–25
        case ..<32: return .title         // 26–31
        default: return .largeTitle       // 32+
        }
    }
}
