//
//  TutorialData.swift
//  AMP2_App_iOS
//

import Foundation

struct TutorialStep {
    let media: MediaItem
    let title: String
    let description: String
    let controls: BottomControlsType
    let tsTitle: String?
    let tsText: String?

    init(
        media: MediaItem,
        title: String,
        description: String,
        controls: BottomControlsType,
        tsTitle: String? = nil,
        tsText: String? = nil
    ) {
        self.media = media
        self.title = title
        self.description = description
        self.controls = controls
        self.tsTitle = tsTitle
        self.tsText = tsText
    }
}

let pairingSteps: [TutorialStep] = [
    TutorialStep(
        media: MediaItem(name: "bt_pairing_1", type: .gif),
        title: String(localized: "Put on the headset"),
        description: String(localized: "Listen to audio cues inside of the headset and use the buttons on the left earcup to walk through this tutorial."),
        controls: .first
    ),
    TutorialStep(
        media: MediaItem(name: "bt_pairing_2", type: .gif),
        title: String(localized: "Turn on the headset"),
        description: String(localized: "Press and hold + to turn on the headset."),
        controls: .standard,
        tsTitle: String(localized: "My headset isn't turning on."),
        tsText: String(localized: "Make sure that a lithium or alkaline AA battery has been inserted into the battery cap. If a battery is already inserted, try replacing it.")
    ),
    TutorialStep(
        media: MediaItem(name: "bt_pairing_3", type: .gif),
        title: String(localized: "Enter the menu"),
        description: String(localized: "Press and hold the + and - buttons to enter the menu built into the headset."),
        controls: .standard
    ),
    TutorialStep(
        media: MediaItem(name: "bt_pairing_4", type: .gif),
        title: String(localized: "Navigate the menu"),
        description: String(localized: "Press the + or - button until the headset reads “Bluetooth Settings.”"),
        controls: .standard
    ),
    TutorialStep(
        media: MediaItem(name: "bt_pairing_5", type: .gif),
        title: String(localized: "Enable pairing"),
        description: String(localized: "Press ● to select Bluetooth, then press ● again to start pairing."),
        controls: .standard,
        tsTitle: String(localized: "I selected the wrong option."),
        tsText: String(localized: """
            The +, -, and ● buttons can be used to navigate backwards through the menu. \
            Press + or - to find the \"Back\" option, then press ● to go to the previous menu. Continue \
            to navigate through the menu until you find “Bluetooth Settings”. \
            Check the user manual for a map of all available options.
            """)
    ),
    TutorialStep(
        media: MediaItem(name: "headset_silhouette", type: .image),
        title: String(localized: "Go to Settings"),
        description: String(localized: """
            Leave this app open, then open Settings › Bluetooth on your iPhone and \
            click on the headset with your serial number. Once it has connected, return to this app.
            """),
        controls: .last
    ),
]

let reconnectingSteps: [TutorialStep] = [
    TutorialStep(
        media: MediaItem(name: "bt_pairing_1", type: .gif),
        title: String(localized: "Put on the headset"),
        description: String(localized: "Listen to audio cues inside of the headset and use the buttons on the left earcup to walk through this tutorial."),
        controls: .first
    ),
    TutorialStep(
        media: MediaItem(name: "bt_pairing_2", type: .gif),
        title: String(localized: "Turn on the headset"),
        description: String(localized: "Press and hold + to turn on the headset."),
        controls: .standard,
        tsTitle: String(localized: "My headset isn't turning on."),
        tsText: String(localized: "Make sure that a lithium or alkaline AA battery has been inserted into the battery cap. If a battery is already inserted, try replacing it.")
    ),
    TutorialStep(
        media: MediaItem(name: "bt_reconnection", type: .gif),
        title: String(localized: "Enable Bluetooth"),
        description: String(localized: "Press and hold the - and ● buttons to enable Bluetooth."),
        controls: .last,
        tsTitle: String(localized: "My headset isn’t pairing to this system."),
        tsText: String(localized: """
            Make sure that Bluetooth is enabled on your system. If you're attempting to use \
            the app with a new headset, please give the app some extra time to register the headset.
            """)
    ),
]
