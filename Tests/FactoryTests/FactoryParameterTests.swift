import XCTest
import FactoryTesting
@testable import FactoryKit

#if canImport(SwiftUI)
import SwiftUI
#endif

final class FactoryParameterTests: XCContainerTestCase {

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
