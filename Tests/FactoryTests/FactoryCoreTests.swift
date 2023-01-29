import XCTest
@testable import Factory

final class FactoryCoreTests: XCTestCase {

    override func setUp() {
        super.setUp()
        Container.Registrations.reset()
        Container.Scope.reset()
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
        XCTAssertNil(service2)
        Container.optionalService.register { MockService() }
        let service3: MyServiceType? = Container.optionalService()
        XCTAssertTrue(service3?.text() == "MockService")
    }

    func testExplicitlyUnrwappedOptionalResolution() throws {
        Container.optionalService.register { MyService() }
        let service1: MyServiceType = Container.optionalService()!
        XCTAssertTrue(service1.text() == "MyService")
    }

    func testPromisedRegistrationAndOptionalResolution() throws {
        let service1: MyServiceType? = Container.promisedService()
        XCTAssertTrue(service1?.text() == nil)
        Container.promisedService.register { MyService() }
        let service2: MyServiceType? = Container.promisedService()
        XCTAssertTrue(service2?.text() == "MyService")
    }

    func testResetOptions() {
        func registerAndResolve() {
            Container.cachedService.register {
                MyService()
            }
            let _ = Container.cachedService()
        }

        XCTAssertTrue(Container.Registrations.isEmpty)
        XCTAssertTrue(Container.Scope.cached.isEmpty)

        registerAndResolve()

        Container.cachedService.reset(.none)

        XCTAssertFalse(Container.Registrations.isEmpty)
        XCTAssertFalse(Container.Scope.cached.isEmpty)

        Container.cachedService.reset(.all)

        XCTAssertTrue(Container.Registrations.isEmpty)
        XCTAssertTrue(Container.Scope.cached.isEmpty)

        registerAndResolve()

        Container.cachedService.reset(.registration)

        XCTAssertTrue(Container.Registrations.isEmpty)
        XCTAssertFalse(Container.Scope.cached.isEmpty)

        registerAndResolve()

        Container.cachedService.reset(.scope)

        XCTAssertFalse(Container.Registrations.isEmpty)
        XCTAssertTrue(Container.Scope.cached.isEmpty)

    }

    func testCircularDependencyFailure() {
        let chain = "FactoryTests.RecursiveA > FactoryTests.RecursiveB > FactoryTests.RecursiveC > FactoryTests.RecursiveA"
        expectFatalError(expectedMessage: "circular dependency chain - \(chain)") {
            let _ = Container.recursiveA()
        }
    }

}
