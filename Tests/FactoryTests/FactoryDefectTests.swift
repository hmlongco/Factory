import XCTest
@testable import Factory

final class FactoryDefectTests: XCTestCase {

    override func setUp() {
        super.setUp()
        Container.Registrations.reset()
        Container.Scope.reset()
    }

    // scope would not correctly resolve a factory with an optional type. e.g. Factory<MyType?>(scope: .cached) { nil }
    func testNilScopedService() throws {
        Container.nilCachedService.reset()
        let service1 = Container.nilCachedService()
        XCTAssertNil(service1)
        Container.nilCachedService.register {
            MyService()
        }
        let service2 = Container.nilCachedService()
        XCTAssertNotNil(service2)
    }

    // any registration of MyServiceType on any factory would satisfy any other factory also of MyServiceType
    // this prevented two factories with same base type
    func testDuplicateTypeDistinctResolution() throws {
        let service1: MyServiceType = Container.myServiceType()
        let service2: MyServiceType = Container.myServiceType2()
        XCTAssertTrue(service1.id != service2.id)
        XCTAssertTrue(service1.text() == "MyService")
        XCTAssertTrue(service2.text() == "MyService")
        Container.myServiceType.register { MockService() }
        let service3: MyServiceType = Container.myServiceType()
        let service4: MyServiceType = Container.myServiceType2()
        XCTAssertTrue(service1.id != service3.id)
        XCTAssertTrue(service2.id != service4.id)
        XCTAssertTrue(service3.id != service4.id)
        XCTAssertTrue(service3.text() == "MockService")
        XCTAssertTrue(service4.text() == "MyService")
    }

    // If lazy injecting an optional type factory would be called repeatedly. Resolution should attempted once.
    func testLazyInjectionOccursOnce() throws {
        Container.nilSService.reset()
        let service1 = TestLazyInjectionOccursOnce()
        XCTAssertNil(service1.service)
        Container.nilSService.register {
            MyService()
        }
        XCTAssertNil(service1.service)
    }

    // Nested injection when both are on the same scope locks thread. If this test passes then thread wasn't locked...
    func testSingletondScopeLocking() throws {
        let service1: LockingTestA? = Container.lockingTestA()
        XCTAssertNotNil(service1)
        let service2: LockingTestA? = Container.lockingTestA()
        XCTAssertNotNil(service2)
        let text1 = Container.singletonService().text()
        let text2 = Container.singletonService().text()
        XCTAssertTrue(text1 == text2)
    }

    // Shared scope caching failed when caching a non-optional protocol
    func testProtocolSharedScope() throws {
        var service1: MyServiceType? = Container.sharedExplicitProtocol()
        var service2: MyServiceType? = Container.sharedExplicitProtocol()
        XCTAssertNotNil(service1)
        XCTAssertNotNil(service2)
        // Shared cached item ids should match
        XCTAssertTrue(service1?.id == service2?.id)
        service1 = nil
        service2 = nil
        let service3: MyServiceType? = Container.sharedExplicitProtocol()
        XCTAssertNotNil(service3)
        // Shared instance should have released so new and old ids should not match
        XCTAssertTrue(service2?.id != service3?.id)
    }

    // Shared scope caching feiled when caching a non-optional protocol value
    func testProtocolSharedValueScope() throws {
        var service1: MyServiceType? = Container.sharedValueProtocol()
        var service2: MyServiceType? = Container.sharedValueProtocol()
        XCTAssertNotNil(service1)
        XCTAssertNotNil(service2)
        // Shared cached item ids should NOT match
        XCTAssertTrue(service1?.id != service2?.id)
        // Nothing should be cached
        XCTAssertTrue(Container.Scope.shared.isEmpty)
        service1 = nil
        service2 = nil
        let service3: MyServiceType? = Container.sharedValueProtocol()
        XCTAssertNotNil(service3)
        // Shared instance should have released so new and old ids should not match
        XCTAssertTrue(service2?.id != service3?.id)
    }

}

fileprivate class TestLazyInjectionOccursOnce {
    @LazyInjected(Container.nilSService) var service
}

extension Container {
    fileprivate static var lockingTestA = Factory(scope: .singleton) { LockingTestA() }
    fileprivate static var lockingTestB = Factory(scope: .singleton) { LockingTestB() }
}

// classes for recursive resolution test
fileprivate class LockingTestA {
    @Injected(Container.lockingTestB) var b: LockingTestB
    init() {}
}

fileprivate class LockingTestB {
    init() {}
}
