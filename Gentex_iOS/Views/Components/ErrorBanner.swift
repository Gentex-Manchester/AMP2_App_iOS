//
//  ErrorBanner.swift
//  Gentex_iOS
//
//  Shows a failure, what to do about it, and a way to try again.
//  Shows both `errorDescription` and `recoverySuggestion`, so a failure never
//  looks like an empty state.
//

import SwiftUI

struct ErrorBanner: View {
    let title: String
    let message: String
    var recovery: String?
    var retry: (() -> Void)?

    /// Builds from any error, using `LocalizedError`'s two halves when present.
    init(title: String, error: Error, retry: (() -> Void)? = nil) {
        self.title = title
        self.message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        self.recovery = (error as? LocalizedError)?.recoverySuggestion
        self.retry = retry
    }

    init(title: String, message: String, recovery: String? = nil, retry: (() -> Void)? = nil) {
        self.title = title
        self.message = message
        self.recovery = recovery
        self.retry = retry
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.opsCoreRed)

                Text(title)
                    .font(.ibmPlexSans(size: 18, weight: .bold))
            }

            Text(message)
                .font(.ibmPlexSans(size: 15))
                .fixedSize(horizontal: false, vertical: true)

            if let recovery {
                Text(recovery)
                    .font(.ibmPlexSans(size: 15))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let retry {
                Button(action: retry) {
                    Text("Try Again")
                        .font(.ibmPlexSans(size: 18))
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(Color.opsCoreRed)
                        .cornerRadius(16)
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray5))
        .cornerRadius(16)
    }
}

#Preview("With recovery and retry") {
    ErrorBanner(
        title: "Couldn't load teams",
        error: DatabaseError.databaseOpenError(
            underlying: NSError(domain: "preview", code: 1,
                                userInfo: [NSLocalizedDescriptionKey: "file is not a database"])
        ),
        retry: {}
    )
    .padding()
}

#Preview("Message only") {
    ErrorBanner(title: "Couldn't join team", message: "Connect a headset to join a team.")
        .padding()
}
