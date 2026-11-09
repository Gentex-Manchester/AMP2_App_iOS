//
//  SettingRow.swift
//  AMP2_App_iOS
//

import SwiftUI

struct SettingRow<Destination: View>: View {

    let title: String
    let view: Destination

    init(title: String, @ViewBuilder view: () -> Destination) {
        self.title = title
        self.view = view()
    }

    var body: some View {
        NavigationLink {
            view
        } label: {
            HStack {
                AppText(title, style: .body)

                Spacer()

                Image(systemName: "chevron.right")
            }
            .foregroundColor(Color("OnSurface"))
            .padding(.vertical, 16)
            .padding(.horizontal)
            .frame(maxWidth: .infinity, minHeight: 72)
            .background(Color("Surface"))
            .cornerRadius(16)
        }
        .padding(.horizontal)
    }
}

#Preview {
    NavigationStack {
        SettingRow(title: "Preview") {
            Text("Preview Location")
        }
    }
}
