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
                        width: 250,
                        height: 250
                    )
                )
            } else if step.media.type == .gif {
                GIFImageView(
                    media: step.media,
                    configuration: MediaConfiguration(
                        contentMode: .fit,
                        width: 250,
                        height: 250
                    )
                )
            }

            AppText(step.title, style: .header2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)

            if !step.description.isEmpty {
                AppText(step.description, style: .body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(.horizontal)
    }
}

func landscapeLayout(_ step: TutorialStep) -> some View {
    HStack(spacing: 32) {
        if step.media.type == .image {
            ImageView(
                media: step.media,
                configuration: MediaConfiguration(
                    contentMode: .fit,
                    width: 200,
                    height: 200
                )
            )
        } else if step.media.type == .gif {
            GIFImageView(
                media: step.media,
                configuration: MediaConfiguration(
                    contentMode: .fit,
                    width: 200,
                    height: 200
                )
            )
        }

        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 24) {
                    AppText(step.title, style: .header2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)

                    if !step.description.isEmpty {
                        AppText(step.description, style: .body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .multilineTextAlignment(.leading)
                    }
                }
                .frame(
                    maxWidth: .infinity,
                    minHeight: geometry.size.height,
                    alignment: .center
                )
            }
        }
    }
    .padding(.horizontal)
}
