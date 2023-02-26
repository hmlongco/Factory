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

    func testConvenienceFucntions() throws {
        XCTAssertNotNil(Container.shared.cachedCoverage())
        XCTAssertNotNil(Container.shared.graphCoverage())
        XCTAssertNotNil(Container.shared.scopeCoverage())
        XCTAssertNotNil(Container.shared.sharedCoverage())
        XCTAssertNotNil(Container.shared.singletonCoverage())
        XCTAssertNotNil(Container.shared.uniqueCoverage())
//        XCTAssertNotNil(Container.shared.cachedCoverageParameter(1))
//        XCTAssertNotNil(Container.shared.graphCoverageParameter(1))
//        XCTAssertNotNil(Container.shared.scopeCoverageParameter(1))
//        XCTAssertNotNil(Container.shared.sharedCoverageParameter(1))
//        XCTAssertNotNil(Container.shared.singletonCoverageParameter(1))
//        XCTAssertNotNil(Container.shared.uniqueCoverageParameter(1))
    }

}

private extension Container {
    var cachedCoverage: Factory<MyService?> { self { MyService() }.cached }
    var graphCoverage: Factory<MyService?> { self { MyService() }.graph }
    var scopeCoverage: Factory<MyService?> { self { MyService() }.scope(.session) }
    var sharedCoverage: Factory<MyService?> { self { MyService() }.shared }
    var singletonCoverage: Factory<MyService?>  { self { MyService() }.singleton }
    var uniqueCoverage: Factory<MyService?>  { self { MyService() }.unique }
//    var cachedCoverageParameter: ParameterFactory<Int, ParameterService?> { cached { ParameterService(value: $0) }. }
//    var graphCoverageParameter: ParameterFactory<Int, ParameterService?> { graph { ParameterService(value: $0) } }
//    var scopeCoverageParameter: ParameterFactory<Int, ParameterService?> { scope(.session) { ParameterService(value: $0) } }
//    var sharedCoverageParameter: ParameterFactory<Int, ParameterService?> { shared { ParameterService(value: $0) } }
//    var singletonCoverageParameter: ParameterFactory<Int, ParameterService?> { singleton { ParameterService(value: $0) } }
//    var uniqueCoverageParameter: ParameterFactory<Int, ParameterService?>  { self { ParameterService(value: $0) } }
}
