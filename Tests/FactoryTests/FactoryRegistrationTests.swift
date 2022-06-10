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

        // add registrtion and test initial state
        Container.myServiceType.register(factory: { MockServiceN(1) })
        let service2 = Container.myServiceType()
        XCTAssertTrue(service2.text() == "MockService1")

        // push and test changed state
        Container.Registrations.push()
        Container.myServiceType.register(factory: { MockServiceN(2) })
        let service3 = Container.myServiceType()
        XCTAssertTrue(service3.text() == "MockService2")

        // pop and ensure we're back to initial state
        Container.Registrations.pop()
        let service4 = Container.myServiceType()
        XCTAssertTrue(service4.text() == "MockService1")

        // pop again (which does nothing) and test for initial state
        Container.Registrations.pop()
        let service5 = Container.myServiceType()
        XCTAssertTrue(service5.text() == "MockService1")
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
