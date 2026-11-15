//
//  ChatListChromeUITests.swift
//  Bloom
//

import XCTest

final class ChatListChromeUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testShowsChatListChrome() {
        let app = launchChats()

        XCTAssertTrue(element("chatRow_1", in: app).waitForExistence(timeout: 10))
        // Icons only, but every tab stays reachable and named for VoiceOver.
        XCTAssertEqual(app.tabBars.firstMatch.buttons.count, 3)
        attachScreenshot(of: app, named: "chat-list")
    }

    func testSearchReplacesTheTitleAndTheComposer() {
        let app = launchChats()

        app.buttons["searchButton"].tap()
        let field = app.textFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["newMessageButton"].exists)
        attachScreenshot(of: app, named: "search-open")

        field.typeText("Nina")
        XCTAssertTrue(element("chatRow_2", in: app).waitForNonExistence(timeout: 5))
        XCTAssertTrue(element("chatRow_1", in: app).exists)
        attachScreenshot(of: app, named: "search-filtered")

        app.buttons["searchCloseButton"].tap()
        XCTAssertTrue(app.buttons["newMessageButton"].waitForExistence(timeout: 5))
        XCTAssertTrue(element("chatRow_2", in: app).waitForExistence(timeout: 5))
        attachScreenshot(of: app, named: "search-closed")
    }

    func testComposerOpensAFullHeightSheet() {
        let app = launchChats()

        app.buttons["newMessageButton"].tap()
        let close = element("newMessageCloseButton", in: app)
        XCTAssertTrue(close.waitForExistence(timeout: 5))
        // A large sheet puts its toolbar under the status bar; a medium one starts near mid-screen.
        XCTAssertLessThan(close.frame.minY, 120)
        attachScreenshot(of: app, named: "new-message-sheet")

        close.tap()
        XCTAssertTrue(app.buttons["newMessageButton"].waitForExistence(timeout: 5))
        XCTAssertFalse(close.exists)
    }

    private func launchChats() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-AppMode=mock"]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))

        XCTAssertTrue(app.buttons["continueButton"].waitForExistence(timeout: 10))
        app.buttons["continueButton"].tap()

        XCTAssertTrue(app.buttons["newMessageButton"].waitForExistence(timeout: 10))
        return app
    }

    /// Identifiers land on different element types depending on the SwiftUI container.
    private func element(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    private func attachScreenshot(of app: XCUIApplication, named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
