import XCTest
@testable import FactoryKit

#if canImport(SwiftUI)
import SwiftUI
#endif

final class FactoryParameterTests: XCTestCase {

    override func setUp() {
        super.setUp()
        Container.shared.reset()
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
        let service2 = Container.shared.scopedParameterService(7)
        XCTAssertTrue(service2.value == 6) // original
    }

    func testScopeOnParameterServiceResolutions() throws {
        let service1 = Container.shared.scopedOnParameterService(6)
        XCTAssertTrue(service1.value == 6)
        let service2 = Container.shared.scopedOnParameterService(7)
        XCTAssertTrue(service2.value == 7)
        let service3 = Container.shared.scopedOnParameterService(6)
        XCTAssertTrue(service3.value == 6)
        XCTAssertTrue(service1.id == service3.id)
        XCTAssertTrue(service2.id != service3.id)
        let service4 = Container.shared.scopedOnParameterService(7)
        XCTAssertTrue(service4.value == 7)
        XCTAssertTrue(service2.id == service4.id)
        XCTAssertTrue(service3.id != service4.id)
        XCTAssertFalse(Container.shared.manager.isEmpty(.scope))
        Container.shared.scopedOnParameterService.reset()
        XCTAssertTrue(Container.shared.manager.isEmpty(.scope))
    }

    func testScopedParameterServiceReset() throws {
        XCTAssertTrue(Container.shared.manager.isEmpty(.scope))
        let service1 = Container.shared.scopedParameterService(6)
        XCTAssertTrue(service1.value == 6)
        XCTAssertFalse(Container.shared.manager.isEmpty(.scope))
        Container.shared.scopedParameterService.reset()
        XCTAssertTrue(Container.shared.manager.isEmpty(.scope))
    }

    func testScopeOnParametersDistinguishesHashCollisions() {
        let container = Container()
        let factory = ParameterFactory<CollidingParameter, ParameterService>(container) {
            ParameterService(value: $0.value)
        }.scopeOnParameters.cached
        let first = CollidingParameter(value: 1)
        let second = CollidingParameter(value: 2)

        XCTAssertNotEqual(first, second)
        XCTAssertEqual(first.hashValue, second.hashValue)

        let service1 = factory(first)
        let service2 = factory(second)
        XCTAssertEqual(service1.value, 1)
        XCTAssertEqual(service2.value, 2)
        XCTAssertFalse(service1 === service2)
        XCTAssertTrue(factory(CollidingParameter(value: 1)) === service1)
        XCTAssertTrue(factory(CollidingParameter(value: 2)) === service2)

        factory.reset(.scope)
        XCTAssertFalse(factory(first) === service1)
        XCTAssertFalse(factory(second) === service2)
        XCTAssertEqual(factory(first).value, 1)
        XCTAssertEqual(factory(second).value, 2)
    }

    func testRegistrationInvalidatesAllCollidingParameters() {
        let container = Container()
        let factory = ParameterFactory<CollidingParameter, ParameterService>(container) {
            ParameterService(value: $0.value)
        }.scopeOnParameters.cached
        let first = CollidingParameter(value: 1)
        let second = CollidingParameter(value: 2)
        let service1 = factory(first)
        let service2 = factory(second)

        factory.register { ParameterService(value: $0.value + 10) }

        XCTAssertEqual(factory(first).value, 11)
        XCTAssertEqual(factory(second).value, 12)
        XCTAssertFalse(factory(first) === service1)
        XCTAssertFalse(factory(second) === service2)
    }

#if canImport(SwiftUI)
    func testPreviewFunction() throws {
        let service1 = Container.shared.parameterService(5)
        XCTAssertTrue(service1.value == 5)
        XCTAssertTrue(service1.text() == "ParameterService5")
        Container.shared.parameterService.preview { n in
            ParameterService(value: n)
        }
        let service2 = Container.shared.parameterService(6)
        XCTAssertTrue(service2.text() == "ParameterService6")
    }
#endif

}

private struct CollidingParameter: Hashable {
    let value: Int

    func hash(into hasher: inout Hasher) {
        hasher.combine(0)
    }
}
