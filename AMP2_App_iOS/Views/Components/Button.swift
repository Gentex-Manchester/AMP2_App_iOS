//
//  Button.swift
//  AMP2_App_iOS
//
//  Created by Peter Sargent on 10/28/26.
//

import SwiftUI

struct PrimaryButton: View {
    let label: String
    let enabled: Bool
    let action: () -> Void

    init(
        label: String,
        enabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.label = label
        self.enabled = enabled
        self.action = action
    }
    
    var body : some View {
        Button(action: action) {
            AppText(label, style: .body)
                .foregroundColor(enabled ? Color("OnPrimary") : Color("OnError"))
                .frame(maxWidth: .infinity, minHeight: 72)
                .background(enabled ? Color("Primary") : Color("Error"))
                .cornerRadius(16)
        }
        .disabled(!enabled)
    }
}

struct SecondaryButton: View {
    // Uses surface color scheme
    let label: String
    let enabled: Bool
    let action: () -> Void

    init(
        label: String,
        enabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.label = label
        self.enabled = enabled
        self.action = action
    }
    
    var body : some View {
        Button(action: action) {
            AppText(label, style: .body)
                .foregroundColor(Color("OnSurface"))
                .frame(maxWidth: .infinity, minHeight: 72)
                .background(Color("Surface"))
                .cornerRadius(16)
        }
        .disabled(!enabled)
    }
}

struct SelectionButton: View {
    // Uses primary and secondary color schemes (on/off)
    let label: String
    let enabled: Bool
    let selected: Bool
    let action: () -> Void

    init(
        label: String,
        enabled: Bool = true,
        selected: Bool,
        action: @escaping () -> Void
    ) {
        self.label = label
        self.enabled = enabled
        self.selected = selected
        self.action = action
    }
    
    var body : some View {
        Button(action: action) {
            AppText(label, style: .body)
                .foregroundColor(selected ? Color("OnPrimary") : Color("OnSecondary"))
                .frame(maxWidth: .infinity, minHeight: 72)
                .background(selected ? Color("Primary") : Color("Secondary"))
                .cornerRadius(16)
        }
        .disabled(!enabled)
    }
}

#Preview {
    VStack {
        PrimaryButton(label: "Primary Button", action: {})
        PrimaryButton(label: "Primary Button (Disabled)", enabled: false, action: {})
        SecondaryButton(label: "Secondary Button", action: {})
        SelectionButton(label: "Selection Button (Selected)", selected: true, action: {})
        SelectionButton(label: "Selection Button (Deselected)", selected: false, action: {})
    }
}
