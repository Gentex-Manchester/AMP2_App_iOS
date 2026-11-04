//
//  MediaConfiguration.swift
//  AMP2_App_iOS
//
//  Created by Peter Sargent on 11/4/26.
//


import SwiftUI

struct MediaConfiguration {

    var contentMode: ContentMode = .fill

    var cornerRadius: CGFloat = 0

    var width: CGFloat? = nil

    var height: CGFloat? = nil

    var isAnimated: Bool = true

    var showsPlaceholder: Bool = true

    var loops: Bool = true

    var backgroundColor: Color = .clear
}
