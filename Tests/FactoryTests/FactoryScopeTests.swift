import XCTest
@testable import Factory

final class FactoryScopeTests: XCTestCase {

    override func setUp() {
        super.setUp()
        Factory.Registrations.reset()
        Factory.Scope.cached.reset()
    }

    func testUniqueScope() throws {
        let service1 = Factory.myServiceType()
        let service2 = Factory.myServiceType()
        XCTAssertTrue(service1.id != service2.id)
    }

    func testCachedScope() throws {
        let service1 = Factory.cachedService()
        let service2 = Factory.cachedService()
        XCTAssertTrue(service1.id == service2.id)
        let service3 = Factory.cachedService()
        XCTAssertTrue(service2.id == service3.id)
    }

    func testCachedScopeGlobalReset() throws {
        let service1 = Factory.cachedService()
        let service2 = Factory.cachedService()
        XCTAssertTrue(service1.id == service2.id)
        Factory.Scope.cached.reset()
        let service3 = Factory.cachedService()
        XCTAssertTrue(service2.id != service3.id)
    }

    func testCachedScopeAutoRelease() throws {
        let service1 = Factory.cachedService()
        let service2 = Factory.cachedService()
        XCTAssertTrue(service1.id == service2.id)
        Factory.cachedService.register { MyService() }
        let service3 = Factory.cachedService()
        XCTAssertTrue(service2.id != service3.id)
    }

    func testSharedScope() throws {
        var service1: MyService? = Factory.sharedService()
        var service2: MyService? = Factory.sharedService()
        XCTAssertTrue(service1?.id == service2?.id)
        service1 = nil
        service2 = nil
        let service3: MyService? = Factory.sharedService()
        XCTAssertTrue(service2?.id != service3?.id)
    }

    func testSharedScopeGlobalReset() throws {
        let service1: MyService = Factory.sharedService()
        let service2: MyService = Factory.sharedService()
        XCTAssertTrue(service1.id == service2.id)
        Factory.Scope.shared.reset()
        let service3: MyService? = Factory.sharedService()
        XCTAssertTrue(service2.id != service3?.id)
    }

    func testSharedScopeAutoRelease() throws {
        let service1 = Factory.sharedService()
        let service2 = Factory.sharedService()
        XCTAssertTrue(service1.id == service2.id)
        Factory.sharedService.register { MyService() }
        let service3 = Factory.sharedService()
        XCTAssertTrue(service2.id != service3.id)
    }

    func testSingletondScope() throws {
        let service1 = Factory.singletonService()
        let service2 = Factory.singletonService()
        XCTAssertTrue(service1.id == service2.id)
        let service3 = Factory.singletonService()
        XCTAssertTrue(service2.id == service3.id)
    }

    func testSingletondScopeGlobalReset() throws {
        let service1: MyService = Factory.singletonService()
        let service2: MyService = Factory.singletonService()
        XCTAssertTrue(service1.id == service2.id)
        Factory.Scope.singleton.reset()
        let service3: MyService? = Factory.singletonService()
        XCTAssertTrue(service2.id != service3?.id)
    }

    func testCustomCachedScope() throws {
        let service1 = Factory.sessionService()
        let service2 = Factory.sessionService()
        XCTAssertTrue(service1.id == service2.id)
        Factory.Scope.session.reset()
        let service3 = Factory.sessionService()
        XCTAssertTrue(service2.id != service3.id)
    }

}
