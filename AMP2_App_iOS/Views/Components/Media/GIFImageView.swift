//
//  GIFImageView.swift
//  AMP2_App_iOS
//
//  Created by Peter Sargent on 11/4/26.
//

import SwiftUI
import UIKit
import ImageIO

struct GIFImageView: View {

    let media: MediaItem

    var configuration: MediaConfiguration = .init()

    @Environment(\.colorScheme) private var colorScheme

    private var gifName: String {
        let suffix = colorScheme == .dark ? "_dark" : "_light"
        return media.name + suffix
    }

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
            if Bundle.main.url(
                forResource: gifName,
                withExtension: "gif"
            ) != nil {
                GIFRepresentable(
                    name: gifName,
                    contentMode: configuration.contentMode == .fill
                        ? .scaleAspectFill
                        : .scaleAspectFit
                )
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
}

// MARK: - UIKit GIF Renderer

private final class GIFUIImageView: UIImageView {
    override var intrinsicContentSize: CGSize {
        CGSize(
            width: UIView.noIntrinsicMetric,
            height: UIView.noIntrinsicMetric
        )
    }
}

private struct GIFRepresentable: UIViewRepresentable {

    let name: String
    let contentMode: UIView.ContentMode

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> GIFUIImageView {
        let imageView = GIFUIImageView()

        imageView.clipsToBounds = true
        imageView.contentMode = contentMode
        imageView.image = loadGIF(named: name)
        imageView.startAnimating()

        context.coordinator.currentName = name

        return imageView
    }

    func updateUIView(
        _ imageView: GIFUIImageView,
        context: Context
    ) {
        imageView.contentMode = contentMode

        guard context.coordinator.currentName != name else {
            return
        }

        imageView.stopAnimating()
        imageView.image = loadGIF(named: name)
        imageView.startAnimating()

        context.coordinator.currentName = name
    }
    
    private func loadGIF(named name: String) -> UIImage? {
        guard
            let url = Bundle.main.url(
                forResource: name,
                withExtension: "gif"
            ),
            let source = CGImageSourceCreateWithURL(
                url as CFURL,
                nil
            )
        else {
            return nil
        }

        let frameCount = CGImageSourceGetCount(source)

        guard frameCount > 0 else {
            return nil
        }

        var frames: [UIImage] = []
        var duration: TimeInterval = 0

        for index in 0..<frameCount {
            guard let cgImage = CGImageSourceCreateImageAtIndex(
                source,
                index,
                nil
            ) else {
                continue
            }

            let properties = CGImageSourceCopyPropertiesAtIndex(
                source,
                index,
                nil
            ) as? [CFString: Any]

            let gifProperties = properties?[kCGImagePropertyGIFDictionary]
                as? [CFString: Any]

            let unclampedDelay = gifProperties?[
                kCGImagePropertyGIFUnclampedDelayTime
            ] as? TimeInterval

            let clampedDelay = gifProperties?[
                kCGImagePropertyGIFDelayTime
            ] as? TimeInterval

            let frameDelay = unclampedDelay ?? clampedDelay ?? 0.1
            let safeDelay = max(frameDelay, 0.02)

            frames.append(UIImage(cgImage: cgImage))
            duration += safeDelay
        }

        guard !frames.isEmpty else {
            return nil
        }

        return UIImage.animatedImage(
            with: frames,
            duration: duration
        )
    }

    final class Coordinator {
        var currentName: String?
    }
}

