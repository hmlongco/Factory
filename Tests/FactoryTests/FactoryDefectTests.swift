import XCTest
@testable import Factory

final class FactoryDefectTests: XCTestCase {

    override func setUp() {
        super.setUp()
        Container.shared = Container()
    }

    // scope would not correctly resolve a factory with an optional type. e.g. Factory<MyType?>(scope: .cached) { nil }
    func testNilScopedService() throws {
        Container.shared.nilCachedService.reset()
        let service1 = Container.shared.nilCachedService()
        XCTAssertNil(service1)
        Container.shared.nilCachedService.register {
            MyService()
        }
        let service2 = Container.shared.nilCachedService()
        XCTAssertNotNil(service2)
    }

    // any registration of MyServiceType on any factory would satisfy any other factory also of MyServiceType
    // this prevented two factories with same base type
    func testDuplicateTypeDistinctResolution() throws {
        let service1: MyServiceType = Container.shared.myServiceType()
        let service2: MyServiceType = Container.shared.myServiceType2()
        XCTAssertTrue(service1.id != service2.id)
        XCTAssertTrue(service1.text() == "MyService")
        XCTAssertTrue(service2.text() == "MyService")
        Container.shared.myServiceType.register { MockService() }
        let service3: MyServiceType = Container.shared.myServiceType()
        let service4: MyServiceType = Container.shared.myServiceType2()
        XCTAssertTrue(service1.id != service3.id)
        XCTAssertTrue(service2.id != service4.id)
        XCTAssertTrue(service3.id != service4.id)
        XCTAssertTrue(service3.text() == "MockService")
        XCTAssertTrue(service4.text() == "MyService")
    }

    // If lazy injecting an optional type factory would be called repeatedly. Resolution should attempted once.
    func testLazyInjectionOccursOnce() throws {
        Container.shared.nilSService.reset()
        let service1 = TestLazyInjectionOccursOnce()
        XCTAssertNil(service1.service)
        Container.shared.nilSService.register {
            MyService()
        }
        XCTAssertNil(service1.service)
    }

    // Nested injection when both are on the same scope locks thread. If this test passes then thread wasn't locked...
    func testSingletondScopeLocking() throws {
        let service1: LockingTestA? = Container.shared.lockingTestA()
        XCTAssertNotNil(service1)
        let service2: LockingTestA? = Container.shared.lockingTestA()
        XCTAssertNotNil(service2)
        let text1 = Container.shared.singletonService().text()
        let text2 = Container.shared.singletonService().text()
        XCTAssertTrue(text1 == text2)
    }

    // Shared scope caching failed when caching a non-optional protocol
    func testProtocolSharedScope() throws {
        var service1: MyServiceType? = Container.shared.sharedExplicitProtocol()
        var service2: MyServiceType? = Container.shared.sharedExplicitProtocol()
        XCTAssertNotNil(service1)
        XCTAssertNotNil(service2)
        // Shared cached item ids should match
        XCTAssertTrue(service1?.id == service2?.id)
        service1 = nil
        service2 = nil
        let service3: MyServiceType? = Container.shared.sharedExplicitProtocol()
        XCTAssertNotNil(service3)
        // Shared instance should have released so new and old ids should not match
        XCTAssertTrue(service2?.id != service3?.id)
    }

    // Shared scope caching failed when caching a non-optional protocol value
    func testProtocolSharedValueScope() throws {
        var service1: MyServiceType? = Container.shared.sharedValueProtocol()
        var service2: MyServiceType? = Container.shared.sharedValueProtocol()
        XCTAssertNotNil(service1)
        XCTAssertNotNil(service2)
        // Shared cached item ids should NOT match
        XCTAssertTrue(service1?.id != service2?.id)
        // Nothing should be cached
        // FIX XCTAssertTrue(Container.shared.Scope.shared.isEmpty)
        service1 = nil
        service2 = nil
        let service3: MyServiceType? = Container.shared.sharedValueProtocol()
        XCTAssertNotNil(service3)
        // Shared instance should have released so new and old ids should not match
        XCTAssertTrue(service2?.id != service3?.id)
    }

}

fileprivate class TestLazyInjectionOccursOnce {
    @LazyInjected(\.nilSService) var service
}

extension Container {
    fileprivate var lockingTestA: Factory<LockingTestA> { make { LockingTestA() }.singleton }
    fileprivate var lockingTestB: Factory<LockingTestB> { make { LockingTestB() }.singleton }
}

// classes for recursive resolution test
fileprivate class LockingTestA {
    @Injected(\.lockingTestB) var b: LockingTestB
    init() {}
}

fileprivate class LockingTestB {
    init() {}
}
