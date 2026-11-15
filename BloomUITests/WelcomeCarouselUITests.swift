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

    /// Swiping back from the logo used to pull the pool to its middle run while the
    /// finger was still down, which showed up as a teleport and a jerk. The card before
    /// the logo is the last feature, and reaching it must not move the pool.
    func testSwipingBackFromTheLogoShowsTheLastPage() {
        let app = XCUIApplication()
        app.launchArguments = ["-AppMode=mock"]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        XCTAssertTrue(app.otherElements["welcomePage0"].waitForExistence(timeout: 5))

        app.otherElements["welcomePage0"].swipeRight()

        XCTAssertTrue(app.otherElements["welcomePage3"].waitForExistence(timeout: 5))
        attachScreenshot(of: app, named: "welcome-back-from-logo")
    }

    /// The window is only three cards wide and is reused, so a page that was shown
    /// before has to come back around. Swiping past the end and back must walk the pages
    /// in order, both ways.
    func testSwipingWalksThePagesInBothDirections() {
        let app = XCUIApplication()
        app.launchArguments = ["-AppMode=mock"]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        XCTAssertTrue(app.otherElements["welcomePage0"].waitForExistence(timeout: 5))

        // Each swipe is well under the five-second timer, which restarts on every move.
        var current = 0
        for page in [1, 2, 3] {
            app.otherElements["welcomePage\(current)"].swipeLeft()
            XCTAssertTrue(
                app.otherElements["welcomePage\(page)"].waitForExistence(timeout: 5),
                "swiping forward from page \(current) should land on \(page)"
            )
            current = page
        }
        attachScreenshot(of: app, named: "welcome-wrapped-to-last")

        for page in [2, 1] {
            app.otherElements["welcomePage\(current)"].swipeRight()
            XCTAssertTrue(
                app.otherElements["welcomePage\(page)"].waitForExistence(timeout: 5),
                "swiping back from page \(current) should land on \(page)"
            )
            current = page
        }
        attachScreenshot(of: app, named: "welcome-back-to-second")
    }

    private func attachScreenshot(of app: XCUIApplication, named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
