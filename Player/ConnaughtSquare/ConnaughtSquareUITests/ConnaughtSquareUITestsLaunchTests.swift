//
//  ConnaughtSquareUITestsLaunchTests.swift
//  ConnaughtSquareUITests
//
//  Created by Michael Scott on 22/07/2026.
//

import XCTest

final class ConnaughtSquareUITestsLaunchTests: XCTestCase {

    // Note: `runsForEachTargetApplicationUIConfiguration` is deliberately not overridden.
    // On the My Mac destination it renders the dark configuration by changing the system
    // appearance, and the run leaves it set to Dark rather than restoring it.

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app
        // XCUIAutomation Documentation
        // https://developer.apple.com/documentation/xcuiautomation

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
