import XCTest
@testable import Factory

final class FactoryCoreTests: XCTestCase {

    override func setUp() {
        super.setUp()
        Factory.Registrations.reset()
    }

    func testBasicResolution() throws {
        let service1 = Factory.myServiceType()
        XCTAssertTrue(service1.text() == "MyService")
        let service2 = Factory.mockService()
        XCTAssertTrue(service2.text() == "MockService")
    }

    func testBasicResolutionOverride() throws {
        let service1 = Factory.myServiceType()
        XCTAssertTrue(service1.text() == "MyService")
        Factory.myServiceType.register(factory: { MockService() })
        let service2 = Factory.myServiceType()
        XCTAssertTrue(service2.text() == "MockService")
    }

    func testBasicResolutionOverrideReset() throws {
        Factory.myServiceType.register { MockService() }
        let service1 = Factory.myServiceType()
        XCTAssertTrue(service1.text() == "MockService")
        Factory.myServiceType.reset()
        let service2 = Factory.myServiceType()
        XCTAssertTrue(service2.text() == "MyService")
    }

    func testOptionalResolution() throws {
        let service1: MyServiceType? = Factory.optionalService()
        XCTAssertTrue(service1?.text() == "MyService")
        Factory.optionalService.register { nil }
        let service2: MyServiceType? = Factory.optionalService()
        Factory.optionalService.register { MockService() }
        XCTAssertNil(service2)
        let service3: MyServiceType? = Factory.optionalService()
        XCTAssertTrue(service3?.text() == "MockService")
    }

}
