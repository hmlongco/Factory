import XCTest
@testable import Factory

final class FactoryContextTests: XCTestCase {

    override func setUp() {
        super.setUp()

        // start over
        Container.shared.reset()

        // externally defined contexts
        Container.shared.externalContextService
            .register { ContextService(name: "REGISTERED") }
            .onPreview { ContextService(name: "PREVIEW") }
            .onTest { ContextService(name: "TEST") }
            .onArg("ARG") { ContextService(name: "ARG") }

        // externally defined contexts
        Container.shared.internalContextService
            .register { ContextService(name: "REGISTERED") }
            .onPreview { ContextService(name: "PREVIEW") }
            .onTest { ContextService(name: "TEST") }
            .onArg("ARG") { ContextService(name: "ARG") }

        // externally defined device contexts
        Container.shared.simulatorContextService
            .onDevice { ContextService(name: "DEVICE") }
            .onSimulator { ContextService(name: "SIMULATOR") }

        // define arg contexts
        Container.shared.argsContextService
            .onArgs(["ARG1","ARG2"]) { ContextService(name: "ARG") }
    }

    override func tearDown() {
        super.tearDown()
        // restore current arg state
        FactoryContext.current = FactoryContext()
    }

  #if os(macOS)
  // on linux the detection of test or siumator fails, so skipping seams logical until there is an alternative.
    func testDefaultRunningUnitTest() {
        let service1 = Container.shared.externalContextService()
        XCTAssertEqual(service1.name, "TEST")
        let service2 = Container.shared.internalContextService()
        XCTAssertEqual(service2.name, "TEST")
        if FactoryContext.current.isSimulator {
            let service3 = Container.shared.simulatorContextService()
            XCTAssertEqual(service3.name, "SIMULATOR")
        } else {
            let service3 = Container.shared.simulatorContextService()
            XCTAssertEqual(service3.name, "DEVICE")
        }
        let service4 = Container.shared.argsContextService()
        XCTAssertEqual(service4.name, "FACTORY")
    }
  #endif
  
    func testNoPreviewNoTest() {
        FactoryContext.current.isPreview = false
        FactoryContext.current.isTest = false
        let service1 = Container.shared.externalContextService()
        XCTAssertEqual(service1.name, "REGISTERED")
        let service2 = Container.shared.internalContextService()
        XCTAssertEqual(service2.name, "DEBUG")
        let service3 = Container.shared.argsContextService()
        XCTAssertEqual(service3.name, "FACTORY")
    }

    func testWithPreview() {
        FactoryContext.current.isPreview = true
        FactoryContext.current.isTest = false
        let service1 = Container.shared.externalContextService()
        XCTAssertEqual(service1.name, "PREVIEW")
        let service2 = Container.shared.internalContextService()
        XCTAssertEqual(service2.name, "PREVIEW")
        let service3 = Container.shared.argsContextService()
        XCTAssertEqual(service3.name, "FACTORY")
    }

    func testWithTest() {
        FactoryContext.current.isPreview = false
        FactoryContext.current.isTest = true
        let service1 = Container.shared.externalContextService()
        XCTAssertEqual(service1.name, "TEST")
        let service2 = Container.shared.internalContextService()
        XCTAssertEqual(service2.name, "TEST")
        let service3 = Container.shared.argsContextService()
        XCTAssertEqual(service3.name, "FACTORY")
    }

    func testWithSimulator() {
        FactoryContext.current.isPreview = false
        FactoryContext.current.isTest = false
        FactoryContext.current.isSimulator = true
        let service1 = Container.shared.simulatorContextService()
        XCTAssertEqual(service1.name, "SIMULATOR")
        let service3 = Container.shared.argsContextService()
        XCTAssertEqual(service3.name, "FACTORY")
    }

