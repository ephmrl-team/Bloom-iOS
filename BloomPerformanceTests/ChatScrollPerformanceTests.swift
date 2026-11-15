//
//  ChatScrollPerformanceTests.swift
//  Bloom
//

import XCTest

final class ChatScrollPerformanceTests: XCTestCase {
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
