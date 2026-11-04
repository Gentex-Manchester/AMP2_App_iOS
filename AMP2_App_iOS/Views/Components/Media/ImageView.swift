//
//  ImageView.swift
//  AMP2_App_iOS
//
//  Created by Peter Sargent on 11/4/26.
//

import SwiftUI
import UIKit

struct ImageView: View {

    let media: MediaItem

    var configuration: MediaConfiguration = .init()

    private var placeholder: some View {
        Rectangle()
            .fill(configuration.backgroundColor)
            .overlay {
                if configuration.showsPlaceholder {
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                }
            }
    }

    var body: some View {
        Group {
            if let image = UIImage(named: media.name) {
                rendered(Image(uiImage: image))
            } else {
                placeholder
            }
        }
        .frame(
            width: configuration.width,
            height: configuration.height
        )
        .background(configuration.backgroundColor)
        .clipShape(
            RoundedRectangle(
                cornerRadius: configuration.cornerRadius
            )
        )
    }

    @ViewBuilder
    private func rendered(_ image: Image) -> some View {
        switch configuration.contentMode {
        case .fill:
            image
                .resizable()
                .scaledToFill()

        case .fit:
            image
                .resizable()
                .scaledToFit()

        @unknown default:
            image
                .resizable()
                .scaledToFit()
        }
    }
}
