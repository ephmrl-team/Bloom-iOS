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
