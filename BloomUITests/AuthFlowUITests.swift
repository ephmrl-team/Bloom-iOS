//
//  AuthFlowUITests.swift
//  Bloom
//

import XCTest

final class AuthFlowUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func launch(_ extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-AppMode=mock"] + extraArguments
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        return app
    }

    /// The mock backend has nothing to authorise, so the iCloud button goes straight in.
    func testMockContinueSkipsSignIn() {
        let app = launch()

        XCTAssertTrue(app.buttons["continueButton"].waitForExistence(timeout: 10))
        app.buttons["continueButton"].tap()

        XCTAssertTrue(app.buttons["newMessageButton"].waitForExistence(timeout: 10))
    }

    /// MOCK also offers the guest entry, which opens the chat list without a session.
    func testMockContinueWithoutAccountShowsChats() {
        let app = launch()

        let guest = app.buttons["continueWithoutAccountButton"]
        XCTAssertTrue(guest.waitForExistence(timeout: 10))
        guest.tap()

        XCTAssertTrue(app.buttons["newMessageButton"].waitForExistence(timeout: 10))
        XCTAssertTrue(element("chatRow_1", in: app).waitForExistence(timeout: 10))
    }

    /// Signs in through the mock backend and lands on the chat list.
    private func signIn(_ app: XCUIApplication) {
        app.buttons["mnemonicLoginButton"].tap()

        let firstWord = app.textFields["mnemonicWord1"]
        XCTAssertTrue(firstWord.waitForExistence(timeout: 10))
        firstWord.tap()

        let words = Array(repeating: "abandon", count: 11) + ["about"]
        for word in words {
            app.typeText("\(word)\n")
        }

        app.buttons["continueButton"].tap()

        let toChats = app.buttons["continueToChatsButton"]
        XCTAssertTrue(toChats.waitForExistence(timeout: 10))
        toChats.tap()

        XCTAssertTrue(app.buttons["newMessageButton"].waitForExistence(timeout: 10))
    }

    func testMnemonicLoginShowsChats() {
        let app = launch()

        signIn(app)

        XCTAssertTrue(element("chatRow_1", in: app).waitForExistence(timeout: 10))
    }

    func testSendsMessageInChat() {
        let app = launch()
        signIn(app)

        element("chatRow_1", in: app).tap()

        let field = app.textFields["chatMessageField"]
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        app.typeText("Hello from the UI test")

        app.buttons["chatSendButton"].tap()

        // The bubble label carries the timestamp after the text, so match on a substring.
        let sent = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", "Hello from the UI test"))
            .firstMatch
        XCTAssertTrue(sent.waitForExistence(timeout: 10))
    }

    func testRejectsMnemonicWithBrokenChecksum() {
        let app = launch()
        app.buttons["mnemonicLoginButton"].tap()

        let firstWord = app.textFields["mnemonicWord1"]
        XCTAssertTrue(firstWord.waitForExistence(timeout: 10))
        firstWord.tap()
        for _ in 0..<12 {
            app.typeText("abandon\n")
        }

        XCTAssertFalse(app.buttons["continueButton"].isEnabled)
    }

    func testShowsErrorWhenLoginFails() {
        let app = launch(["-MockScenario=error"])
        app.buttons["mnemonicLoginButton"].tap()

        let firstWord = app.textFields["mnemonicWord1"]
        XCTAssertTrue(firstWord.waitForExistence(timeout: 10))
        firstWord.tap()
        for word in Array(repeating: "abandon", count: 11) + ["about"] {
            app.typeText("\(word)\n")
        }

        app.buttons["continueButton"].tap()

        XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 10))
    }

    /// Identifiers land on different element types depending on the SwiftUI container.
    private func element(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }
}