    func testWithDevice() {
        FactoryContext.current.isPreview = false
        FactoryContext.current.isTest = false
        FactoryContext.current.isSimulator = false
        let service1 = Container.shared.simulatorContextService()
        XCTAssertEqual(service1.name, "DEVICE")
        let service3 = Container.shared.argsContextService()
        XCTAssertEqual(service3.name, "FACTORY")
    }

    func testDebugWithNoPreviewNoTest() {
        FactoryContext.current.isPreview = false
        FactoryContext.current.isTest = false
        Container.shared.externalContextService
            .onDebug { ContextService(name: "DEBUG") }
        let service1 = Container.shared.externalContextService()
        XCTAssertEqual(service1.name, "DEBUG")
        let service2 = Container.shared.internalContextService()
        XCTAssertEqual(service2.name, "DEBUG")
        let service3 = Container.shared.argsContextService()
        XCTAssertEqual(service3.name, "FACTORY")
    }

    func testWithArgument() {
        FactoryContext.current.isPreview = false
        FactoryContext.current.isTest = false
        FactoryContext.current.arguments = ["ARG"]
        let service1 = Container.shared.externalContextService()
        XCTAssertEqual(service1.name, "ARG")
        let service2 = Container.shared.internalContextService()
        XCTAssertEqual(service2.name, "ARG")
        let service3 = Container.shared.argsContextService()
        XCTAssertEqual(service3.name, "FACTORY")
    }

    func testWithArguments() {
        FactoryContext.current.isPreview = false
        FactoryContext.current.isTest = false
        FactoryContext.current.arguments = ["ARG2"]
        let service1 = Container.shared.externalContextService()
        XCTAssertEqual(service1.name, "REGISTERED")
        let service2 = Container.shared.internalContextService()
        XCTAssertEqual(service2.name, "DEBUG")
        let service3 = Container.shared.argsContextService()
        XCTAssertEqual(service3.name, "ARG")
    }

    func testRuntimeArgFunctions() {
        FactoryContext.current.isPreview = false
        FactoryContext.current.isTest = false
        FactoryContext.setArg("ARG2", forKey: "CUSTOM")
        let service1 = Container.shared.argsContextService()
        XCTAssertEqual(service1.name, "ARG")
        FactoryContext.removeArg(forKey: "CUSTOM")
        let service2 = Container.shared.argsContextService()
        XCTAssertEqual(service2.name, "FACTORY")
    }

    func testUnmatchedArgument() {
        FactoryContext.current.arguments = ["ARG3"]
        FactoryContext.current.isPreview = false
        FactoryContext.current.isTest = false
        let service1 = Container.shared.externalContextService()
        XCTAssertEqual(service1.name, "REGISTERED")
        let service2 = Container.shared.internalContextService()
        XCTAssertEqual(service2.name, "DEBUG")
        let service3 = Container.shared.argsContextService()
        XCTAssertEqual(service3.name, "FACTORY")
    }

    func testResettingContext1() {
        FactoryContext.current.arguments = ["ARG"]
        FactoryContext.current.isPreview = true
        FactoryContext.current.isTest = true
        Container.shared.externalContextService.reset(.context)
        let service1 = Container.shared.externalContextService()
        // contexts cleared, registration visible
        XCTAssertEqual(service1.name, "REGISTERED")
        let service2 = Container.shared.internalContextService()
        // has no effect on service2
        XCTAssertEqual(service2.name, "ARG")
        // has no effect on service3
        let service3 = Container.shared.argsContextService()
        XCTAssertEqual(service3.name, "FACTORY")
    }

    func testResettingContext2() {
        FactoryContext.current.arguments = ["ARG"]
        FactoryContext.current.isPreview = true
        FactoryContext.current.isTest = true
        Container.shared.internalContextService.reset(.context)
        let service1 = Container.shared.externalContextService()
        // no effect on service1
        XCTAssertEqual(service1.name, "ARG")
        let service2 = Container.shared.internalContextService()
        // unable to clear internally defined context
        XCTAssertEqual(service2.name, "DEBUG")
        // has no effect on service3
        let service3 = Container.shared.argsContextService()
        XCTAssertEqual(service3.name, "FACTORY")
    }

