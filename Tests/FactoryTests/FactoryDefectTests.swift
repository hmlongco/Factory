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

}

private class TestLazyInjectionOccursOnce {
    @LazyInjected(Container.nilSService) var service
}
