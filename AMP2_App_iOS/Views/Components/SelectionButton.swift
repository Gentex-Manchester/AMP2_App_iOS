//
//  SelectionButton.swift
//  AMP2_App_iOS
//
//  Created by Peter Sargent on 10/28/26.
//

import SwiftUI

struct SelectionButton: View {
    let label: String
    let selected: Bool
    let action: () -> Void

    init(
        label: String,
        selected: Bool,
        action: @escaping () -> Void
    ) {
        self.label = label
        self.selected = selected
        self.action = action
    }
    
    var body : some View {
        Button(action: action) {
            HStack {
                Spacer()
                Text(label)
                    .font(.ibmPlexSans(size: 20))
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.vertical, 16)
            .padding(.horizontal)
            .frame(maxWidth: .infinity)
            .background(selected ? Color.opsCoreRed : Color.opsCoreRed.opacity(0.50))
            .cornerRadius(16)
        }
    }
}
