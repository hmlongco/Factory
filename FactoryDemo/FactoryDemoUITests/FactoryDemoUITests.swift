//
//  FactoryDemoUITests.swift
//  FactoryDemoUITests
//
//  Created by Michael Long on 1/4/23.
//

import XCTest

final class FactoryDemoUITests: XCTestCase {

    @MainActor
    func testExample1() throws {
        let app = XCUIApplication()
        app.launchArguments.append("mock1")
        app.launch()

        let welcome = app.staticTexts["Mock Number 1! for Michael"]
        XCTAssert(welcome.exists)
    }

    @MainActor
    func testExample2() throws {
        let app = XCUIApplication()
        app.launchArguments.append("mock2")
        app.launch()

        let welcome = app.staticTexts["Mock Number 2! for Michael"]
        XCTAssert(welcome.exists)
    }

}
