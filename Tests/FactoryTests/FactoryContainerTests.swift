import XCTest
@testable import FactoryKit

#if canImport(SwiftUI)
import SwiftUI
#endif

final class FactoryContainerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        Container.shared.reset()
        CustomContainer.shared.reset()
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

    func testWithFunction() throws {
        let service1 = Container.shared.myServiceType()
        XCTAssertTrue(service1.text() == "MyService")

        Container.shared.with {
            $0.myServiceType.register(factory: { MockService() })
        }

        let service2 = Container.shared.myServiceType()
        XCTAssertTrue(service2.text() == "MockService")
    }

    #if canImport(SwiftUI)
    func testPreviewFunction() throws {
        let service1 = Container.shared.myServiceType()
        XCTAssertTrue(service1.text() == "MyService")

        let _ = Container.preview {
            $0.myServiceType.register(factory: { MockService() })
        }

        let service2 = Container.shared.myServiceType()
        XCTAssertTrue(service2.text() == "MockService")
    }
    #endif

    func testConvenienceFunctions() throws {
        XCTAssertNotNil(Container.shared.cachedCoverage())
        XCTAssertNotNil(Container.shared.graphCoverage())
        XCTAssertNotNil(Container.shared.scopeCoverage())
        XCTAssertNotNil(Container.shared.sharedCoverage())
        XCTAssertNotNil(Container.shared.singletonCoverage())
        XCTAssertNotNil(Container.shared.uniqueCoverage())
    }

    func testIsEmpty() throws {
        XCTAssertTrue(Container.shared.manager.isEmpty(.all))
        XCTAssertTrue(Container.shared.manager.isEmpty(.registration))
        XCTAssertTrue(Container.shared.manager.isEmpty(.scope))
        XCTAssertTrue(Container.shared.manager.isEmpty(.none))
        Container.shared.myServiceType.once() // coverage
        XCTAssertTrue(Container.shared.manager.isEmpty(.context))
    }

}

private extension Container {
    var cachedCoverage: Factory<MyService?> { self { MyService() }.cached }
    var graphCoverage: Factory<MyService?> { self { MyService() }.graph }
    var scopeCoverage: Factory<MyService?> { self { MyService() }.scope(.session) }
    var sharedCoverage: Factory<MyService?> { self { MyService() }.shared }
    var singletonCoverage: Factory<MyService?>  { self { MyService() }.singleton }
    var uniqueCoverage: Factory<MyService?>  { self { MyService() }.unique }
}
