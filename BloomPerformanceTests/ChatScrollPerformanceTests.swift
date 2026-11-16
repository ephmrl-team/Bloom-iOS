//
//  ChatScrollPerformanceTests.swift
//  Bloom
//

import XCTest

final class ChatScrollPerformanceTests: XCTestCase {
    func testMessageScrollHitches() {
        let app = XCUIApplication()
        app.launchArguments = ["-AppMode=mock", "-MockScenario=large"]
        app.launch()
        let continueButton = app.buttons["continueButton"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 20))
        continueButton.tap()
        let chat = app.descendants(matching: .any).matching(identifier: "chatRow_1").firstMatch
        XCTAssertTrue(chat.waitForExistence(timeout: 20))
        chat.tap()
        let messages = app.scrollViews["chatMessageList"]
        XCTAssertTrue(messages.waitForExistence(timeout: 20))

        let options = XCTMeasureOptions()
        options.iterationCount = 3
        measure(metrics: [XCTHitchMetric(application: app), XCTCPUMetric(application: app), XCTMemoryMetric(application: app)],
                options: options) {
            messages.swipeDown(velocity: .fast)
            messages.swipeUp(velocity: .fast)
        }
    }

    func testChatListScrollHitches() {
        let app = XCUIApplication()
        app.launchArguments = ["-AppMode=mock", "-MockScenario=large"]
        let options = XCTMeasureOptions()
        options.iterationCount = 3

        measure(
            metrics: [
                XCTHitchMetric(application: app),
                XCTCPUMetric(application: app),
                XCTMemoryMetric(application: app)
            ],
            options: options
        ) {
            app.launch()
            let list = app.collectionViews.firstMatch
            if list.waitForExistence(timeout: 10) {
                list.swipeUp(velocity: .fast)
                list.swipeDown(velocity: .fast)
            }
            app.terminate()
        }
    }
}
