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
            .preview { ContextService(name: "PREVIEW") }
            .test { ContextService(name: "TEST") }
            .arg("ARG") { ContextService(name: "ARG") }

        // externally defined contexts
        Container.shared.internalContextService
            .register { ContextService(name: "REGISTERED") }
            .preview { ContextService(name: "PREVIEW") }
            .test { ContextService(name: "TEST") }
            .arg("ARG") { ContextService(name: "ARG") }

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

    func testDebugWithNoPreviewNoTest() {
        FactoryContext.isPreview = false
        FactoryContext.isTest = false
        Container.shared.externalContextService
            .debug { ContextService(name: "DEBUG") }
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
            .debug { ContextService(name: "DEBUG") }
    }
}
