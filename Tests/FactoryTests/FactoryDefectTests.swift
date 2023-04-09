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

    // CircularDependencyCheck failing when Factory depends upon Factory depends upon Factory of the same type
    func testCircularDependencyFailure() {
        expectNonFatalError() {
            let _ = Container.shared.circularFailure1()
        }
        expectNonFatalError() {
            let _ = Container.shared.circularFailure1()
        }
    }

    // Unable to correctly clear/set scope to unique using register function
    func testRegistrationClearsScope() throws {
        Container.shared.manager.reset()
        let service1 = Container.shared.cachedService()
        XCTAssertNotNil(service1)
        XCTAssertFalse(Container.shared.manager.isEmpty(.scope))
        Container.shared.manager.reset()
        Container.shared.singletonService
            .unique
            .register { MyService() }
        let service2 = Container.shared.cachedService()
        XCTAssertNotNil(service2)
        // scope defined in factory definition will still override last change
        XCTAssertFalse(Container.shared.manager.isEmpty(.scope))
        Container.shared.manager.reset()
        let service3 = Container.shared.scopedParameterService(8)
        XCTAssertNotNil(service3)
        XCTAssertFalse(Container.shared.manager.isEmpty(.scope))
        Container.shared.manager.reset()
        Container.shared.scopedParameterService
            .unique
            .register { ParameterService(value: $0) }
        let service4 = Container.shared.scopedParameterService(9)
        XCTAssertNotNil(service4)
        // scope defined in factory definition will still override last change
        XCTAssertFalse(Container.shared.manager.isEmpty(.scope))
    }

    // Registration on a new container could be overriden by auto registration
    func testRegistrationOverridenByAutoRegistration() throws {
        let container1 = AutoRegisteringContainer()
        let service1 = container1.test()
        XCTAssertEqual(service1.value, 32)
        let container2 = AutoRegisteringContainer()
        container2.test.register {
            MockServiceN(64)
        }
        let service2 = container2.test()
        XCTAssertEqual(service2.value, 64)
    }

    // AutoRegistration should have no effect on singletons
    func testAutoRegistrationAndSingletonCache() throws {
        let container1 = AutoRegisteringContainer()
        let service1 = container1.singletonTest()
        // should be auto registration value
        XCTAssertEqual(service1.value, 32)
        container1.singletonTest.register {
            MockServiceN(64)
        }
        let service2 = container1.singletonTest()
        // register should have cleared singleton scope cache so should be new value
        XCTAssertEqual(service2.value, 64)
        let container2 = AutoRegisteringContainer()
        let service3 = container2.singletonTest()
        // auto registration should have no effect on scope cache
        XCTAssertEqual(service3.value, 64)
    }

}

extension Container {
    fileprivate var circularFailure1: Factory<MyService> { self { self.circularFailure2() } }
    fileprivate var circularFailure2: Factory<MyService> { self { self.circularFailure3() } }
    fileprivate var circularFailure3: Factory<MyService> { self { MyService() } }
}


fileprivate class TestLazyInjectionOccursOnce {
    @LazyInjected(\.nilSService) var service
}

extension Container {
    fileprivate var lockingTestA: Factory<LockingTestA> { self { LockingTestA() }.singleton }
    fileprivate var lockingTestB: Factory<LockingTestB> { self { LockingTestB() }.singleton }
}

// classes for recursive resolution test
fileprivate class LockingTestA {
    @Injected(\.lockingTestB) var b: LockingTestB
    init() {}
}

fileprivate class LockingTestB {
    init() {}
}

fileprivate final class AutoRegisteringContainer: SharedContainer, AutoRegistering {
    static var shared = AutoRegisteringContainer()
    var test: Factory<MyServiceType> {
        self { MockServiceN(16) }
    }
    var singletonTest: Factory<MyServiceType> {
        self { MockServiceN(16) }.singleton
    }
    func autoRegister() {
        test.register { MockServiceN(32) }
        singletonTest.register { MockServiceN(32) }
    }
    var manager = ContainerManager()
}
