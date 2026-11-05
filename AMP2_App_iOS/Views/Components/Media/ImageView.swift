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

    var body: some View {
        Group {
            if let image = UIImage(named: media.name) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
        }
    }

}
