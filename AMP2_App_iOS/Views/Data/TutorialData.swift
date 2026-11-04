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
        controls: .standard
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
        controls: .standard
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
        controls: .standard
    ),
    TutorialStep(
        media: MediaItem(name: "bt_reconnection", type: .gif),
        title: "Enable Bluetooth",
        description: "Press and hold the - and ● buttons to enable Bluetooth.",
        controls: .last
    ),
]
