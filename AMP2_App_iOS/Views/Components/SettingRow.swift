//
//  ErrorBanner.swift
//  AMP2_App_iOS
//
//  Shows a failure, what to do about it, and a way to try again.
//  Shows both `errorDescription` and `recoverySuggestion`, so a failure never
//  looks like an empty state.
//

import SwiftUI

struct SettingRow: View {
    let title: String
    var route: SettingsRoute

    init(title: String, route: SettingsRoute) {
        self.title = title
        self.route = route
    }
    
    var body : some View {
        NavigationLink(value: route) {
            HStack {
                Text(title)
                    .font(.ibmPlexSans(size: 20))

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
