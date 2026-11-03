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

struct AppText: View {

    let string: String
    let style: AppTextStyle

    init(_ string: String, style: AppTextStyle) {
        self.string = string
        self.style = style
    }

    var body: some View {
        Text(string)
            .font(font)
    }

    private var font: Font {
        return style.font
    }
}

#Preview {
    AppText("Header 1", style: .header1)
    AppText("Header 2", style: .header2)
    AppText("Header 3", style: .header3)
    AppText("Body", style: .body)
    AppText("Subbody", style: .subbody)
}
