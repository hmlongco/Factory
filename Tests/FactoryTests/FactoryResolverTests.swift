import XCTest
import FactoryTesting
@testable import FactoryKit

final class FactoryResolverTests: XCResolvingContainerTestCase {

    func testBasicResolve() throws {
        let container = ResolvingContainer()
        let service1: MyService? = container.resolve()
        let service2: MyService? = container.resolve()
        XCTAssertNotNil(service1)
        XCTAssertNotNil(service2)
        // Unique item ids should not match
        XCTAssertTrue(service1?.id != service2?.id)
    }

    func testResolvingScope() throws {
        let container = ResolvingContainer()
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
        let container = ResolvingContainer()
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

package final class ResolvingContainer: SharedContainer, AutoRegistering, Resolving {
    #if swift(>=5.5)
    @TaskLocal package static var shared = ResolvingContainer()
    #else
    package static let shared = ResolvingContainer()
    #endif
    package func autoRegister() {
        register { MyService() }
    }
    package let manager = ContainerManager()

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

package class XCResolvingContainerTestCase: XCTestCase {
    package var transform: (@Sendable (ResolvingContainer) -> Void)?

    package override func invokeTest() {
        withContainer(
            shared: ResolvingContainer.$shared,
            container: ResolvingContainer(),
            operation: super.invokeTest,
            transform: self.transform
        )
    }
}
