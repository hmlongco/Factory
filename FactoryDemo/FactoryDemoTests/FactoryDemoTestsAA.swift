//
//  FactoryDemoTests.swift
//  FactoryDemoTests
//
//  Created by Michael Long on 4/5/23.
//
//  Testing issue https://github.com/hmlongco/Factory/issues/114
//

import XCTest

@testable import FactoryDemo

final class FactoryDemoTestsAA: XCTestCase {

    override func setUpWithError() throws {
        AAContainer.shared.manager.push()
    }

    override func tearDownWithError() throws {
        AAContainer.shared.manager.pop()
    }

    func testMock() {
        AAContainer.shared.service.register {
            AAMockService()
        }
        let sut = AAViewModel()
        XCTAssertEqual(sut.name, "MockService")
    }

    func testMock2() {
        AAContainer.shared.service.onTest {
            AAMockService()
        }
        let sut = AAViewModel()
        XCTAssertEqual(sut.name, "MockService")
    }

}
