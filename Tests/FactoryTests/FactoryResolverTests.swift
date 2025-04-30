import XCTest
@testable import Factory

final class FactoryResolverTests: XCTestCase {

    fileprivate var container: ResolvingContainer!

    override func setUp() {
        super.setUp()
        container = ResolvingContainer()
    }

    func testBasicResolve() throws {
        let service1: MyService? = container.resolve()
        let service2: MyService? = container.resolve()
        XCTAssertNotNil(service1)
        XCTAssertNotNil(service2)
        // Unique item ids should not match
        XCTAssertTrue(service1?.id != service2?.id)
    }

    func testResolvingScope() throws {
        let service0: MyServiceType? = container.resolve()
        XCTAssertNil(service0)
        container.register { MyService() as MyServiceType }
            .scope(.singleton)
        let service1: MyServiceType? = container.resolve()
        let service2: MyServiceType? = container.resolve()
        XCTAssertNotNil(service1)
        XCTAssertNotNil(service2)
        // Shared cached item ids should match
        XCTAssertTrue(service1?.id == service2?.id)
    }

    func testFactoryScope() throws {
        container.factory(MyService.self)?
            .scope(.singleton)
        let service1: MyService? = container.resolve()
        let service2: MyService? = container.resolve()
        XCTAssertNotNil(service1)
        XCTAssertNotNil(service2)
        // Item ids should match
        XCTAssertTrue(service1?.id == service2?.id)
    }

}

fileprivate final class ResolvingContainer: SharedContainer, AutoRegistering, Resolving {
    static let shared = ResolvingContainer()
    func autoRegister() {
        register { MyService() }
    }
    let manager = ContainerManager()

    func someService() -> MyServiceType {
        self { MyService() }()
    }

    var myService: MyServiceType { _myService() }
    var _myService: Factory<MyServiceType> { self { MyService() } }

    func resolve<T>(_ path: KeyPath<ResolvingContainer, Factory<T>>) -> T {
        self[keyPath: path]()
    }

    func register<T>(_ path: KeyPath<ResolvingContainer, Factory<T>>, _ factory: @escaping @Sendable () -> T) {
        self[keyPath: path].register(factory: factory)
    }
    
    func test() {
        _ = ResolvingContainer.shared.resolve(\._myService)
    }

}
