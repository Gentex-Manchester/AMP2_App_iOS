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
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 70)
                .background(Color.accent)
                .cornerRadius(16)
        }
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.50)
    }
}

struct SecondaryButton: View {
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
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 70)
                .background(Color(.systemGray2))
                .cornerRadius(16)
        }
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.50)
    }
}

struct SelectionButton: View {
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
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 70)
                .background(selected ? Color.accent : Color.accent.opacity(0.50))
                .cornerRadius(16)
        }
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.50)
    }
}

#Preview {
    VStack {
        PrimaryButton(label: "Primary Button", action: {})
        SecondaryButton(label: "Secondary Button", action: {})
        SelectionButton(label: "Selection Button (Selected)", selected: true, action: {})
        SelectionButton(label: "Selection Button (Deselected)", selected: false, action: {})
    }
}
