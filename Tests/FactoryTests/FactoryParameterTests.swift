import XCTest
@testable import Factory

final class FactoryParameterTests: XCTestCase {

    override func setUp() {
        super.setUp()
        Container.shared = Container()
    }

    func testParameterServiceResolutions() throws {
        let service1 = Container.shared.parameterService(5)
        XCTAssertEqual(service1.value, 5)
    }

    func testParameterRegistrationsAndResolutions() throws {
        let service1 = Container.shared.parameterService(5)
        XCTAssertTrue(service1.value == 5)
        XCTAssertTrue(service1.text() == "ParameterService5")
        Container.shared.parameterService.register { n in
            ParameterService(value: n)
        }
        let service2 = Container.shared.parameterService(6)
        XCTAssertTrue(service2.text() == "ParameterService6")
   }

    func testScopedParameterServiceResolutions() throws {
        let service1 = Container.shared.scopedParameterService(6)
        XCTAssertTrue(service1.value == 6)
    }

    func testScopedParameterServiceReset() throws {
        XCTAssertTrue(Container.shared.manager.cache.isEmpty)
        let service1 = Container.shared.scopedParameterService(6)
        XCTAssertTrue(service1.value == 6)
        XCTAssertFalse(Container.shared.manager.cache.isEmpty)
        Container.shared.scopedParameterService.reset()
        XCTAssertTrue(Container.shared.manager.cache.isEmpty)
    }

}
