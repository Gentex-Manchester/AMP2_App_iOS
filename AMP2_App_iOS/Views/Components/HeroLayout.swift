//
//  HeroLayout.swift
//  AMP2_App_iOS
//
//  Created by Peter Sargent on 11/5/26.
//

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
                landscapeView()
                    .scrollEdgeEffectHidden()
            } else {
                portraitView()
                    .scrollEdgeEffectHidden()
            }
        } else {
            if (isLandscape) {
                landscapeView()
            } else {
                portraitView()
            }
        }
    }
        
    private func landscapeView() -> some View {
        return GeometryReader { geometry in
            HStack(spacing: 0) {
                
                // Left column
                ZStack {
                    imageContent(primaryContentBg)
                        .stretchy()
                    
                    VStack(spacing: 0) {
                        primaryContent
                            .frame(maxWidth: .infinity, alignment: .center)
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
    }
    
    private func portraitView() -> some View {
        GeometryReader { geometry in
            let isCompact = geometry.size.height < 700

            ScrollView {
                VStack(spacing: 0) {
                    VStack() {
                        Spacer()
                            .frame(height: isCompact ? 16 : 128)

                        primaryContent
                            .frame(maxWidth: .infinity, alignment: .center)

                        Spacer()
                            .frame(height: isCompact ? 16 : 32)
                    }
                    .frame(width: geometry.size.width)
                    .background {
                        GeometryReader { sectionGeometry in
                            imageContent(primaryContentBg)
                                .aspectRatio(contentMode: .fill)
                                .frame(
                                    width: sectionGeometry.size.width
                                        + sectionGeometry.safeAreaInsets.leading
                                        + sectionGeometry.safeAreaInsets.trailing,
                                    height: sectionGeometry.size.height
                                )
                                .clipped()
                                .stretchy()
                                .ignoresSafeArea(edges: .horizontal)
                        }
                    }

                    Spacer()
                        .frame(height: isCompact ? 16 : 32)

                    secondaryContent
                }
            }
            .ignoresSafeArea(edges: .top)
        }
    }
}

private func imageContent(
    _ media: MediaItem
) -> some View {
    MediaView(
        media: media
    )
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
