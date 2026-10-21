//
//  UserManualsView.swift
//  Gentex_iOS
//

import SwiftUI

struct UserManualsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                linkButton(title: "Introduction", url: "https://example.com")
                linkButton(title: "Using LTC", url: "https://example.com")
                linkButton(title: "Using Bluetooth", url: "https://example.com")
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .padding(.top, 10)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("User Manuals")
                    .font(.ibmPlexSans(size: 28, weight: .bold))
            }
        }
    }

    private func linkButton(title: String, url: String) -> some View {
        Link(destination: URL(string: url)!) {
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
    }
}

#Preview {
    UserManualsView()
}
