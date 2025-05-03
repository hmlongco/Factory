//
//  FactoryDemoTests.swift
//  FactoryDemoTests
//
//  Created by Michael Long on 4/5/23.
//

import XCTest
import Factory
import Common

@testable import FactoryDemo

final class FactoryDemoTests: XCTestCase {

    override func setUpWithError() throws {
        Container.shared.fatalType.register { TestFatalCommonType() }
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() async throws {
        let test1 = Container.shared.commonType()
        XCTAssertNotNil(test1)
        let test2 = Container.shared.promisedType()
        XCTAssertNotNil(test2)
        let test3 = Container.shared.fatalType()
        XCTAssertNotNil(test3)

        for _ in 0..<100 {
            let name = "tests2Example3"
            Container.shared.contextService.register { ContextService(name: name) }
            XCTAssertEqual(Container.shared.contextService().name, name)
            try await Task.sleep(nanoseconds: 1_000_000)
        }
    }

}

public class TestFatalCommonType: CommonType {
    public init() {}
    public func test() {
        print("TestFatalCommonType Test")
    }
}
