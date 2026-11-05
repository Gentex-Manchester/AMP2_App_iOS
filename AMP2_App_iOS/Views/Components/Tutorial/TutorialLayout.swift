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

private func portraitLayout(_ step: TutorialStep) -> some View {
    ScrollView {
        VStack(spacing: 24) {
            imageContent(step)
            textContent(step)
        }
        .padding(.horizontal)
    }
}

private func landscapeLayout(_ step: TutorialStep) -> some View {
    HStack(spacing: 32) {
        imageContent(step)
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 24) {
                    textContent(step)
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

private func imageContent(_ step: TutorialStep) -> some View {
    Group {
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
    }
}

private func textContent(_ step: TutorialStep) -> some View {
    Group {
        AppText(step.title, style: .header2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .multilineTextAlignment(.leading)

        AppText(step.description, style: .body)
            .frame(maxWidth: .infinity, alignment: .leading)
            .multilineTextAlignment(.leading)
        
        if let tsTitle = step.tsTitle, let tsText = step.tsText {
            TroubleshootingPopup(
                title: tsTitle,
                text: tsText
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .multilineTextAlignment(.leading)
        }
    }
}

#Preview {
    let tutorialStep = TutorialStep(
        media: MediaItem(name: "Placeholder", type: .image),
        title: "Test Step",
        description: "Test Description",
        controls: .standard,
        tsTitle: "Test tsTitle",
        tsText: "Test tsText"
    )
    stepContent(tutorialStep, isLandscape: false)
}
