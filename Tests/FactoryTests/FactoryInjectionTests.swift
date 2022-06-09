import XCTest
@testable import Factory

class Services {
    @Injected(Container.myServiceType) var service
    @Injected(Container.mockService) var mock
    init() {}
}

final class FactoryInjectionTests: XCTestCase {

    override func setUp() {
        super.setUp()
        Container.Registrations.reset()
        Container.Scope.reset()
    }

    func testBasicInjection() throws {
        let services = Services()
        XCTAssertTrue(services.service.text() == "MyService")
        XCTAssertTrue(services.mock.text() == "MockService")
    }

}
