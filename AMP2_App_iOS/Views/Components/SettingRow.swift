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
            .foregroundColor(.primary)
            .padding(.vertical, 16)
            .padding(.horizontal)
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray4))
            .cornerRadius(16)
        }
        .padding(.horizontal)
        .padding(.bottom, 10)
    }
}

#Preview {
    NavigationStack {
        SettingRow(title: "Preview") {
            Text("Preview Location")
        }
    }
}
