//
//  TroubleshootingPopup.swift
//  AMP2_App_iOS
//
//  Created by Peter Sargent on 11/5/26.
//

import SwiftUI

struct TroubleshootingPopup: View {
    let title: String
    let text: String

    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented = true
        } label: {
            AppText(title, style: .body)
                .foregroundStyle(.primary)
                .underline()
                .multilineTextAlignment(.leading)
        }
        .foregroundStyle(.accent)
        .alert(title,isPresented: $isPresented) {
            Button("Continue", role: .cancel) { }
        } message: {
            Text(text)
        }
    }
}

#Preview {
    TroubleshootingPopup(
        title: "Test Title",
        text: "Test Text"
    )
}
