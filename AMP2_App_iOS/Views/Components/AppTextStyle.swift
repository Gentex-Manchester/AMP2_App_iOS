//
//  GentexText.swift
//  AMP2_App_iOS
//
//  Created by Peter Sargent on 11/3/26.
//

import SwiftUI

enum AppTextStyle {
    case header1
    case header2
    case header3
    case body
    case subbody
    
    var font: Font {
        switch self {
        case .header1:
            return .ibmPlexSans(size: 48, weight: .semiBold)
        case .header2:
            return .ibmPlexSans(size: 36, weight: .bold)
        case .header3:
            return .ibmPlexSans(size: 24, weight: .bold)
        case .body:
            return .ibmPlexSans(size: 24, weight: .medium)
        case .subbody:
            return .ibmPlexSans(size: 16, weight: .semiBold)
        }
    }
}

extension View {
    func appTextStyle(_ style: AppTextStyle) -> some View {
        self.font(style.font)
    }
}

#Preview {
    Text("Header 1")
        .appTextStyle(.header1)
    Text("Header 2")
        .appTextStyle(.header2)
    Text("Header 3")
        .appTextStyle(.header3)
    Text("Body")
        .appTextStyle(.body)
    Text("Subbody")
        .appTextStyle(.subbody)
}