    func testResettingContainer() {
        FactoryContext.current.arguments = ["ARG"]
        FactoryContext.current.isPreview = true
        FactoryContext.current.isTest = true
        // reset container registrations and contexts
        Container.shared.manager.reset()
        let service1 = Container.shared.externalContextService()
        // will see factory
        XCTAssertEqual(service1.name, "FACTORY")
        let service2 = Container.shared.internalContextService()
        // unable to clear internally defined context
        XCTAssertEqual(service2.name, "DEBUG")
    }

    func testResettingContainerRegistrations() {
        FactoryContext.current.arguments = ["ARG"]
        FactoryContext.current.isPreview = true
        FactoryContext.current.isTest = true
        // reset container registrations and contexts
        Container.shared.manager.reset(options: .registration)
        let service1 = Container.shared.externalContextService()
        // will see preivew
        XCTAssertEqual(service1.name, "ARG")
        let service2 = Container.shared.internalContextService()
        // will see preivew
        XCTAssertEqual(service2.name, "ARG")
    }

    func testResettingContainerContexts() {
        FactoryContext.current.arguments = ["ARG"]
        FactoryContext.current.isPreview = true
        FactoryContext.current.isTest = true
        // reset container contexts
        Container.shared.manager.reset(options: .context)
        let service1 = Container.shared.externalContextService()
        // will see registered
        XCTAssertEqual(service1.name, "REGISTERED")
        let service2 = Container.shared.internalContextService()
        // unable to clear internally defined context
        XCTAssertEqual(service2.name, "DEBUG")
    }

    func testResettingContainerContextsWithOnce() {
        FactoryContext.current.arguments = []
        FactoryContext.current.isPreview = true
        FactoryContext.current.isTest = true
        // reset container contexts
        let service1 = Container.shared.onceContextService()
        // will see once
        XCTAssertEqual(service1.name, "ONCE")
        // update
        Container.shared.onceContextService.onDebug {
            ContextService(name: "DEBUG")
        }
        let service2 = Container.shared.onceContextService()
        // will see new context
        XCTAssertEqual(service2.name, "DEBUG")
        Container.shared.onceContextService.reset(.context)
        let service3 = Container.shared.onceContextService()
        // will see factory
        XCTAssertEqual(service3.name, "FACTORY")
        // hard reset
        Container.shared.manager.reset()
        let service4 = Container.shared.onceContextService()
        // will see once
        XCTAssertEqual(service4.name, "ONCE")
    }

    func testChaining() {
        FactoryContext.current.arguments = []
        FactoryContext.current.isPreview = false
        FactoryContext.current.isTest = false
        let service1 = Container.shared.internalContextService()
        XCTAssertEqual(service1.name, "DEBUG")
        let service2 = Container.shared.internalContextService
            .onDebug { ContextService(name: "CHANGED") }
            .resolve()
        XCTAssertEqual(service2.name, "CHANGED")
    }

}

struct ContextService {
    var name: String
}

extension Container {
    fileprivate var externalContextService: Factory<ContextService> {
        self { ContextService(name: "FACTORY") }
    }
    fileprivate var internalContextService: Factory<ContextService> {
        self { ContextService(name: "FACTORY") }
            .onDebug { ContextService(name: "DEBUG") }
    }
    fileprivate var simulatorContextService: Factory<ContextService> {
        self { ContextService(name: "FACTORY") }
    }
    fileprivate var onceContextService: Factory<ContextService> {
        self { ContextService(name: "FACTORY") }
            .onDebug { ContextService(name: "ONCE") }
            .once()
    }
    fileprivate var argsContextService: Factory<ContextService> {
        self { ContextService(name: "FACTORY") }
    }
}
