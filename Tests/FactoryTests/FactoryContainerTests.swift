import XCTest
@testable import Factory


final class FactoryContainerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        Container.shared = Container()
        CustomContainer.shared = CustomContainer()
    }

    func testDecorators() {
        CustomContainer.count = 0
        let _ = CustomContainer.shared.decorated()
        XCTAssertEqual(CustomContainer.shared.count, 2)
    }

    func testPushPop() throws {
        let service1 = Container.shared.myServiceType()
        XCTAssertTrue(service1.text() == "MyService")

        // add registration and test initial state
        Container.shared.myServiceType.register(factory: { MockServiceN(1) })
        let service2 = Container.shared.myServiceType()
        XCTAssertTrue(service2.text() == "MockService1")

        // push and test changed state
        Container.shared.manager.push()
        Container.shared.myServiceType.register(factory: { MockServiceN(2) })
        let service3 = Container.shared.myServiceType()
        XCTAssertTrue(service3.text() == "MockService2")

        // pop and ensure we're back to initial state
        Container.shared.manager.pop()
        let service4 = Container.shared.myServiceType()
        XCTAssertTrue(service4.text() == "MockService1")

        // pop again (which does nothing) and test for initial state
        Container.shared.manager.pop()
        let service5 = Container.shared.myServiceType()
        XCTAssertTrue(service5.text() == "MockService1")
    }

    func testReset() throws {
        let service1 = Container.shared.myServiceType()
        XCTAssertTrue(service1.text() == "MyService")

        Container.shared.myServiceType.register(factory: { MockService() })
        let service2 = Container.shared.myServiceType()
        XCTAssertTrue(service2.text() == "MockService")

        Container.shared.manager.reset()

        let service3 = Container.shared.myServiceType()
        XCTAssertTrue(service3.text() == "MyService")
    }

}