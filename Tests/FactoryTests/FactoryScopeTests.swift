import XCTest
@testable import Factory

final class FactoryScopeTests: XCTestCase {

    override func setUp() {
        super.setUp()
        Container.Registrations.reset()
        Container.Scope.cached.reset()
    }

    func testUniqueScope() throws {
        let service1 = Container.myServiceType()
        let service2 = Container.myServiceType()
        XCTAssertTrue(service1.id != service2.id)
    }

    func testCachedScope() throws {
        let service1 = Container.cachedService()
        let service2 = Container.cachedService()
        XCTAssertTrue(service1.id == service2.id)
        let service3 = Container.cachedService()
        XCTAssertTrue(service2.id == service3.id)
    }

    func testCachedScopeGlobalReset() throws {
        let service1 = Container.cachedService()
        let service2 = Container.cachedService()
        XCTAssertTrue(service1.id == service2.id)
        Container.Scope.cached.reset()
        let service3 = Container.cachedService()
        XCTAssertTrue(service2.id != service3.id)
    }

    func testCachedScopeAutoRelease() throws {
        let service1 = Container.cachedService()
        let service2 = Container.cachedService()
        XCTAssertTrue(service1.id == service2.id)
        Container.cachedService.register { MyService() }
        let service3 = Container.cachedService()
        XCTAssertTrue(service2.id != service3.id)
    }

    func testSharedScope() throws {
        var service1: MyService? = Container.sharedService()
        var service2: MyService? = Container.sharedService()
        XCTAssertTrue(service1?.id == service2?.id)
        service1 = nil
        service2 = nil
        let service3: MyService? = Container.sharedService()
        XCTAssertTrue(service2?.id != service3?.id)
    }

    func testSharedScopeGlobalReset() throws {
        let service1: MyService = Container.sharedService()
        let service2: MyService = Container.sharedService()
        XCTAssertTrue(service1.id == service2.id)
        Container.Scope.shared.reset()
        let service3: MyService? = Container.sharedService()
        XCTAssertTrue(service2.id != service3?.id)
    }

    func testSharedScopeAutoRelease() throws {
        let service1 = Container.sharedService()
        let service2 = Container.sharedService()
        XCTAssertTrue(service1.id == service2.id)
        Container.sharedService.register { MyService() }
        let service3 = Container.sharedService()
        XCTAssertTrue(service2.id != service3.id)
    }

    func testSingletondScope() throws {
        let service1 = Container.singletonService()
        let service2 = Container.singletonService()
        XCTAssertTrue(service1.id == service2.id)
        let service3 = Container.singletonService()
        XCTAssertTrue(service2.id == service3.id)
    }

    func testSingletondScopeGlobalReset() throws {
        let service1: MyService = Container.singletonService()
        let service2: MyService = Container.singletonService()
        XCTAssertTrue(service1.id == service2.id)
        Container.Scope.singleton.reset()
        let service3: MyService? = Container.singletonService()
        XCTAssertTrue(service2.id != service3?.id)
    }

    func testCustomCachedScope() throws {
        let service1 = Container.sessionService()
        let service2 = Container.sessionService()
        XCTAssertTrue(service1.id == service2.id)
        Container.Scope.session.reset()
        let service3 = Container.sessionService()
        XCTAssertTrue(service2.id != service3.id)
    }

}
