//
//  GentexAppearance.swift
//  AMP2_App_iOS
//
//  Nav bars, bar buttons, and segmented controls are UIKit and ignore SwiftUI
//  font modifiers; appearance proxies are the only way to reach them. Fonts
//  only. Alerts and confirmation dialogs can't be restyled by any public API.
//

import SwiftUI
import UIKit

enum GentexAppearance {

    /// Call once, from the app's `init()`.
    static func apply() {
        applyNavigationBar()
        applyBarButtons()
        applySegmentedControl()
    }

    // MARK: - Navigation bar

    private static func applyNavigationBar() {
        // Matches the `.principal` toolbar titles used elsewhere.
        guard let inline = font(.bold, 20, relativeTo: .headline),
              let large = font(.bold, 28, relativeTo: .largeTitle)
        else { return }

        let bar = UINavigationBar.appearance()

        // Mutate the existing appearances: a fresh one has an opaque background
        // and would make every bar solid at the scroll edge.
        for appearance in [
            bar.standardAppearance,
            bar.compactAppearance,
            bar.scrollEdgeAppearance,
            bar.compactScrollEdgeAppearance
        ].compactMap({ $0 }) {
            appearance.titleTextAttributes[.font] = inline
            appearance.largeTitleTextAttributes[.font] = large
        }
    }

    // MARK: - Bar buttons

    private static func applyBarButtons() {
        guard let regular = font(.regular, 18, relativeTo: .body) else { return }
        let attributes: [NSAttributedString.Key: Any] = [.font: regular]

        for state: UIControl.State in [.normal, .highlighted, .disabled] {
            UIBarButtonItem.appearance().setTitleTextAttributes(attributes, for: state)
        }

        let item = UIBarButtonItemAppearance(style: .plain)
        item.normal.titleTextAttributes = attributes
        item.highlighted.titleTextAttributes = attributes
        item.disabled.titleTextAttributes = attributes

        let bar = UINavigationBar.appearance()
        for appearance in [
            bar.standardAppearance,
            bar.compactAppearance,
            bar.scrollEdgeAppearance,
            bar.compactScrollEdgeAppearance
        ].compactMap({ $0 }) {
            appearance.buttonAppearance = item
            appearance.backButtonAppearance = item
            appearance.doneButtonAppearance = item
        }
    }

    // MARK: - Segmented control

    private static func applySegmentedControl() {
        guard let regular = font(.regular, 14, relativeTo: .subheadline) else { return }
        let attributes: [NSAttributedString.Key: Any] = [.font: regular]
        UISegmentedControl.appearance().setTitleTextAttributes(attributes, for: .normal)
        UISegmentedControl.appearance().setTitleTextAttributes(attributes, for: .selected)
    }

    // MARK: - Helpers

    /// Dynamic Type-scaled. Nil means `UIAppFonts` is missing from the built
    /// Info.plist (`INFOPLIST_KEY_*` silently drops keys outside Xcode's allowlist).
    private static func font(
        _ weight: IBMPlexSansWeight,
        _ size: CGFloat,
        relativeTo textStyle: UIFont.TextStyle
    ) -> UIFont? {
        guard let base = UIFont(name: weight.rawValue, size: size) else { return nil }
        return UIFontMetrics(forTextStyle: textStyle).scaledFont(for: base)
    }
}
