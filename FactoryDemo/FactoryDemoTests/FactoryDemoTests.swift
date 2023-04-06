//
//  FactoryDemoTests.swift
//  FactoryDemoTests
//
//  Created by Michael Long on 4/5/23.
//

import XCTest
import Factory
@testable import FactoryDemo

final class FactoryDemoTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        let test1 = Container.shared.commonType()
        XCTAssertNotNil(test1)
        let test2 = Container.shared.promisedType()
        XCTAssertNotNil(test2)
    }

}
