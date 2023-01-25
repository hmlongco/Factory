import XCTest
@testable import Factory

final class FactoryScopeTests: XCTestCase {

    override func setUp() {
        super.setUp()
        Container.shared = Container()
    }

    func testUniqueScope() throws {
        let service1 = Container.shared.myServiceType()
        let service2 = Container.shared.myServiceType()
        XCTAssertTrue(service1.id != service2.id)
    }

    func testCachedScope() throws {
        let service1 = Container.shared.cachedService()
        let service2 = Container.shared.cachedService()
        XCTAssertTrue(service1.id == service2.id)
        let service3 = Container.shared.cachedService()
        XCTAssertTrue(service2.id == service3.id)
    }

    func testOptionalCachedScope() throws {
        let service1: MyServiceType? = Container.shared.cachedOptionalService()
        let service2: MyServiceType? = Container.shared.cachedOptionalService()
        XCTAssertNotNil(service1)
        XCTAssertNotNil(service2)
        // Shared cached item ids should match
        XCTAssertTrue(service1?.id == service2?.id)
        let oldID = service1?.id
        XCTAssertNotNil(oldID)
        // Clear cache
        Container.shared.manager.reset()
        let service3: MyServiceType? = Container.shared.cachedOptionalService()
        XCTAssertNotNil(service3)
        // Shared instance should have released so new and old ids should not match
        XCTAssertTrue(oldID != service3?.id)
    }

    func testEmptyOptionalCachedScope() throws {
        let emptyService1: MyServiceType? = Container.shared.cachedEmptyOptionalService()
        let emptyService2: MyServiceType? = Container.shared.cachedEmptyOptionalService()
        XCTAssertNil(emptyService1)
        XCTAssertNil(emptyService2)
        // test caching after registration
        Container.shared.cachedEmptyOptionalService.register { MyService() }
        let service1: MyServiceType? = Container.shared.cachedOptionalService()
        let service2: MyServiceType? = Container.shared.cachedOptionalService()
        XCTAssertNotNil(service1)
        XCTAssertNotNil(service2)
        // Shared cached item ids should match
        XCTAssertTrue(service1?.id == service2?.id)
        let oldID = service1?.id
        XCTAssertNotNil(oldID)
        // Clear cache
        Container.shared.manager.reset()
        let service3: MyServiceType? = Container.shared.cachedOptionalService()
        XCTAssertNotNil(service3)
        // Shared instance should have released so new and old ids should not match
        XCTAssertTrue(oldID != service3?.id)
    }

    func testCachedScopeGlobalReset() throws {
        let service1 = Container.shared.cachedService()
        let service2 = Container.shared.cachedService()
        XCTAssertTrue(service1.id == service2.id)
        Container.shared.manager.reset()
        let service3 = Container.shared.cachedService()
        XCTAssertTrue(service2.id != service3.id)
    }

    func testCachedScopeAutoRelease() throws {
        let service1 = Container.shared.cachedService()
        let service2 = Container.shared.cachedService()
        XCTAssertTrue(service1.id == service2.id)
        Container.shared.cachedService.register { MyService() }
        let service3 = Container.shared.cachedService()
        XCTAssertTrue(service2.id != service3.id)
    }

    func testSharedScope() throws {
        var service1: MyServiceType? = Container.shared.sharedService()
        var service2: MyServiceType? = Container.shared.sharedService()
        XCTAssertNotNil(service1)
        XCTAssertNotNil(service2)
        // Shared cached item ids should match
        XCTAssertTrue(service1?.id == service2?.id)
        let oldID = service1?.id
        XCTAssertNotNil(oldID)
        service1 = nil
        service2 = nil
        let service3: MyServiceType? = Container.shared.sharedService()
        XCTAssertNotNil(service3)
        // Shared instance should have released so new and old ids should not match
        XCTAssertTrue(oldID != service3?.id)
    }

    func testGraphScope() throws {
        // Has base to graph scope
        let graph1 = Container.shared.graphWrapper()
        XCTAssertTrue(graph1.service1.id == graph1.service2.id)
        XCTAssertTrue(Container.shared.manager.cache.isEmpty)
        // No base to the graph scope
        let graph2 = GraphWrapper()
        XCTAssertTrue(graph2.service1.id != graph2.service2.id)
        XCTAssertTrue(Container.shared.manager.cache.isEmpty)
    }

