//
//  MediaItem.swift
//  AMP2_App_iOS
//
//  Created by Peter Sargent on 11/4/26.
//

import SwiftUI

struct MediaItem: Identifiable {
    let id: UUID
    let name: String
    let type: MediaType

    init(
        id: UUID = UUID(),
        name: String,
        type: MediaType
    ) {
        self.id = id
        self.name = name
        self.type = type
    }
}
