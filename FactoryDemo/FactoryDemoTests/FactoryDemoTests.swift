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

    func testExample() async throws {
        let test1 = Container.shared.commonType()
        XCTAssertNotNil(test1)
        let test2 = Container.shared.promisedType()
        XCTAssertNotNil(test2)
        
        for _ in 0..<100 {
            let name = "tests2Example3"
            Container.shared.contextService.register { ContextService(name: name) }
            XCTAssertEqual(Container.shared.contextService().name, name)
            try await Task.sleep(nanoseconds: 1_000_000)
        }
    }

}
