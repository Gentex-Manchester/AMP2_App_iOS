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
        media: MediaItem(name: "Button Placement (Dark)", type: .image),
        title: "Put on the headset.",
        description: "You will need to use the buttons on the right-hand side and listen to audio prompts to walk through this tutorial.",
        controls: .first
    ),
    TutorialStep(
        media: MediaItem(name: "BT Step 2 (Dark)", type: .image),
        title: "Hold the plus (+) button to power on the headset.",
        description: "If the headset isn't powering on, make sure to check on your headset battery.",
        controls: .standard
    ),
    TutorialStep(
        media: MediaItem(name: "BT Step 3 (Dark)", type: .image),
        title: "Hold the plus (+) and minus (-) buttons to enter the menu.",
        description: "You should hear \"Menu,\" then one of the menu options, like \"Configure LTC.\"",
        controls: .standard
    ),
    TutorialStep(
        media: MediaItem(name: "BT Step 2 (Dark)", type: .image),
        title: "Press the plus (+) button until you get to the \"Configure Bluetooth\" option.",
        description: "Don't press the button too quickly, this may lead to selecting the wrong option.",
        controls: .standard
    ),
    TutorialStep(
        media: MediaItem(name: "BT Step 4 (Dark)", type: .image),
        title: "Press the center button to enter the Bluetooth menu, then press it again to activate Bluetooth pairing.",
        description: "You should hear \"Bluetooth Pairing\" after the first press, then \"Selection Confirmed.\" after the second press.",
        controls: .standard
    ),
    TutorialStep(
        media: MediaItem(name: "Connect Device", type: .image),
        title: "The headset is now in Bluetooth pairing mode.",
        description: """
            Leave this app open, then open Settings › Bluetooth on your iPhone \
            and tap your headset under Other Devices.

            It should move to My Devices and read "Connected." If it says "Not \
            Connected," tap it once more.
            """,
        controls: .last
    ),
]

let reconnectingSteps: [TutorialStep] = [
    TutorialStep(
        media: MediaItem(name: "Connect Device", type: .image),
        title: "Put on the headset.",
        description: """
            Listen to audio cues inside of the headset and use the buttons on the left
            earcup to walk through this tutorial.
            """,
        controls: .first
    ),
    TutorialStep(
        media: MediaItem(name: "BT Step 2 (Dark)", type: .image),
        title: "Hold the plus (+) button to power on the headset.",
        description: "If the headset isn't powering on, make sure to check on your headset battery.",
        controls: .standard
    ),
    TutorialStep(
        media: MediaItem(name: "Connect Device", type: .image),
        title: "Enable Bluetooth.",
        description: "Press and hold the - and SELECT buttons to continue.",
        controls: .last
    ),
]

// No "Headset connected!" step: connecting dismisses the tutorial, as on
// Android (`navigation/HeadsetNav.kt`).
