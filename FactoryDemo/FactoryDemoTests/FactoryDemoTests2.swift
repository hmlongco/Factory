//
//  FactoryDemoTests.swift
//  FactoryDemoTests
//
//  Created by Michael Long on 4/3/23.
//

import XCTest
import FactoryMacros

@testable import FactoryDemo

final class FactoryDemoTests2: XCTestCase {

    let delay: UInt64 = 500_000_000

    override func setUpWithError() throws {
        Container.shared.reset()
    }

    override func tearDownWithError() throws {
        Scope.singleton.reset()
    }

    func testExample1() async throws {
        try await Task.sleep(nanoseconds: delay)
        let name = "tests2Example1"
        Container.shared.contextService.register { ContextService(name: name) }
        XCTAssertEqual(Container.shared.contextService().name, name)
    }

    func testExample2() async throws {
        try await Task.sleep(nanoseconds: delay)
        let name = "tests2Example2"
        Container.shared.contextService.register { ContextService(name: name) }
        XCTAssertEqual(Container.shared.contextService().name, name)
    }

    func testExample3() async throws {
        for _ in 0..<100 {
            let name = "tests2Example3"
            Container.shared.contextService.register { ContextService(name: name) }
            XCTAssertEqual(Container.shared.contextService().name, name)
            try await Task.sleep(nanoseconds: 1_000_000)
        }
     }

    func testExample4() async throws {
        try await Task.sleep(nanoseconds: delay)
        let name = "tests2Example4"
        Container.shared.contextService.register { ContextService(name: name) }
        XCTAssertEqual(Container.shared.contextService().name, name)
    }

    func testExample5() async throws {
        for _ in 0..<100 {
            let name = "tests2Example5"
            Container.shared.contextService.register { ContextService(name: name) }
            XCTAssertEqual(Container.shared.contextService().name, name)
            try await Task.sleep(nanoseconds: 1_000_000)
        }
    }

    func testExample6() async throws {
        try await Task.sleep(nanoseconds: delay)
        let name = "tests2Example6"
        Container.shared.contextService.register { ContextService(name: name) }
        XCTAssertEqual(Container.shared.contextService().name, name)
    }

    func testExample7() async throws {
        try await Task.sleep(nanoseconds: delay)
        let name = "tests2Example7"
        Container.shared.contextService.register { ContextService(name: name) }
        XCTAssertEqual(Container.shared.contextService().name, name)
    }

    func testExample8() async throws {
        try await Task.sleep(nanoseconds: delay)
        let name = "tests2Example8"
        Container.shared.contextService.register { ContextService(name: name) }
        XCTAssertEqual(Container.shared.contextService().name, name)
    }

    func testExample9() async throws {
        try await Task.sleep(nanoseconds: delay)
        let name = "tests2Example9"
        Container.shared.contextService.register { ContextService(name: name) }
        XCTAssertEqual(Container.shared.contextService().name, name)
    }

    func testExample10() async throws {
        try await Task.sleep(nanoseconds: delay)
        let name = "tests2Example10"
        Container.shared.contextService.register { ContextService(name: name) }
        XCTAssertEqual(Container.shared.contextService().name, name)
    }

}
