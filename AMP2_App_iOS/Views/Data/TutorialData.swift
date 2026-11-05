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
        title: "Put on the headset",
        description: "Listen to audio cues inside of the headset and use the buttons on the left earcup to walk through this tutorial.",
        controls: .first
    ),
    TutorialStep(
        media: MediaItem(name: "bt_pairing_2", type: .gif),
        title: "Turn on the headset",
        description: "Press and hold + to turn on the headset.",
        controls: .standard,
        tsTitle: "My headset isn't turning on.",
        tsText: "Make sure that a lithium or alkaline AA battery has been inserted into the battery cap. If a battery is already inserted, try replacing it."
    ),
    TutorialStep(
        media: MediaItem(name: "bt_pairing_3", type: .gif),
        title: "Enter the menu",
        description: "Press and hold the + and - buttons to enter the menu built into the headset.",
        controls: .standard
    ),
    TutorialStep(
        media: MediaItem(name: "bt_pairing_4", type: .gif),
        title: "Navigate the menu",
        description: "Press the + or - button until the headset reads “Bluetooth Settings.”",
        controls: .standard
    ),
    TutorialStep(
        media: MediaItem(name: "bt_pairing_5", type: .gif),
        title: "Enable pairing",
        description: "Press ● to select Bluetooth, then press ● again to start pairing.",
        controls: .standard,
        tsTitle: "I selected the wrong option.",
        tsText: """
            The +, -, and ● buttons can be used to navigate backwards through the menu. \
            Press + or - to find the \"Back\" option, then press ● to go to the previous menu. Continue \
            to navigate through the menu until you find “Bluetooth Settings”. \
            Check the user manual for a map of all available options.
            """
    ),
    TutorialStep(
        media: MediaItem(name: "headset_silhouette", type: .image),
        title: "Go to Settings",
        description: """
            Leave this app open, then open Settings › Bluetooth on your iPhone and \
            click on the headset with your serial number. Once it has connected, return to this app.
            """,
        controls: .last
    ),
]

let reconnectingSteps: [TutorialStep] = [
    TutorialStep(
        media: MediaItem(name: "bt_pairing_1", type: .gif),
        title: "Put on the headset",
        description: "Listen to audio cues inside of the headset and use the buttons on the left earcup to walk through this tutorial.",
        controls: .first
    ),
    TutorialStep(
        media: MediaItem(name: "bt_pairing_2", type: .gif),
        title: "Turn on the headset",
        description: "Press and hold + to turn on the headset.",
        controls: .standard,
        tsTitle: "My headset isn't turning on.",
        tsText: "Make sure that a lithium or alkaline AA battery has been inserted into the battery cap. If a battery is already inserted, try replacing it."
    ),
    TutorialStep(
        media: MediaItem(name: "bt_reconnection", type: .gif),
        title: "Enable Bluetooth",
        description: "Press and hold the - and ● buttons to enable Bluetooth.",
        controls: .last,
        tsTitle: "My headset isn’t pairing to this system.",
        tsText: """
            Make sure that Bluetooth is enabled on your system. If you’ve paired your headset to \
            a different system or are attempting to use a new headset with this system, please \
            unpair your headset from this system’s Bluetooth Settings and then go through the pairing process again.
            """
    ),
]
