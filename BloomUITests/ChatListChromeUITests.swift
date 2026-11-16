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
        let search = app.navigationBars.buttons["Search"]
        let compose = app.buttons["newMessageButton"]
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        XCTAssertTrue(search.isHittable)
        XCTAssertTrue(compose.isHittable)
        XCTAssertGreaterThan(search.frame.width, 0)
        XCTAssertGreaterThan(search.frame.height, 0)
        XCTAssertGreaterThan(compose.frame.width, 0)
        XCTAssertGreaterThan(compose.frame.height, 0)
        XCTAssertTrue(element("chatListTitle", in: app).exists)
        // Icons only, but every tab stays reachable and named for VoiceOver.
        XCTAssertEqual(app.tabBars.firstMatch.buttons.count, 3)
        attachScreenshot(of: app, named: "chat-list")
    }

    func testSearchMorphsIntoFieldAndFiltersChats() {
        let app = launchChats()

        app.navigationBars.buttons["Search"].tap()
        let field = element("searchField", in: app)
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        // iOS 26's integrated search bar ships a bare close button instead of "Cancel".
        XCTAssertTrue(app.buttons["close"].exists)
        XCTAssertFalse(app.buttons["newMessageButton"].exists)
        attachScreenshot(of: app, named: "search-open")

        field.tap()
        field.typeText("Nina")
        XCTAssertTrue(element("chatRow_2", in: app).waitForNonExistence(timeout: 5))
        XCTAssertTrue(element("chatRow_1", in: app).exists)
        attachScreenshot(of: app, named: "search-filtered")

        // Regression: the empty-results branch used to tear the search host down mid-typing.
        field.typeText("zzzzzz")
        XCTAssertTrue(element("chatRow_1", in: app).waitForNonExistence(timeout: 5))
        XCTAssertTrue(field.exists)
        XCTAssertEqual(field.value as? String, "Ninazzzzzz")
        for _ in 0..<6 { field.typeText(XCUIKeyboardKey.delete.rawValue) }

        app.buttons["close"].tap()
        XCTAssertTrue(app.buttons["newMessageButton"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["close"].exists)
        XCTAssertTrue(element("chatRow_2", in: app).waitForExistence(timeout: 5))
        attachScreenshot(of: app, named: "search-closed")
    }

    func testSearchRemainsAfterOpeningChatAndReturning() {
        let app = launchChats()
        app.navigationBars.buttons["Search"].tap()
        let field = element("searchField", in: app)
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("Nina")
        element("chatRow_1", in: app).tap()
        XCTAssertTrue(app.textFields["chatMessageField"].waitForExistence(timeout: 10))

        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.5))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.08, dy: 0.5))
        start.press(forDuration: 0.1, thenDragTo: end)
        XCTAssertTrue(app.textFields["chatMessageField"].exists)
        app.navigationBars.buttons.element(boundBy: 0).tap()

        XCTAssertTrue(field.waitForExistence(timeout: 5))
        XCTAssertEqual(field.value as? String, "Nina")
        XCTAssertTrue(element("chatRow_1", in: app).exists)
        XCTAssertFalse(element("chatRow_2", in: app).exists)
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
        app.launchArguments = ["-AppMode=mock", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
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
