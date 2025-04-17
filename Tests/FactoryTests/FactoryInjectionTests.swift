import XCTest

#if canImport(SwiftUI)
import Combine
import Observation
import SwiftUI
#endif

@testable import Factory

class Services1 {
    @Injected(\.myServiceType) var service
    @Injected(\.mockService) var mock
    @Injected(\CustomContainer.test) var test
    init() {}
}

class Services2 {
    @LazyInjected(\.myServiceType) var service
    @LazyInjected(\.mockService) var mock
    @LazyInjected(\CustomContainer.test) var test
    init() {}
}

class Services3 {
    @WeakLazyInjected(\.sharedService) var service
    @WeakLazyInjected(\.mockService) var mock
    @WeakLazyInjected(\CustomContainer.test) var test
    init() {}
}

class Services4 {
    @DynamicInjected(\.myServiceType) var service
    @DynamicInjected(\.mockService) var mock
    @DynamicInjected(\CustomContainer.test) var test
    init() {}
}

class Services5 {
    @Injected(\.optionalService) var service
    init() {}
}

class ServicesP {
    @LazyInjected(\.servicesC) var service
    let name = "Parent"
    init() {}
    func test() -> String? {
        service.name
    }
}

class ServicesC {
    @WeakLazyInjected(\.servicesP) var service: ServicesP?
    @WeakLazyInjected(\CustomContainer.test) var testService
    init() {}
    let name = "Child"
    func test() -> String? {
        service?.name
    }
}

extension Container {
    fileprivate var services1: Factory<Services1> { self { Services1() } }
    fileprivate var services2: Factory<Services2> { self { Services2() } }
    fileprivate var services3: Factory<Services3> { self { Services3() } }
    fileprivate var services4: Factory<Services4> { self { Services4() } }
    fileprivate var servicesP: Factory<ServicesP> { self { ServicesP() }.shared }
    fileprivate var servicesC: Factory<ServicesC> { self { ServicesC() }.shared }
}

protocol ProtocolP: AnyObject {
    var name: String { get }
    func test() -> String?
}

class ProtocolClassP: ProtocolP {
    let child = Container.shared.protocolC()
    let name = "Parent"
    init() {}
    func test() -> String? {
        child.name
    }
}

protocol ProtocolC: AnyObject {
    var parent: ProtocolP? { get set }
    var name: String { get }
    func test() -> String?
}

class ProtocolClassC: ProtocolC {
    weak var parent: ProtocolP?
    init() {}
    let name = "Child"
    func test() -> String? {
        parent?.name
    }
}

extension Container {
    fileprivate var protocolP: Factory<ProtocolP> {
        self {
            let p = ProtocolClassP()
            p.child.parent = p
            return p
        }
        .shared
    }
    fileprivate var protocolC: Factory<ProtocolC> {
        self { ProtocolClassC() }.shared
    }
}

final class FactoryInjectionTests: XCTestCase {

    override func setUp() {
        super.setUp()
        Container.shared.reset()
    }

    func testBasicInjection() throws {
        let services = Services1()
        XCTAssertEqual(services.service.text(), "MyService")
        XCTAssertEqual(services.mock.text(), "MockService")
        XCTAssertEqual(services.test.text(), "MockService32")
    }

    func testLazyInjection() throws {
        let services = Services2()
        XCTAssertNil(services.$service.resolvedOrNil())
        XCTAssertEqual(services.service.text(), "MyService")
        XCTAssertEqual(services.mock.text(), "MockService")
        XCTAssertEqual(services.test.text(), "MockService32")
        XCTAssertNotNil(services.$service.resolvedOrNil())
    }
    
    func testDynamicInjection() throws {
        let services = Services4()
        XCTAssertEqual(services.service.text(), "MyService")
        XCTAssertEqual(services.mock.text(), "MockService")
        XCTAssertEqual(services.test.text(), "MockService32")
    }

    func testLazyInjectionOccursOnce() throws {
        let services = Services2()
        let id1 = services.service.id
        let id2 = services.service.id
        XCTAssertTrue(id1 == id2)
    }

    func testOptionalInjection() throws {
        let services = Services5()
        XCTAssertTrue(services.service?.text() == "MyService")
    }

    func testWeakLazyInjection() throws {
        var parent: ServicesP? = Container.shared.servicesP()
        let child = Container.shared.servicesC()
        let test = CustomContainer.shared.test()
        XCTAssertNil(child.$testService.resolvedOrNil())
        XCTAssertEqual(parent?.test(), "Child")
        XCTAssertEqual(child.test(), "Parent")
        XCTAssertEqual(child.testService?.text(), test.text())
        XCTAssertNotNil(child.$testService.resolvedOrNil())
        parent = nil
        XCTAssertNil(child.test())
    }

    func testWeakLazyInjectionProtocol() throws {
        var parent: ProtocolP? = Container.shared.protocolP()
        let child: ProtocolC? = Container.shared.protocolC()
        XCTAssertTrue(parent?.test() == "Child")
        XCTAssertTrue(child?.test() == "Parent")
        parent = nil
        XCTAssertNil(child?.test())
    }

    func testInjectionSet() throws {
        let service = Container.shared.services1()
        let oldId = service.service.id
        let newService = MyService()
        let newId = newService.id
        service.service = newService
        XCTAssertTrue(service.service.id != oldId)
        XCTAssertTrue(service.service.id == newId)
    }

    func testLazyInjectionSet() throws {
        let service = Container.shared.services2()
        let oldId = service.service.id
        let newService = MyService()
        let newId = newService.id
        service.service = newService
        XCTAssertTrue(service.service.id != oldId)
        XCTAssertTrue(service.service.id == newId)
    }

