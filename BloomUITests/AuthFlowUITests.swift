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

    /// A Debug build reopened without launch arguments still uses the mock backend:
    /// no arguments, and the iCloud button goes straight to the chat list.
    func testDebugBuildDefaultsToMock() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))

        let continueButton = app.buttons["continueButton"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["continueWithoutAccountButton"].exists)
        continueButton.tap()
        XCTAssertTrue(app.buttons["newMessageButton"].waitForExistence(timeout: 10))
        XCTAssertTrue(element("chatRow_1", in: app).waitForExistence(timeout: 10))
    }

    /// Signs in through the mock backend and lands on the chat list.
    private func signIn(_ app: XCUIApplication) {
        app.buttons["mnemonicLoginButton"].tap()

        let firstWord = app.textFields["mnemonicWord1"]
        XCTAssertTrue(firstWord.waitForExistence(timeout: 10))
        firstWord.tap()

        typeMnemonic(Array(repeating: "abandon", count: 11) + ["about"], into: app)

        app.buttons["continueButton"].tap()

        let toChats = app.buttons["continueToChatsButton"]
        XCTAssertTrue(toChats.waitForExistence(timeout: 10))
        toChats.tap()

        XCTAssertTrue(app.buttons["newMessageButton"].waitForExistence(timeout: 10))
    }

    /// Focus moves between fields on every return, so each word needs its own round trip.
    private func typeMnemonic(_ words: [String], into app: XCUIApplication) {
        for word in words {
            app.typeText("\(word)\n")
        }
    }

    /// The mock backend has nothing to authorise: one tap lands on the chat list.
    private func enterChats(_ app: XCUIApplication) {
        XCTAssertTrue(app.buttons["continueButton"].waitForExistence(timeout: 10))
        app.buttons["continueButton"].tap()
        XCTAssertTrue(app.buttons["newMessageButton"].waitForExistence(timeout: 10))
    }
    func testMnemonicLoginShowsChats() {
        let app = launch()

        signIn(app)

        XCTAssertTrue(element("chatRow_1", in: app).waitForExistence(timeout: 10))
    }

    func testSendsMessageInChat() {
        let app = launch()
        enterChats(app)

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
        typeMnemonic(Array(repeating: "abandon", count: 12), into: app)

        XCTAssertFalse(app.buttons["continueButton"].isEnabled)
    }

    func testShowsErrorWhenLoginFails() {
        let app = launch(["-MockScenario=error"])
        app.buttons["mnemonicLoginButton"].tap()

        let firstWord = app.textFields["mnemonicWord1"]
        XCTAssertTrue(firstWord.waitForExistence(timeout: 10))
        firstWord.tap()
        typeMnemonic(Array(repeating: "abandon", count: 11) + ["about"], into: app)

        app.buttons["continueButton"].tap()

        XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 10))
    }

    /// Identifiers land on different element types depending on the SwiftUI container.
    private func element(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }
}