    func testExplicitProtocolSharedScope() throws {
        var service1: MyServiceType? = Container.shared.sharedExplicitProtocol()
        var service2: MyServiceType? = Container.shared.sharedExplicitProtocol()
        XCTAssertNotNil(service1)
        XCTAssertNotNil(service2)
        // Shared cached item ids should match
        XCTAssertTrue(service1?.id == service2?.id)
        let oldID = service1?.id
        XCTAssertNotNil(oldID)
        service1 = nil
        service2 = nil
        let service3: MyServiceType? = Container.shared.sharedExplicitProtocol()
        XCTAssertNotNil(service3)
        // Shared instance should have released so new and old ids should not match
        XCTAssertTrue(oldID != service3?.id)
    }

    func testInferredProtocolSharedScope() throws {
        var service1: MyServiceType? = Container.shared.sharedInferredProtocol()
        var service2: MyServiceType? = Container.shared.sharedInferredProtocol()
        XCTAssertNotNil(service1)
        XCTAssertNotNil(service2)
        // Shared cached item ids should match
        XCTAssertTrue(service1?.id == service2?.id)
        let oldID = service1?.id
        XCTAssertNotNil(oldID)
        service1 = nil
        service2 = nil
        let service3: MyServiceType? = Container.shared.sharedInferredProtocol()
        XCTAssertNotNil(service3)
        // Shared instance should have released so new and old ids should not match
        XCTAssertTrue(oldID != service3?.id)
    }

    func testOptionalSharedScope() throws {
        var service1: MyServiceType? = Container.shared.sharedOptionalProtocol()
        var service2: MyServiceType? = Container.shared.sharedOptionalProtocol()
        XCTAssertNotNil(service1)
        XCTAssertNotNil(service2)
        // Shared cached item ids should match
        XCTAssertTrue(service1?.id == service2?.id)
        let oldID = service1?.id
        XCTAssertNotNil(oldID)
        service1 = nil
        service2 = nil
        let service3: MyServiceType? = Container.shared.sharedOptionalProtocol()
        XCTAssertNotNil(service3)
        // Shared instance should have released so new and old ids should not match
        XCTAssertTrue(oldID != service3?.id)
    }

    func testOptionalValueSharedScope() throws {
        var service1: MyServiceType? = Container.shared.optionalValueService()
        var service2: MyServiceType? = Container.shared.optionalValueService()
        XCTAssertNotNil(service1)
        XCTAssertNotNil(service2)
        // Value types aren't shared so cached item ids should NOT match
        XCTAssertTrue(service1?.id != service2?.id)
        let oldID = service1?.id
        XCTAssertNotNil(oldID)
        service1 = nil
        service2 = nil
        let service3: MyServiceType? = Container.shared.optionalValueService()
        XCTAssertNotNil(service3)
        // New and old ids should still not match
        XCTAssertTrue(oldID != service3?.id)
    }

    func testSharedScopeGlobalReset() throws {
        let service1: MyServiceType = Container.shared.sharedService()
        let service2: MyServiceType = Container.shared.sharedService()
        XCTAssertTrue(service1.id == service2.id)
        Container.shared.manager.reset()
        let service3: MyServiceType? = Container.shared.sharedService()
        XCTAssertTrue(service2.id != service3?.id)
    }

    func testSharedScopeAutoRelease() throws {
        let service1 = Container.shared.sharedService()
        let service2 = Container.shared.sharedService()
        XCTAssertTrue(service1.id == service2.id)
        Container.shared.sharedService.register { MyService() }
        let service3 = Container.shared.sharedService()
        XCTAssertTrue(service2.id != service3.id)
    }

    func testSingletondScope() throws {
        let service1 = Container.shared.singletonService()
        let service2 = Container.shared.singletonService()
        XCTAssertTrue(service1.id == service2.id)
        let service3 = Container.shared.singletonService()
        XCTAssertTrue(service2.id == service3.id)
    }

