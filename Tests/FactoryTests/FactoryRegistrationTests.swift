import XCTest
@testable import Factory


final class FactoryRegistrationTests: XCTestCase {

    override func setUp() {
        super.setUp()
        Container.Registrations.reset()
        Container.Scope.reset()
    }

    func testPushPop() throws {
        let service1 = Container.myServiceType()
        XCTAssertTrue(service1.text() == "MyService")

        Container.Registrations.push()

        Container.myServiceType.register(factory: { MockService() })
        let service2 = Container.myServiceType()
        XCTAssertTrue(service2.text() == "MockService")

        Container.Registrations.pop()

        let service3 = Container.myServiceType()
        XCTAssertTrue(service3.text() == "MyService")
    }

    func testReset() throws {
        let service1 = Container.myServiceType()
        XCTAssertTrue(service1.text() == "MyService")

        Container.myServiceType.register(factory: { MockService() })
        let service2 = Container.myServiceType()
        XCTAssertTrue(service2.text() == "MockService")

        Container.Registrations.reset()

        let service3 = Container.myServiceType()
        XCTAssertTrue(service3.text() == "MyService")
    }

}
