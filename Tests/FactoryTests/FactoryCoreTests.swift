import XCTest
import FactoryTesting
@testable import FactoryKit

#if canImport(SwiftUI)
import SwiftUI
#endif

final class FactoryCoreTests: XCContainerAndCustomContainerTestCase {

    override func setUp() {
        CustomContainer.shared.count = 0
    }

    func testBasicResolution() throws {
        let service1 = Container.shared.myServiceType()
        XCTAssertTrue(service1.text() == "MyService")
        let service2 = Container.shared.mockService()
        XCTAssertTrue(service2.text() == "MockService")
    }

    func testGlobalResolutionFunctions() throws {
        let service1 = resolve(\.myServiceType)
        XCTAssertEqual(service1.text(), "MyService")
        let service2 = resolve(\CustomContainer.test)
        XCTAssertEqual(service2.text(), "MockService32")
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
        XCTAssertEqual(service2?.text(), "MyService")
    }

    func testPromisedParameterRegistrationAndOptionalResolution() throws {
        let service1: ParameterService? = Container.shared.promisedParameterService(23)
        XCTAssertTrue(service1?.text() == nil)
        Container.shared.promisedParameterService.register { ParameterService(value: $0) }
        let service2: ParameterService? = Container.shared.promisedParameterService(23)
        XCTAssertEqual(service2?.text(), "ParameterService23")
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

        XCTAssertTrue(Container.shared.manager.isEmpty(.registration))
        XCTAssertTrue(Container.shared.manager.isEmpty(.scope))

        registerAndResolve()

        Container.shared.cachedService.reset(.none)

        XCTAssertFalse(Container.shared.manager.isEmpty(.registration))
        XCTAssertFalse(Container.shared.manager.isEmpty(.scope))

        Container.shared.cachedService.reset(.all)

        XCTAssertTrue(Container.shared.manager.isEmpty(.registration))
        XCTAssertTrue(Container.shared.manager.isEmpty(.scope))

        registerAndResolve()

        Container.shared.manager.reset(options: .none)

        XCTAssertFalse(Container.shared.manager.isEmpty(.registration))
        XCTAssertFalse(Container.shared.manager.isEmpty(.scope))

        Container.shared.cachedService.reset(.registration)

        XCTAssertTrue(Container.shared.manager.isEmpty(.registration))
        XCTAssertFalse(Container.shared.manager.isEmpty(.scope))

        registerAndResolve()

        Container.shared.cachedService.reset(.scope)

        XCTAssertFalse(Container.shared.manager.isEmpty(.registration))
        XCTAssertTrue(Container.shared.manager.isEmpty(.scope))

        Container.shared.manager.reset(options: .registration)

        XCTAssertTrue(Container.shared.manager.isEmpty(.registration))
        XCTAssertTrue(Container.shared.manager.isEmpty(.scope))

        registerAndResolve()

        Container.shared.manager.reset(options: .scope)

        XCTAssertFalse(Container.shared.manager.isEmpty(.registration))
        XCTAssertTrue(Container.shared.manager.isEmpty(.scope))

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

    func testFactoryOnceOnTest() {
        print("Test testFactoryOnceOnTest running in \(ProcessInfo.processInfo.processName)")
        guard FactoryContext.current.isTest else {
            print("This test can only run in a known test environment")
            return
        }
        let service1 = CustomContainer.shared.onceOnTest()
        XCTAssertEqual(service1.value, 1)
        CustomContainer.shared.onceOnTest.onTest {
            MockServiceN(2)
        }
        let service2 = CustomContainer.shared.onceOnTest()
        XCTAssertEqual(service2.value, 2)
    }

    @MainActor
    func testCircularDependencyFailure() {
        let message = "FACTORY: Circular dependency chain - FactoryTests.RecursiveA > FactoryTests.RecursiveB > FactoryTests.RecursiveC > FactoryTests.RecursiveA"
        expectFatalError(expectedMessage: message) {
            let _ = Container.shared.recursiveA()
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
        XCTAssertNotNil(Container.shared.manager.logger)
        XCTAssertEqual(logged.count, 5)
        if logged.count == 5 {
            XCTAssert(logged[0].contains("consumer"))
            XCTAssert(logged[1].contains("idProvider"))
            XCTAssert(logged[2].contains("commonProvider"))
            XCTAssert(logged[3].contains("valueProvider"))
            XCTAssert(logged[4].contains("commonProvider"))
        }
    }

#if canImport(SwiftUI)
    func testPreviewFunction() throws {
        let service1 = Container.shared.myServiceType()
        XCTAssertTrue(service1.text() == "MyService")

        Container.shared.myServiceType.preview { MockService() }

        let service2 = Container.shared.myServiceType()
        XCTAssertTrue(service2.text() == "MockService")
    }
#endif

}

// FactoryContext.current is not yet using @TaskLocal therefore we cannot use safely the `XCContainerTestCase` here.
final class FactoryCoreStrictPromiseTests: XCTestCase {

    @MainActor
    func testStrictPromise() {
        // Expect non fatal error when strict and NOT in debug mode
        Container.shared.manager.promiseTriggersError = false
        expectNonFatalError {
            let _ = Container.shared.strictPromisedService()
        }
        // Expect fatal error when strict and in debug mode
        Container.shared.manager.promiseTriggersError = true
        expectFatalError(expectedMessage: "MyServiceType was not registered") {
            let _ = Container.shared.strictPromisedService()
        }
    }

    @MainActor
    func testStrictParameterPromise() {
        // Expect non fatal error when strict and NOT in debug mode
        Container.shared.manager.promiseTriggersError = false
        expectNonFatalError {
            let _ = Container.shared.strictPromisedParameterService(23)
        }
        // Expect fatal error when strict and in debug mode
        Container.shared.manager.promiseTriggersError = true
        expectFatalError(expectedMessage: "ParameterService was not registered") {
            let _ = Container.shared.strictPromisedParameterService(23)
        }
    }

}
