//
//  FactoryDemoTests.swift
//  FactoryDemoTests
//
//  Created by Michael Long on 4/3/23.
//

import XCTest
import Factory

@testable import FactoryDemo

final class FactoryDemoTests3: XCTestCase {

    let delay: UInt64 = 250_000_000

    override func setUpWithError() throws {
        Container.shared.reset()
    }

    override func tearDownWithError() throws {
        Scope.singleton.reset()
    }

    func testExample1() async throws {
        try await Task.sleep(nanoseconds: delay)
        let name = "tests3Example1"
        Container.shared.contextService.register { ContextService(name: name) }
        XCTAssertEqual(Container.shared.contextService().name, name)
    }

    func testExample2() async throws {
        try await Task.sleep(nanoseconds: delay)
        let name = "tests3Example2"
        Container.shared.contextService.register { ContextService(name: name) }
        XCTAssertEqual(Container.shared.contextService().name, name)
    }

    func testExample3() async throws {
        try await Task.sleep(nanoseconds: delay)
        let name = "tests3Example3"
        Container.shared.contextService.register { ContextService(name: name) }
        XCTAssertEqual(Container.shared.contextService().name, name)
    }

    func testExample4() async throws {
        try await Task.sleep(nanoseconds: delay)
        let name = "tests3Example4"
        Container.shared.contextService.register { ContextService(name: name) }
        XCTAssertEqual(Container.shared.contextService().name, name)
    }

    func testExample5() async throws {
        try await Task.sleep(nanoseconds: delay)
        let name = "tests3Example5"
        Container.shared.contextService.register { ContextService(name: name) }
        XCTAssertEqual(Container.shared.contextService().name, name)
    }

    func testExample6() async throws {
        try await Task.sleep(nanoseconds: delay)
        let name = "tests3Example6"
        Container.shared.contextService.register { ContextService(name: name) }
        XCTAssertEqual(Container.shared.contextService().name, name)
    }

    func testExample7() async throws {
        try await Task.sleep(nanoseconds: delay)
        let name = "tests3Example7"
        Container.shared.contextService.register { ContextService(name: name) }
        XCTAssertEqual(Container.shared.contextService().name, name)
    }

    func testExample8() async throws {
        try await Task.sleep(nanoseconds: delay)
        let name = "tests3Example8"
        Container.shared.contextService.register { ContextService(name: name) }
        XCTAssertEqual(Container.shared.contextService().name, name)
    }

    func testExample9() async throws {
        try await Task.sleep(nanoseconds: delay)
        let name = "tests3Example9"
        Container.shared.contextService.register { ContextService(name: name) }
        XCTAssertEqual(Container.shared.contextService().name, name)
    }

    func testExample10() async throws {
        try await Task.sleep(nanoseconds: delay)
        let name = "tests3Example10"
        Container.shared.contextService.register { ContextService(name: name) }
        XCTAssertEqual(Container.shared.contextService().name, name)
    }

}
