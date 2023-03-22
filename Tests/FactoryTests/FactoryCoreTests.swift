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

    func testUnsugaredResolution() throws {
        let service1 = Container.shared.myServiceType.resolve()
        XCTAssertEqual(service1.text(), "MyService")
        let service2 = Container.shared.parameterService.resolve(23)
        XCTAssertEqual(service2.text(), "ParameterService23")
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
        let _ = CustomContainer.shared.decorated()
        XCTAssertEqual(CustomContainer.shared.count, 3)
        let _ = CustomContainer.shared.decorated()
        XCTAssertEqual(CustomContainer.shared.count, 4)
    }

    func testFactoryOnce() {
        XCTAssertEqual(CustomContainer.shared.count, 0)
        let service1 = CustomContainer.shared.once()
        XCTAssertEqual(CustomContainer.shared.count, 2)
        let service2 = CustomContainer.shared.once()
        XCTAssertEqual(CustomContainer.shared.count, 3)
        XCTAssertEqual(service1.id, service2.id)
        CustomContainer.shared.once
            .scope(.unique)
            .decorator { _ in }
        let service3 = CustomContainer.shared.once()
        XCTAssertEqual(CustomContainer.shared.count, 3)
        let service4 = CustomContainer.shared.once()
        XCTAssertEqual(CustomContainer.shared.count, 3)
        XCTAssertNotEqual(service3.id, service4.id)
    }

    func testCircularDependencyFailure() {
        let message = "circular dependency chain - FactoryTests.RecursiveA > FactoryTests.RecursiveB > FactoryTests.RecursiveC > FactoryTests.RecursiveA"
        expectFatalError(expectedMessage: message) {
            let _ = Container.shared.recursiveA()
        }
        expectFatalError(expectedMessage: message) {
            let _ = Container.shared.recursiveA()
        }
    }

    func testStrictPromise() {
        // Expect non fatal error when strict and NOT in debug mode
        Container.shared.manager.promiseTriggersError = false
        expectNonFatalError {
            let _ = Container.shared.strictPromisedService()
        }
        // Expect fatal error when strict and in debug mode
        Container.shared.manager.promiseTriggersError = true
        expectFatalError(expectedMessage: "MyServiceType was not registerd") {
            let _ = Container.shared.strictPromisedService()
        }
    }

    func testTrace() {
        var logged: [String] = []
        Container.shared.manager.trace.toggle()
        let _ = Container.shared.optionalService()
        Container.shared.manager.logger = {
            logged.append($0)
        }
        let _ = Container.shared.consumer()
        Container.shared.manager.trace.toggle()
        Container.shared.manager.logger = {
            print($0)
        }
        XCTAssertEqual(logged.count, 5)
        if logged.count == 5 {
            XCTAssert(logged[0].contains("consumer"))
            XCTAssert(logged[1].contains("idProvider"))
            XCTAssert(logged[2].contains("commonProvider"))
            XCTAssert(logged[3].contains("valueProvider"))
            XCTAssert(logged[4].contains("commonProvider"))
        }
    }

}