    func testSingletondScopeGlobalReset() throws {
        let service1: MyServiceType = Container.shared.singletonService()
        let service2: MyServiceType = Container.shared.singletonService()
        XCTAssertTrue(service1.id == service2.id)
        Container.shared.manager.reset(scope: .singleton)
        let service3: MyServiceType? = Container.shared.singletonService()
        XCTAssertTrue(service2.id != service3?.id)
    }

    func testCustomCachedScope() throws {
        let service1 = Container.shared.sessionService()
        let service2 = Container.shared.sessionService()
        XCTAssertTrue(service1.id == service2.id)
        Container.shared.manager.reset(scope: .session)
        let service3 = Container.shared.sessionService()
        XCTAssertTrue(service2.id != service3.id)
    }

    func testValueCachedScope() throws {
        let service1 = Container.shared.valueService()
        let service2 = Container.shared.valueService()
        XCTAssertTrue(service1.id == service2.id)
        Container.shared.manager.reset(scope: .cached)
        let service3 = Container.shared.valueService()
        XCTAssertTrue(service2.id != service3.id)
    }

    func testValueSharedScope() throws {
        let service1 = Container.shared.sharedValueService()
        let service2 = Container.shared.sharedValueService()
        XCTAssertTrue(service1.id != service2.id) // value types can't be shared
    }

    func testNilService() throws {
        Container.shared.nilSService.reset()
        let service1 = Container.shared.nilSService()
        XCTAssertNil(service1)
        Container.shared.nilSService.register {
            MyService()
        }
        let service2 = Container.shared.nilSService()
        XCTAssertNotNil(service2)
    }

    func testNilScopedServiceCaching() throws {
        Container.shared.nilCachedService.reset()
        XCTAssertTrue(Container.shared.manager.cache.isEmpty)
        let service1 = Container.shared.nilCachedService()
        XCTAssertNil(service1)
        XCTAssertTrue(Container.shared.manager.cache.isEmpty) // nothing caches
        let service2 = Container.shared.nilCachedService()
        XCTAssertNil(service2)
        XCTAssertTrue(Container.shared.manager.cache.isEmpty) // nothing caches
        Container.shared.nilCachedService.register {
            MyService()
        }
        let service3 = Container.shared.nilCachedService()
        XCTAssertNotNil(service3)
        XCTAssertFalse(Container.shared.manager.cache.isEmpty) // cached value
        Container.shared.nilCachedService.register {
            nil
        }
        let service4 = Container.shared.nilCachedService()
        XCTAssertNil(service4) // cache was reset by registration
        XCTAssertTrue(Container.shared.manager.cache.isEmpty) // nothing cached
    }

    func testNilSharedServiceCaching() throws {
        Container.shared.nilSharedService.reset()
        XCTAssertTrue(Container.shared.manager.cache.isEmpty)
        let service1 = Container.shared.nilSharedService()
        XCTAssertNil(service1)
        XCTAssertTrue(Container.shared.manager.cache.isEmpty) // nothing caches
        let service2 = Container.shared.nilSharedService()
        XCTAssertNil(service2)
        XCTAssertTrue(Container.shared.manager.cache.isEmpty) // nothing caches
        Container.shared.nilSharedService.register {
            MyService()
        }
        let service3 = Container.shared.nilSharedService()
        XCTAssertNotNil(service3)
        let service4 = Container.shared.nilSharedService()
        XCTAssertNotNil(service4)
        XCTAssertTrue(service3?.id == service4?.id)
        XCTAssertFalse(Container.shared.manager.cache.isEmpty) // cached value
        Container.shared.nilSharedService.register {
            nil
        }
        let service5 = Container.shared.nilSharedService()
        XCTAssertNil(service5) // cache was reset by registration
        XCTAssertTrue(Container.shared.manager.cache.isEmpty) // nothing cached
    }

    func testImplementsGraphScope() throws {
        // Has base to graph scope
        let consumer = Container.shared.consumer()
        XCTAssertTrue(consumer.ids.id == consumer.values.id)
        XCTAssertTrue(Container.shared.manager.cache.isEmpty)
        // No base to the graph scope
        let consumer2 = ProtocolConsumer()
        XCTAssertTrue(consumer2.ids.id != consumer2.values.id)
        XCTAssertTrue(Container.shared.manager.cache.isEmpty)
    }

}
