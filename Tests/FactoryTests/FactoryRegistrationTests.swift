import XCTest
@testable import Factory


final class FactoryRegistrationTests: XCTestCase {

    override func setUp() {
        super.setUp()
        Factory.Registrations.reset()
    }

    func testPushPop() throws {
        let service1 = Factory.myServiceType()
        XCTAssertTrue(service1.text() == "MyService")

        Factory.Registrations.push()

        Factory.myServiceType.register(factory: { MockService() })
        let service2 = Factory.myServiceType()
        XCTAssertTrue(service2.text() == "MockService")

        Factory.Registrations.pop()

        let service3 = Factory.myServiceType()
        XCTAssertTrue(service3.text() == "MyService")
    }

    func testReset() throws {
        let service1 = Factory.myServiceType()
        XCTAssertTrue(service1.text() == "MyService")

        Factory.myServiceType.register(factory: { MockService() })
        let service2 = Factory.myServiceType()
        XCTAssertTrue(service2.text() == "MockService")

        Factory.Registrations.reset()

        let service3 = Factory.myServiceType()
        XCTAssertTrue(service3.text() == "MyService")
    }

}
