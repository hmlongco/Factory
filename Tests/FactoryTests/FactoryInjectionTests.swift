import XCTest
@testable import Factory

class Services {
    @Injected(Factory.myServiceType) var service
    @Injected(Factory.mockService) var mock
    init() {}
}

final class FactoryInjectionTests: XCTestCase {

    override func setUp() {
        super.setUp()
        Factory.Registrations.reset()
    }

    func testBasicInjection() throws {
        let services = Services()
        XCTAssertTrue(services.service.text() == "MyService")
        XCTAssertTrue(services.mock.text() == "MockService")
    }

}
