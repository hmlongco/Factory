import XCTest
@testable import Factory

final class FactoryParameterTests: XCTestCase {

    override func setUp() {
        super.setUp()
        Container.Registrations.reset()
        Container.Scope.reset()
    }

    func testParameterServiceResolutions() throws {
        let service1 = Container.parameterService(5)
        XCTAssertTrue(service1.value == 5)
    }

    func testParameterTupleResolutions() throws {
        let service2 = Container.tupleService((1, 2))
        XCTAssertTrue(service2.value == 3)
    }

    func testParameterRegistrationsAndResolutions() throws {
        let service1 = Container.parameterService(5)
        XCTAssertTrue(service1.value == 5)
        XCTAssertTrue(service1.text() == "ParameterService5")
        Container.parameterService.register { n in
            MockServiceN(n)
        }
        let service2 = Container.parameterService(6)
        XCTAssertTrue(service2.text() == "MockService6")
   }

}
