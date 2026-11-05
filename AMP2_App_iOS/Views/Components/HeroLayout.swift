//
//  HeroLayout.swift
//  AMP2_App_iOS
//
//  Created by Peter Sargent on 11/5/26.
//

// TODO: Need to optimize heavily

import SwiftUI

struct HeroLayout<Primary: View, Secondary: View>: View {

    let primaryContent: Primary
    let secondaryContent: Secondary
    let primaryContentBg: MediaItem
    let isLandscape: Bool

    init(
        @ViewBuilder primaryContent: () -> Primary,
        @ViewBuilder secondaryContent: () -> Secondary,
        primaryContentBg: MediaItem,
        isLandscape: Bool
    ) {
        self.primaryContentBg = primaryContentBg
        self.isLandscape = isLandscape
        self.primaryContent = primaryContent()
        self.secondaryContent = secondaryContent()
    }

    var body: some View {
        if #available(iOS 26.0, *) {
            if (isLandscape) {
                GeometryReader { geometry in
                    HStack(spacing: 0) {

                        // Left column
                        ZStack {
                            imageContent(primaryContentBg)
                                .stretchy()

                            VStack(spacing: 0) {
                                primaryContent
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                        }
                        .frame(width: geometry.size.width * 0.5)
                        .clipped()

                        // Right column
                        ScrollView {
                            VStack(spacing: 0) {
                                Spacer()
                                    .frame(height: 64)

                                secondaryContent
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .frame(width: geometry.size.width * 0.5)
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                }
                .ignoresSafeArea(edges: .vertical)
                .ignoresSafeArea(edges: .leading)
                .scrollEdgeEffectHidden()
            } else {
                ScrollView {
                    VStack {
                        ZStack {
                            imageContent(primaryContentBg)
                                .stretchy()
                            
                            VStack(spacing: 0) {
                                Spacer()
                                    .frame(height: 128)

                                primaryContent
                                    .frame(maxWidth: .infinity, alignment: .center)

                                Spacer()
                                    .frame(height: 64)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        
                        secondaryContent
                    }
                }
                .ignoresSafeArea(edges: .top)
                .scrollEdgeEffectHidden()
            }
        } else {
            if (isLandscape) {
                GeometryReader { geometry in
                    HStack(spacing: 0) {

                        // Left column
                        ZStack {
                            imageContent(primaryContentBg)
                                .stretchy()

                            VStack(spacing: 0) {
                                Spacer(minLength: 0)

                                primaryContent
                                    .frame(maxWidth: .infinity, alignment: .center)

                                Spacer(minLength: 0)
                            }
                        }
                        .frame(width: geometry.size.width * 0.5)
                        .clipped()

                        // Right column
                        ScrollView {
                            VStack(spacing: 0) {
                                Spacer()
                                    .frame(height: 64)

                                secondaryContent
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .frame(width: geometry.size.width * 0.5)
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                }
                .ignoresSafeArea(edges: .vertical)
                .ignoresSafeArea(edges: .leading)
            } else {
                ScrollView {
                    VStack {
                        ZStack {
                            imageContent(primaryContentBg)
                                .stretchy()
                            
                            VStack(spacing: 0) {
                                Spacer()
                                    .frame(height: 128)

                                primaryContent
                                    .frame(maxWidth: .infinity, alignment: .center)

                                Spacer()
                                    .frame(height: 64)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        
                        secondaryContent
                    }
                }
                .ignoresSafeArea(edges: .top)
            }
        }
    }
}

private func imageContent(_ media: MediaItem) -> some View {
    Group {
        if media.type == .image {
            ImageView(
                media: media,
                configuration: MediaConfiguration(
                    contentMode: .fit
                )
            )
        } else if media.type == .gif {
            GIFImageView(
                media: media,
                configuration: MediaConfiguration(
                    contentMode: .fit
                )
            )
        }
    }
}

#Preview {
    let mediaItem = MediaItem(
        name: "disabled_bg_texture",
        type: .image,
    )
    
    HeroLayout(
        primaryContent: {
            Image("headset_silhouette")
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 300)
                .border(.red)
        },
        secondaryContent: {
            Text("Secondary Content")
        },
        primaryContentBg: mediaItem,
        isLandscape: true
    )
}
