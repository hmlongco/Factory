import XCTest
@testable import Factory

final class FactoryContextTests: XCTestCase {

    var arguments: [String] = []
    var isPreview: Bool = false
    var isTest: Bool = false

    override func setUp() {
        super.setUp()

        // start over
        Container.shared = Container()

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

        // save current arg state
        arguments = FactoryContext.arguments
        isPreview = FactoryContext.isPreview
        isTest = FactoryContext.isTest
    }

    override func tearDown() {
        super.tearDown()
        // restore current arg state
        FactoryContext.arguments = arguments
        FactoryContext.isPreview = isPreview
        FactoryContext.isTest = isTest
    }

    func testDefaultRunningUnitTest() {
        let service1 = Container.shared.externalContextService()
        XCTAssertEqual(service1.name, "TEST")
        let service2 = Container.shared.internalContextService()
        XCTAssertEqual(service2.name, "TEST")
        if FactoryContext.isSimulator {
            let service3 = Container.shared.simulatorContextService()
            XCTAssertEqual(service3.name, "SIMULATOR")
        } else {
            let service3 = Container.shared.simulatorContextService()
            XCTAssertEqual(service3.name, "DEVICE")
        }
    }

    func testNoPreviewNoTest() {
        FactoryContext.isPreview = false
        FactoryContext.isTest = false
        let service1 = Container.shared.externalContextService()
        XCTAssertEqual(service1.name, "REGISTERED")
        let service2 = Container.shared.internalContextService()
        XCTAssertEqual(service2.name, "DEBUG")
    }

    func testWithPreview() {
        FactoryContext.isPreview = true
        FactoryContext.isTest = false
        let service1 = Container.shared.externalContextService()
        XCTAssertEqual(service1.name, "PREVIEW")
        let service2 = Container.shared.internalContextService()
        XCTAssertEqual(service2.name, "PREVIEW")
    }

    func testWithTest() {
        FactoryContext.isPreview = false
        FactoryContext.isTest = true
        let service1 = Container.shared.externalContextService()
        XCTAssertEqual(service1.name, "TEST")
        let service2 = Container.shared.internalContextService()
        XCTAssertEqual(service2.name, "TEST")
    }

    func testWithSimulator() {
        FactoryContext.isPreview = false
        FactoryContext.isTest = false
        FactoryContext.isSimulator = true
        let service1 = Container.shared.simulatorContextService()
        XCTAssertEqual(service1.name, "SIMULATOR")
    }

    func testWithDevice() {
        FactoryContext.isPreview = false
        FactoryContext.isTest = false
        FactoryContext.isSimulator = false
        let service1 = Container.shared.simulatorContextService()
        XCTAssertEqual(service1.name, "DEVICE")
    }

    func testDebugWithNoPreviewNoTest() {
        FactoryContext.isPreview = false
        FactoryContext.isTest = false
        Container.shared.externalContextService
            .onDebug { ContextService(name: "DEBUG") }
        let service1 = Container.shared.externalContextService()
        XCTAssertEqual(service1.name, "DEBUG")
        let service2 = Container.shared.internalContextService()
        XCTAssertEqual(service2.name, "DEBUG")
    }

    func testWithArgument() {
        FactoryContext.isPreview = false
        FactoryContext.isTest = false
        FactoryContext.arguments = ["ARG"]
        let service1 = Container.shared.externalContextService()
        XCTAssertEqual(service1.name, "ARG")
        let service2 = Container.shared.internalContextService()
        XCTAssertEqual(service2.name, "ARG")
    }

    func testUnmatchedArgument() {
        FactoryContext.arguments = ["ARG2"]
        FactoryContext.isPreview = false
        FactoryContext.isTest = false
        let service1 = Container.shared.externalContextService()
        XCTAssertEqual(service1.name, "REGISTERED")
        let service2 = Container.shared.internalContextService()
        XCTAssertEqual(service2.name, "DEBUG")
    }

    func testResettingContext1() {
        FactoryContext.arguments = ["ARG"]
        FactoryContext.isPreview = true
        FactoryContext.isTest = true
        Container.shared.externalContextService.reset(.context)
        let service1 = Container.shared.externalContextService()
        // contexts cleared, registration visible
        XCTAssertEqual(service1.name, "REGISTERED")
        let service2 = Container.shared.internalContextService()
        // has no effect on service2
        XCTAssertEqual(service2.name, "ARG")
    }

    func testResettingContext2() {
        FactoryContext.arguments = ["ARG"]
        FactoryContext.isPreview = true
        FactoryContext.isTest = true
        Container.shared.internalContextService.reset(.context)
        let service1 = Container.shared.externalContextService()
        // no effect on service1
        XCTAssertEqual(service1.name, "ARG")
        let service2 = Container.shared.internalContextService()
        // unable to clear internally defined context
        XCTAssertEqual(service2.name, "DEBUG")
    }

    func testResettingContainer() {
        FactoryContext.arguments = ["ARG"]
        FactoryContext.isPreview = true
        FactoryContext.isTest = true
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
        FactoryContext.arguments = ["ARG"]
        FactoryContext.isPreview = true
        FactoryContext.isTest = true
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
        FactoryContext.arguments = ["ARG"]
        FactoryContext.isPreview = true
        FactoryContext.isTest = true
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
        FactoryContext.arguments = []
        FactoryContext.isPreview = true
        FactoryContext.isTest = true
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
        self {
            ContextService(name: "FACTORY")
        }
        .onDebug {
            ContextService(name: "ONCE")
        }
        .once()
    }

}
