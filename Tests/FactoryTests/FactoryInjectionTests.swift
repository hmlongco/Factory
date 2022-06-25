import XCTest
@testable import Factory

class Services1 {
    @Injected(Container.myServiceType) var service
    @Injected(Container.mockService) var mock
    init() {}
}

class Services2 {
    @LazyInjected(Container.myServiceType) var service
    @LazyInjected(Container.mockService) var mock
    init() {}
}

class Services3 {
    @Injected(unsafe: MyServiceType.self) var service
    @Injected(unsafe: MockService.self) var mock
    init() {}
}

class Services4 {
    @LazyInjected(unsafe: MyServiceType.self) var service
    @LazyInjected(unsafe: MockService.self) var mock
    init() {}
}

class Services5 {
    @Injected(Container.optionalService) var service
    init() {}
}

class Services6 {
    @Injected(Container.unsafeService) var service
    init() {}
}


final class FactoryInjectionTests: XCTestCase {

    override func setUp() {
        super.setUp()
        Container.Registrations.reset()
        Container.Scope.reset()
    }

    func testBasicInjection() throws {
        let services = Services1()
        XCTAssertTrue(services.service.text() == "MyService")
        XCTAssertTrue(services.mock.text() == "MockService")
    }

    func testLazyInjection() throws {
        let services = Services2()
        XCTAssertTrue(services.service.text() == "MyService")
        XCTAssertTrue(services.mock.text() == "MockService")
    }

    func testLazyInjectionOccursOnce() throws {
        let services = Services2()
        let id1 = services.service.id
        let id2 = services.service.id
        XCTAssertTrue(id1 == id2)
    }

    func testOptionalInjection() throws {
        let services = Services5()
        XCTAssertTrue(services.service?.text() == "MyService")
    }

    func testUnsafeTypeInjection() throws {
        Container.shared.register { MyService() as MyServiceType }
        Container.shared.register { MockService() }
        let services = Services3()
        XCTAssertTrue(services.service.text() == "MyService")
        XCTAssertTrue(services.mock.text() == "MockService")
    }

    func testLazyUnsafeTypeInjection() throws {
        Container.shared.register { MyService() as MyServiceType }
        Container.shared.register { MockService() }
        let services = Services4()
        XCTAssertTrue(services.service.text() == "MyService")
        XCTAssertTrue(services.mock.text() == "MockService")
    }

    func testUnsafeFactoryInjection() throws {
        Container.unsafeService.register { MyService() }
        let services = Services6()
        XCTAssertTrue(services.service.text() == "MyService")
    }

}
