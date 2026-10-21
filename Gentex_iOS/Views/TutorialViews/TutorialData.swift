//
//  TutorialData.swift
//  Gentex_iOS
//

import Foundation

struct TutorialStep {
    let imageName: String
    let title: String
    let description: String
}

let tutorialSteps: [TutorialStep] = [
    TutorialStep(
        imageName: "Button Placement (Dark)",
        title: "Put on the headset.",
        description: "You will need to use the buttons on the right-hand side and listen to audio prompts to walk through this tutorial."
    ),
    TutorialStep(
        imageName: "BT Step 2 (Dark)",
        title: "Hold the plus (+) button to power on the headset.",
        description: "If the headset isn't powering on, make sure to check on your headset battery."
    ),
    TutorialStep(
        imageName: "BT Step 3 (Dark)",
        title: "Hold the plus (+) and minus (-) buttons to enter the menu.",
        description: "You should hear \"Menu,\" then one of the menu options, like \"Configure LTC.\""
    ),
    TutorialStep(
        imageName: "BT Step 2 (Dark)",
        title: "Press the plus (+) button until you get to the \"Configure Bluetooth\" option.",
        description: "Don't press the button too quickly, this may lead to selecting the wrong option."
    ),
    TutorialStep(
        imageName: "BT Step 4 (Dark)",
        title: "Press the center button to enter the Bluetooth menu, then press it again to activate Bluetooth pairing.",
        description: "You should hear \"Bluetooth Pairing\" after the first press, then \"Selection Confirmed.\" after the second press."
    ),
    // Pairing step. No "Bluetooth Settings" button: `openSettingsURLString`
    // opens the app's own permission page, and AccessorySetupKit can't see this
    // headset. See docs/ble-protocol.md §10.
    // "Connected" (not just paired) is required (ble-parity-plan.md §0.1), but
    // it's a hint, not its own step; tapping the headset usually connects it.
    TutorialStep(
        imageName: "Connect Device",
        title: "The headset is now in Bluetooth pairing mode.",
        description: """
            Leave this app open, then open Settings › Bluetooth on your iPhone \
            and tap your headset under Other Devices.

            It should move to My Devices and read "Connected." If it says "Not \
            Connected," tap it once more.
            """
    ),
]

// No "Headset connected!" step: connecting dismisses the tutorial, as on
// Android (`navigation/HeadsetNav.kt`).
