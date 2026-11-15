//
//  LaunchPerformanceTests.swift
//  Bloom
//

import XCTest

final class LaunchPerformanceTests: XCTestCase {
    func testLaunchPerformance() {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
