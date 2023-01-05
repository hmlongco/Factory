//
//  FactoryDemoUITests.swift
//  FactoryDemoUITests
//
//  Created by Michael Long on 1/4/23.
//

import XCTest

final class FactoryDemoUITests: XCTestCase {

    func testExample() throws {
        let app = XCUIApplication()
        app.launchArguments.append("-mock1")
        app.launch()

        let welcome = app.staticTexts["Mock Number 1! for Michael"]
        XCTAssert(welcome.exists)
    }

}
