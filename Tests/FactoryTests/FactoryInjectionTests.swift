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

class Services5 {
    @Injected(Container.optionalService) var service
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

}
