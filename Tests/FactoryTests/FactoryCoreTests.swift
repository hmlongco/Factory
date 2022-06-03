import XCTest
@testable import Factory

final class FactoryCoreTests: XCTestCase {

    override func setUp() {
        super.setUp()
        Container.Registrations.reset()
    }

    func testBasicResolution() throws {
        let service1 = Container.myServiceType()
        XCTAssertTrue(service1.text() == "MyService")
        let service2 = Container.mockService()
        XCTAssertTrue(service2.text() == "MockService")
    }

    func testBasicResolutionOverride() throws {
        let service1 = Container.myServiceType()
        XCTAssertTrue(service1.text() == "MyService")
        Container.myServiceType.register(factory: { MockService() })
        let service2 = Container.myServiceType()
        XCTAssertTrue(service2.text() == "MockService")
    }

    func testBasicResolutionOverrideReset() throws {
        Container.myServiceType.register { MockService() }
        let service1 = Container.myServiceType()
        XCTAssertTrue(service1.text() == "MockService")
        Container.myServiceType.reset()
        let service2 = Container.myServiceType()
        XCTAssertTrue(service2.text() == "MyService")
    }

    func testOptionalResolution() throws {
        let service1: MyServiceType? = Container.optionalService()
        XCTAssertTrue(service1?.text() == "MyService")
        Container.optionalService.register { nil }
        let service2: MyServiceType? = Container.optionalService()
        Container.optionalService.register { MockService() }
        XCTAssertNil(service2)
        let service3: MyServiceType? = Container.optionalService()
        XCTAssertTrue(service3?.text() == "MockService")
    }

}
