//
//  TutorialLayout.swift
//  AMP2_App_iOS
//
//  Created by Peter Sargent on 11/4/26.
//

import SwiftUI

@ViewBuilder
func stepContent(_ step: TutorialStep, isLandscape: Bool) -> some View {
    if isLandscape {
        landscapeLayout(step)
    } else {
        portraitLayout(step)
    }
}

func portraitLayout(_ step: TutorialStep) -> some View {
    ScrollView {
        VStack(spacing: 24) {
            if step.media.type == .image {
                ImageView(
                    media: step.media,
                    configuration: MediaConfiguration(
                        contentMode: .fit,
                        height: 250
                    )
                )
            }

            AppText(step.title, style: .header2)
                .multilineTextAlignment(.center)

            if !step.description.isEmpty {
                AppText(step.description, style: .body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal)
    }
}

func landscapeLayout(_ step: TutorialStep) -> some View {
    ScrollView {
        HStack(spacing: 32) {
            if step.media.type == .image {
                ImageView(
                    media: step.media,
                    configuration: MediaConfiguration(
                        contentMode: .fit,
                        height: 200
                    )
                )
            }

            VStack(spacing: 16) {
                AppText(step.title, style: .header2)
                    .multilineTextAlignment(.center)

                if !step.description.isEmpty {
                    AppText(step.description, style: .body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal)
    }
}
