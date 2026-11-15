//
//  WelcomeCarouselUITests.swift
//  Bloom
//

import XCTest

final class WelcomeCarouselUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    /// The carousel used to open on the first card of the pool, where there is no
    /// neighbour to the left, and only moved once the five-second timer fired — which
    /// looked like an empty left edge followed by a jump across the whole pool.
    func testOpensOnTheFirstPageAndAdvancesOnePage() {
        let app = XCUIApplication()
        app.launchArguments = ["-AppMode=mock"]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        XCTAssertTrue(app.buttons["continueButton"].waitForExistence(timeout: 10))

        // Only the centred page is exposed, so finding it proves where the carousel sits.
        XCTAssertTrue(app.otherElements["welcomePage0"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.otherElements["welcomePage1"].exists)
        attachScreenshot(of: app, named: "welcome-start")

        // The timer advances by a single page; a jump across the pool would land on
        // page 1 anyway, so the screenshot is what shows the difference.
        XCTAssertTrue(app.otherElements["welcomePage1"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.otherElements["welcomePage0"].exists)
        attachScreenshot(of: app, named: "welcome-after-one-advance")
    }

    private func attachScreenshot(of app: XCUIApplication, named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
