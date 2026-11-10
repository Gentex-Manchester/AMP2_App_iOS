//
//  BottomControls.swift
//  AMP2_App_iOS
//
//  Created by Peter Sargent on 11/4/26.
//

import SwiftUI

enum BottomControlsType {
    case standard
    case first
    case last
}

struct BottomControls: View {
    let type: BottomControlsType
    let goBack: () -> Void
    let goForward: () -> Void
    
    var body: some View {
        HStack(spacing: 18) {
            if (type == .first) {
                Spacer()
                    .frame(maxWidth: .infinity)
            } else {
                SecondaryButton(label: String(localized: "Back")) {
                    goBack()
                }
            }
            
            if (type == .last) {
                Spacer()
                    .frame(maxWidth: .infinity)
            } else {
                PrimaryButton(label: String(localized: "Next")) {
                    goForward()
                }
            }
        }
    }
}

#Preview {
    BottomControls(type: .first, goBack: {}, goForward: {})
    BottomControls(type: .standard, goBack: {}, goForward: {})
    BottomControls(type: .last, goBack: {}, goForward: {})
}
