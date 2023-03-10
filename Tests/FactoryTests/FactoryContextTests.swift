import XCTest
@testable import Factory

final class FactoryContextTests: XCTestCase {

    var arguments: [String] = []
    var isPreview: Bool = false
    var isTest: Bool = false

    override func setUp() {
        super.setUp()
        Container.shared = Container()
        Container.shared.contextService.register {
            ContextService(name: "REGISTERED")
        }
        arguments = FactoryContext.arguments
        isPreview = FactoryContext.isPreview
        isTest = FactoryContext.isTest
    }

    override func tearDown() {
        super.tearDown()
        FactoryContext.arguments = arguments
        FactoryContext.isPreview = isPreview
        FactoryContext.isTest = isTest
    }

    func testDefaultRunningUnitTest() {
        let service = Container.shared.contextService()
        XCTAssertEqual(service.name, "TEST")
    }

    func testRegistered() {
        FactoryContext.isPreview = false
        FactoryContext.isTest = false
        let service = Container.shared.contextService()
        XCTAssertEqual(service.name, "REGISTERED")
    }

    func testRunningPreview() {
        FactoryContext.isPreview = true
        FactoryContext.isTest = false
        let service = Container.shared.contextService()
        XCTAssertEqual(service.name, "PREVIEW")
    }

    func testRunningTest() {
        FactoryContext.isPreview = false
        FactoryContext.isTest = true
        let service = Container.shared.contextService()
        XCTAssertEqual(service.name, "TEST")
    }

    func testRunningDebug() {
        FactoryContext.isPreview = false
        FactoryContext.isTest = false
        Container.shared.contextService.debug {
            ContextService(name: "DEBUG")
        }
        let service = Container.shared.contextService()
        XCTAssertEqual(service.name, "DEBUG")
    }

    func testWithArgument() {
        FactoryContext.arguments = ["ARG"]
        let service = Container.shared.contextService()
        XCTAssertEqual(service.name, "ARG")
    }

    func testUnmatchedArgument() {
        FactoryContext.arguments = ["UNMATCHED"]
        FactoryContext.isPreview = false
        FactoryContext.isTest = false
        let service = Container.shared.contextService()
        XCTAssertEqual(service.name, "REGISTERED")
    }

}

struct ContextService {
    var name: String
}

extension Container {
    fileprivate var contextService: Factory<ContextService> {
        self { ContextService(name: "FACTORY") }
            .preview { ContextService(name: "PREVIEW") }
            .test { ContextService(name: "TEST") }
            .arg("ARG") { ContextService(name: "ARG") }
    }
}
