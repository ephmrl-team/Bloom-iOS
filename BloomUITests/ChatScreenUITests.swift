//
//  ChatScreenUITests.swift
//  Bloom
//

import XCTest

final class ChatScreenUITests: XCTestCase {
    func testShowsChatChrome() {
        let app = XCUIApplication()
        app.launchArguments = ["-AppMode=mock", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        XCTAssertTrue(app.buttons["continueButton"].waitForExistence(timeout: 15))
        app.buttons["continueButton"].tap()
        XCTAssertTrue(element("chatRow_1", in: app).waitForExistence(timeout: 15))
        element("chatRow_1", in: app).tap()

        XCTAssertTrue(element("chatMessageField", in: app).waitForExistence(timeout: 15))
        XCTAssertTrue(element("chatProfileButton", in: app).isHittable)
        XCTAssertTrue(element("chatOptionsButton", in: app).isHittable)
        XCTAssertTrue(app.navigationBars.buttons.element(boundBy: 0).isHittable)

        let profile = element("chatProfileButton", in: app).frame
        let back = app.navigationBars.buttons.element(boundBy: 0).frame
        let options = element("chatOptionsButton", in: app).frame
        let availableWidth = options.minX - back.maxX
        XCTAssertGreaterThan(availableWidth, 0)
        XCTAssertGreaterThan(profile.width, availableWidth * 0.75)
        XCTAssertGreaterThanOrEqual(profile.minX, back.maxX - 1)
        XCTAssertLessThanOrEqual(profile.maxX, options.minX + 1)

        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "chat-resting"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testKeyboardAndSendMessage() {
        let app = launchChat()

        let field = element("chatMessageField", in: app)
        XCTAssertTrue(field.waitForExistence(timeout: 15))
        // The text field has 16 pt leading and 11 pt bottom inset inside the glass.
        XCTAssertEqual(field.frame.minX, app.frame.minX + 44, accuracy: 1)
        XCTAssertEqual(app.frame.maxY - field.frame.maxY, 39, accuracy: 1)

        let keyboard = focusComposer(field, in: app)
        send("Smooth message", in: app)

        XCTAssertEqual(field.value as? String, "")
        XCTAssertTrue(field.isHittable)
        XCTAssertLessThanOrEqual(field.frame.maxY, keyboard.frame.minY + 1)
        element("chatMessageList", in: app).swipeDown()
        XCTAssertTrue(keyboard.waitForNonExistence(timeout: 10))
        XCTAssertEqual(field.frame.minX, app.frame.minX + 44, accuracy: 1)
    }

    func testOpensProfileAndReturnsToChat() {
        let app = launchChat()

        let profile = element("chatProfileButton", in: app)
        XCTAssertTrue(profile.waitForExistence(timeout: 15))
        profile.tap()
        XCTAssertTrue(element("profileAvatar", in: app).waitForExistence(timeout: 15))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(element("chatMessageField", in: app).waitForExistence(timeout: 15))
    }

    /// Long-pressing a bubble must keep its 22 pt shape and put it back exactly where it was; an
    /// emoji-only bubble has no background, so it must lift without a plate or a corner clip.
    func testMessageContextMenuKeepsBubbleShape() {
        let app = launchChat()

        let bubble = element("chatMessageList", in: app).staticTexts
            .matching(NSPredicate(format: "label BEGINSWITH %@", "Message #36 from Nina"))
            .firstMatch
        XCTAssertTrue(bubble.waitForExistence(timeout: 15))
        let restingFrame = bubble.frame
        capture("menu-baseline")

        bubble.press(forDuration: 1.2)
        XCTAssertTrue(app.buttons["Copy"].waitForExistence(timeout: 10))
        capture("menu-open-text")
        dismissMenu(in: app)
        XCTAssertEqual(bubble.frame.minY, restingFrame.minY, accuracy: 1)
        XCTAssertEqual(bubble.frame.minX, restingFrame.minX, accuracy: 1)

        element("chatMessageField", in: app).tap()
        send("😀", in: app)
        let emoji = element("chatMessageList", in: app).staticTexts
            .matching(NSPredicate(format: "label BEGINSWITH %@", "😀"))
            .firstMatch
        XCTAssertTrue(emoji.waitForExistence(timeout: 10))

        emoji.press(forDuration: 1.2)
        XCTAssertTrue(app.buttons["Copy"].waitForExistence(timeout: 10))
        capture("menu-open-emoji")
        dismissMenu(in: app)
        XCTAssertTrue(app.buttons["Copy"].waitForNonExistence(timeout: 10))
    }

    private func dismissMenu(in app: XCUIApplication) {
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.03, dy: 0.3)).tap()
        XCTAssertTrue(app.buttons["Copy"].waitForNonExistence(timeout: 10))
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func launchChat() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-AppMode=mock", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        XCTAssertTrue(app.buttons["continueButton"].waitForExistence(timeout: 15))
        app.buttons["continueButton"].tap()
        XCTAssertTrue(element("chatRow_1", in: app).waitForExistence(timeout: 15))
        element("chatRow_1", in: app).tap()
        return app
    }

    private func focusComposer(_ field: XCUIElement, in app: XCUIApplication) -> XCUIElement {
        field.tap()
        let keyboard = app.keyboards.firstMatch
        XCTAssertTrue(keyboard.waitForExistence(timeout: 10))
        XCTAssertEqual(field.frame.minX, app.frame.minX + 32, accuracy: 1)
        XCTAssertLessThanOrEqual(field.frame.maxY, keyboard.frame.minY + 1)
        return keyboard
    }

    private func send(_ text: String, in app: XCUIApplication) {
        element("chatMessageField", in: app).typeText(text)
        let button = element("chatSendButton", in: app)
        XCTAssertTrue(button.waitForExistence(timeout: 10))
        button.tap()
        let sent = element("chatMessageList", in: app).staticTexts
            .matching(NSPredicate(format: "label BEGINSWITH %@", text))
            .firstMatch
        XCTAssertTrue(sent.waitForExistence(timeout: 10))
    }

    private func element(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }
}