    func testWeakLazyInjectionSet() throws {
        let strongReference: MyServiceType? = Container.shared.sharedService()
        XCTAssertNotNil(strongReference)
        let service = Container.shared.services3()
        let oldId = service.service?.id
        let newService = MyService()
        let newId = newService.id
        service.service = newService
        XCTAssertTrue(service.service?.id != oldId)
        XCTAssertTrue(service.service?.id == newId)
    }

    func testInjectionResolve() throws {
        let object = Container.shared.services1()
        let oldId = object.service.id
        // force resolution
        object.$service.resolve()
        // should have new instance
        let newId = object.service.id
        XCTAssertTrue(oldId != newId)
    }

    func testLazyInjectionResolve() throws {
        let object = Container.shared.services2()
        let oldId = object.service.id
        // force resolution
        object.$service.resolve()
        // should have new instance
        let newId = object.service.id
        XCTAssertTrue(oldId != newId)
    }

    func testWeakLazyInjectionResolve() throws {
        var strongReference: MyServiceType? = Container.shared.sharedService()
        XCTAssertNotNil(strongReference)
        let oldId = strongReference?.id

        let service = Container.shared.services3()
        let newID = service.service?.id
        XCTAssertTrue(oldId == newID)

        service.service = nil

        service.$service.resolve()
        XCTAssertNotNil(service.service)
        XCTAssertTrue(service.service?.id == newID)

        strongReference = nil
        XCTAssertNil(service.service)

        service.$service.resolve()

        XCTAssertNil(service.service)
    }
    
    func testDynamicInjectionResolve() throws {
        let object = Container.shared.services4()
        let oldId = object.service.id
        // should have new instance
        let newId = object.service.id
        XCTAssertTrue(oldId != newId)
        let newId2 = object.$service.resolve().id
        XCTAssertTrue(newId2 != newId)
    }

    #if canImport(SwiftUI)
    @available(iOS 14, *)
    func testInjectedType() throws {
        let vm1 = ResolvingViewModel()
        XCTAssertNil(vm1.service1)
        XCTAssertNil(vm1.service2)
        Container.shared.register {
            MyService()
        }
        let vm2 = ResolvingViewModel()
        XCTAssertNotNil(vm2.service1)
        XCTAssertNotNil(vm2.service2)
        vm2.service1 = nil
        XCTAssertNil(vm2.service1)
    }

    @available(iOS 14, *)
    @MainActor
    func testInjectedObject() throws {
        // Test initializer for default container
        let i1 = InjectedObject(\.contentViewModel)
        let cvm1 = i1.wrappedValue
        XCTAssertEqual(cvm1.text, "Test")
        // Test initializer for custom container
        let i2 = InjectedObject(\CustomContainer.contentViewModel)
        let cvm2 = i2.wrappedValue
        XCTAssertEqual(cvm2.text, "Test")
        // Test initializer for passed parameter
        let i3 = InjectedObject(ContentViewModel())
        let cvm3 = i3.wrappedValue
        XCTAssertEqual(cvm3.text, "Test")
        // Test projected value
        let projected = i3.projectedValue
        XCTAssertNotNil(projected)
    }

    @available(iOS 17, *)
    @MainActor
    func testInjectedObservable() throws {
        // Test initializer for default container
        let i1 = InjectedObservable(\.contentObservableViewModel)
        let cvm1 = i1.wrappedValue
        XCTAssertEqual(cvm1.text, "Test")
        // Test initializer for custom container
        let i2 = InjectedObservable(\CustomContainer.contentObservableViewModel)
        let cvm2 = i2.wrappedValue
        XCTAssertEqual(cvm2.text, "Test")
        // Test initializer for passed parameter
        let i3 = InjectedObservable(ContentObservableViewModel())
        let cvm3 = i3.wrappedValue
        XCTAssertEqual(cvm3.text, "Test")
        // Test projected value
        let projected = i3.projectedValue
        XCTAssertEqual(projected.wrappedValue.test.a, 1)
    }
    #endif

}

#if canImport(SwiftUI)
@available(iOS 14, *)
class ContentViewModel: ObservableObject {
    @Published var text = "Test"
}
@available(iOS 14, *)
extension Container {
    var contentViewModel: Factory<ContentViewModel> {
        self { ContentViewModel() }
    }
}
@available(iOS 14, *)
extension CustomContainer {
    var contentViewModel: Factory<ContentViewModel> {
        self { ContentViewModel() }
    }
}

@available(iOS 14, *)
class ResolvingViewModel: ObservableObject {
    @InjectedType var service1: MyService?
    @InjectedType(Container.shared) var service2: MyService?
}

extension Container: Resolving {}

@available(iOS 17, *)
extension Container {
    var contentObservableViewModel: Factory<ContentObservableViewModel> {
        self { ContentObservableViewModel() }
    }
}

@available(iOS 17, *)
extension CustomContainer {
    var contentObservableViewModel: Factory<ContentObservableViewModel> {
        self { ContentObservableViewModel() }
    }
}

@available(iOS 17, *)
@Observable
class ContentObservableViewModel {

    @ObservationIgnored
    @Injected(\.myServiceType) var viewModel

    struct Test {
        var a: Int = 1
        var b: String = "2"
    }

    var text = "Test"
    var test: Test = .init()
    
}

@available(iOS 17, *)
struct ContentObservableView: View {
    @InjectedObservable(\.contentObservableViewModel) var viewModel
    var body: some View {
        Text(viewModel.text)
        TextField("Test", text: $viewModel.test.b)
    }
}

#endif

