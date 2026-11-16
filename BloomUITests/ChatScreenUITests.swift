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
        let app = XCUIApplication()
        app.launchArguments = ["-AppMode=mock", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        XCTAssertTrue(app.buttons["continueButton"].waitForExistence(timeout: 15))
        app.buttons["continueButton"].tap()
        XCTAssertTrue(element("chatRow_1", in: app).waitForExistence(timeout: 15))
        element("chatRow_1", in: app).tap()

        let field = element("chatMessageField", in: app)
        XCTAssertTrue(field.waitForExistence(timeout: 15))
        // The text field has 16 pt leading and 11 pt bottom inset inside the glass.
        XCTAssertEqual(field.frame.minX, app.frame.minX + 44, accuracy: 1)
        XCTAssertEqual(app.frame.maxY - field.frame.maxY, 39, accuracy: 1)
        field.tap()
        let keyboard = app.keyboards.firstMatch
        XCTAssertTrue(keyboard.waitForExistence(timeout: 10))
        XCTAssertEqual(field.frame.minX, app.frame.minX + 32, accuracy: 1)
        XCTAssertLessThanOrEqual(field.frame.maxY, keyboard.frame.minY + 1)
        field.typeText("Smooth message")
        let send = element("chatSendButton", in: app)
        XCTAssertTrue(send.waitForExistence(timeout: 10))
        send.tap()
        let sent = element("chatMessageList", in: app).staticTexts
            .matching(NSPredicate(format: "label BEGINSWITH %@", "Smooth message"))
            .firstMatch
        XCTAssertTrue(sent.waitForExistence(timeout: 10))
        XCTAssertEqual(field.value as? String, "")
        XCTAssertTrue(field.isHittable)
        XCTAssertLessThanOrEqual(field.frame.maxY, keyboard.frame.minY + 1)
        element("chatMessageList", in: app).swipeDown()
        let hidden = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: keyboard)
        XCTAssertEqual(XCTWaiter.wait(for: [hidden], timeout: 10), .completed)
        XCTAssertEqual(field.frame.minX, app.frame.minX + 44, accuracy: 1)
    }

    func testOpensProfileAndReturnsToChat() {
        let app = XCUIApplication()
        app.launchArguments = ["-AppMode=mock", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        XCTAssertTrue(app.buttons["continueButton"].waitForExistence(timeout: 15))
        app.buttons["continueButton"].tap()
        let chat = element("chatRow_1", in: app)
        XCTAssertTrue(chat.waitForExistence(timeout: 15))
        chat.tap()

        let profile = element("chatProfileButton", in: app)
        XCTAssertTrue(profile.waitForExistence(timeout: 15))
        profile.tap()
        XCTAssertTrue(element("profileAvatar", in: app).waitForExistence(timeout: 15))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(element("chatMessageField", in: app).waitForExistence(timeout: 15))
    }

    private func element(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }
}
