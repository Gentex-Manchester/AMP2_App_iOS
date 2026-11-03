//
//  AMP2_App_iOSUITestsLaunchTests.swift
//  AMP2_App_iOSUITests
//
//  Created by aaron stockdale on 6/18/26.
//

import XCTest

final class AMP2_App_iOSUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
