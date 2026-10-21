//
//  Gentex_iOSUITests.swift
//  Gentex_iOSUITests
//
//  Rev 3 C3: launch, navigation, and the pairing walkthrough.
//
//  The simulator has no Bluetooth radio, so several tests assert on
//  `.bluetoothUnsupported`, which is what a user sees with Bluetooth off. The
//  pairing walkthrough is opened with the debug launch argument in `UITestFlags`.
//

import XCTest

final class Gentex_iOSUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Helpers

    private func launch(_ arguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += arguments
        app.launch()
        return app
    }

    private func tab(_ name: String, in app: XCUIApplication) -> XCUIElement {
        app.buttons[name]
    }

    // MARK: - Launch

    func testLaunchesToTheHeadsetTab() throws {
        let app = launch()

        XCTAssertTrue(tab("Headset", in: app).waitForExistence(timeout: 10))
        XCTAssertTrue(tab("Teams", in: app).exists)
        XCTAssertTrue(tab("Settings", in: app).exists)

        // With no headset, the landing screen must explain itself.
        XCTAssertTrue(
            app.staticTexts["To use this app, you must connect to an AMP 2.0 headset, like the AMP 2.0 Elite headset."].exists
                || app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Bluetooth'")).count > 0
        )
    }

    // MARK: - Bluetooth unavailable (rev 3 B9)

    /// B9: the radio fault used to be a grey footnote under "No headset connected",
    /// so users went looking for a headset problem.
    func testRadioFaultLeadsTheScreenAndDisablesConnecting() throws {
        let app = launch()

        let headline = app.staticTexts["This device does not support Bluetooth LE."]
        XCTAssertTrue(headline.waitForExistence(timeout: 10), "the radio fault must be the headline")

        let button = app.buttons["Bluetooth unavailable"]
        XCTAssertTrue(button.exists, "the button must name the real blocker")
        XCTAssertFalse(button.isEnabled, "scanning with no radio only fails again")
    }

    // MARK: - Navigation

    func testTabsSwitchContent() throws {
        let app = launch()
        XCTAssertTrue(tab("Settings", in: app).waitForExistence(timeout: 10))

        tab("Settings", in: app).tap()
        XCTAssertTrue(app.staticTexts["Appearance"].waitForExistence(timeout: 5))

        tab("Headset", in: app).tap()
        XCTAssertTrue(app.buttons["Bluetooth unavailable"].waitForExistence(timeout: 5))

        tab("Settings", in: app).tap()
        XCTAssertTrue(app.staticTexts["Appearance"].waitForExistence(timeout: 5))
    }

    func testSettingsPushesAndPopsBack() throws {
        let app = launch()
        tab("Settings", in: app).tap()

        let appearance = app.staticTexts["Appearance"]
        XCTAssertTrue(appearance.waitForExistence(timeout: 10))
        appearance.tap()

        let back = app.navigationBars.buttons.element(boundBy: 0)
        XCTAssertTrue(back.waitForExistence(timeout: 5))
        back.tap()

        XCTAssertTrue(app.staticTexts["Permissions"].waitForExistence(timeout: 5))
    }

    // MARK: - Permissions (rev 3 B10)

    /// The list used to describe permissions without reporting any of them.
    func testPermissionsListReportsEachStatus() throws {
        let app = launch()
        tab("Settings", in: app).tap()

        let permissions = app.staticTexts["Permissions"]
        XCTAssertTrue(permissions.waitForExistence(timeout: 10))
        permissions.tap()

        XCTAssertTrue(app.staticTexts["Bluetooth Permissions"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Camera Permissions"].exists)

        // Any status will do; it varies by machine.
        let statuses = ["Allowed", "Not allowed", "Restricted", "Not requested"]
        let shown = statuses.filter { app.staticTexts[$0].exists }
        XCTAssertFalse(shown.isEmpty, "no permission reported a status")
    }

    // MARK: - Rotation

    /// Gentex: rotating inside a submenu reset to the root. `ContentView` swapped
    /// VStack/HStack on rotation, giving the content a new identity and tearing
    /// down the navigation stack.
    func testRotatingInsideASubmenuKeepsYourPlace() throws {
        let app = launch()
        addTeardownBlock { XCUIDevice.shared.orientation = .portrait }

        tab("Settings", in: app).tap()

        // Must be System, or the app locks to portrait and never rotates.
        let orientationRow = app.staticTexts["Orientation"]
        XCTAssertTrue(orientationRow.waitForExistence(timeout: 10))
        orientationRow.tap()

        // Nav title, not a row label: after rotation a label query can hit another element.
        let title = app.navigationBars.staticTexts["Orientation"]
        XCTAssertTrue(title.waitForExistence(timeout: 5), "did not reach the Orientation screen")

        let system = app.buttons["System"]
        XCTAssertTrue(system.waitForExistence(timeout: 5))
        system.tap()

        XCUIDevice.shared.orientation = .landscapeLeft

        XCTAssertTrue(
            title.waitForExistence(timeout: 8),
            "rotating dropped the user out of the submenu"
        )

        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(title.waitForExistence(timeout: 8), "rotating back lost the screen")
    }

    /// The tab bar becomes a sidebar in landscape; both must work.
    func testTabsSurviveRotation() throws {
        let app = launch()
        addTeardownBlock { XCUIDevice.shared.orientation = .portrait }

        tab("Settings", in: app).tap()
        XCTAssertTrue(app.staticTexts["Appearance"].waitForExistence(timeout: 10))

        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(tab("Headset", in: app).waitForExistence(timeout: 5))
        XCTAssertTrue(tab("Teams", in: app).exists)
        XCTAssertTrue(tab("Settings", in: app).exists)

        tab("Headset", in: app).tap()
        XCTAssertTrue(app.buttons["Bluetooth unavailable"].waitForExistence(timeout: 5))
    }

    // MARK: - Pairing walkthrough

    /// Opened via launch argument; its button is disabled without a radio.
    func testPairingWalkthroughStepsForwardAndBack() throws {
        let app = launch(["-uiTestOpenPairingTutorial"])

        let next = app.buttons["Next"]
        XCTAssertTrue(next.waitForExistence(timeout: 10), "the walkthrough did not open")

        next.tap()
        let back = app.buttons["Back"]
        XCTAssertTrue(back.waitForExistence(timeout: 5), "Back appears once past the first step")

        next.tap()
        XCTAssertTrue(back.exists)

        back.tap()
        XCTAssertTrue(next.waitForExistence(timeout: 5))
    }

    /// The waiting step used to hang with the headset already connected: the scan
    /// started only on a step change, not when opened straight onto it.
    func testWalkthroughReachesTheWaitingStep() throws {
        let app = launch(["-uiTestOpenPairingTutorial"])

        let next = app.buttons["Next"]
        XCTAssertTrue(next.waitForExistence(timeout: 10))

        // Step count isn't hard-coded; it follows the copy.
        var taps = 0
        while next.exists && next.isHittable && taps < 12 {
            next.tap()
            taps += 1
        }

        XCTAssertTrue(
            app.staticTexts["Waiting for your headset…"].waitForExistence(timeout: 5)
                || app.buttons["Check Again"].exists
                || app.buttons["Looking…"].exists,
            "the walkthrough never reached the step that waits for the headset"
        )
    }
}
