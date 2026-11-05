//
//  MediaView.swift
//  AMP2_App_iOS
//
//  Created by Peter Sargent on 11/4/26.
//


import SwiftUI

struct MediaView: View {

    let media: MediaItem

    var configuration: MediaConfiguration = .init()

    var body: some View {
        Group {
            switch media.type {
            case .image:
                ImageView(media: media)
            case .gif:
                GIFImageView(media: media)
            }
        }
    }
}
