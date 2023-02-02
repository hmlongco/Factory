import XCTest
@testable import Factory

final class FactoryCoreTests: XCTestCase {

    override func setUp() {
        super.setUp()
        Container.shared = Container()
        CustomContainer.shared = CustomContainer()
    }

    func testBasicResolution() throws {
        let service1 = Container.shared.myServiceType()
        XCTAssertTrue(service1.text() == "MyService")
        let service2 = Container.shared.mockService()
        XCTAssertTrue(service2.text() == "MockService")
    }

    func testBasicStaticResolution() throws {
        let service1 = Container.myServiceType()
        XCTAssertTrue(service1.text() == "MyService")
    }

    func testBasicResolutionOverride() throws {
        let service1 = Container.shared.myServiceType()
        XCTAssertTrue(service1.text() == "MyService")
        Container.shared.myServiceType.register(factory: { MockService() })
        let service2 = Container.shared.myServiceType()
        XCTAssertTrue(service2.text() == "MockService")
    }

    func testBasicResolutionOverrideReset() throws {
        Container.shared.myServiceType.register { MockService() }
        let service1 = Container.shared.myServiceType()
        XCTAssertTrue(service1.text() == "MockService")
        Container.shared.myServiceType.reset()
        let service2 = Container.shared.myServiceType()
        XCTAssertTrue(service2.text() == "MyService")
    }

    func testOptionalResolution() throws {
        let service1: MyServiceType? = Container.shared.optionalService()
        XCTAssertTrue(service1?.text() == "MyService")
        Container.shared.optionalService.register { nil }
        let service2: MyServiceType? = Container.shared.optionalService()
        XCTAssertNil(service2)
        Container.shared.optionalService.register { MockService() }
        let service3: MyServiceType? = Container.shared.optionalService()
        XCTAssertTrue(service3?.text() == "MockService")
    }

    func testExplicitlyUnrwappedOptionalResolution() throws {
        Container.shared.optionalService.register { MyService() }
        let service1: MyServiceType = Container.shared.optionalService()!
        XCTAssertTrue(service1.text() == "MyService")
    }

    func testPromisedRegistrationAndOptionalResolution() throws {
        let service1: MyServiceType? = Container.shared.promisedService()
        XCTAssertTrue(service1?.text() == nil)
        Container.shared.promisedService.register { MyService() }
        let service2: MyServiceType? = Container.shared.promisedService()
        XCTAssertTrue(service2?.text() == "MyService")
    }

    func testResetOptions() {
        func registerAndResolve() {
            // Sneak in code coverage on with as well
            Container.shared.with {
                $0.cachedService.register {
                    MyService()
                }
            }
            let _ = Container.shared.cachedService()
        }

        XCTAssertTrue(Container.shared.manager.registrations.isEmpty)
        XCTAssertTrue(Container.shared.manager.cache.isEmpty)

        registerAndResolve()

        Container.shared.cachedService.reset(.none)

        XCTAssertFalse(Container.shared.manager.registrations.isEmpty)
        XCTAssertFalse(Container.shared.manager.cache.isEmpty)

        Container.shared.cachedService.reset(.all)

        XCTAssertTrue(Container.shared.manager.registrations.isEmpty)
        XCTAssertTrue(Container.shared.manager.cache.isEmpty)

        registerAndResolve()

        Container.shared.manager.reset(options: .none)

        XCTAssertFalse(Container.shared.manager.registrations.isEmpty)
        XCTAssertFalse(Container.shared.manager.cache.isEmpty)

        Container.shared.cachedService.reset(.registration)

        XCTAssertTrue(Container.shared.manager.registrations.isEmpty)
        XCTAssertFalse(Container.shared.manager.cache.isEmpty)

        registerAndResolve()

        Container.shared.cachedService.reset(.scope)

        XCTAssertFalse(Container.shared.manager.registrations.isEmpty)
        XCTAssertTrue(Container.shared.manager.cache.isEmpty)

        Container.shared.manager.reset(options: .registration)

        XCTAssertTrue(Container.shared.manager.registrations.isEmpty)
        XCTAssertTrue(Container.shared.manager.cache.isEmpty)

        registerAndResolve()

        Container.shared.manager.reset(options: .scope)

        XCTAssertFalse(Container.shared.manager.registrations.isEmpty)
        XCTAssertTrue(Container.shared.manager.cache.isEmpty)

    }

    func testFactoryDecorators() {
        XCTAssertEqual(CustomContainer.shared.count, 0)
        let _ = CustomContainer.shared.decorated()
        XCTAssertEqual(CustomContainer.shared.count, 2)
    }

    func testCircularDependencyFailure() {
        expectFatalError(expectedMessage: "circular dependency chain - FactoryTests.RecursiveA > FactoryTests.RecursiveB > FactoryTests.RecursiveC > FactoryTests.RecursiveA") {
            let _ = Container.shared.recursiveA()
        }
    }

}
