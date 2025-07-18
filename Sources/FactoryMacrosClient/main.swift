import FactoryMacros
import Foundation

public protocol MyServiceType {
    var id: UUID { get }
}
@MainActor public protocol MainActorType {
    var id: UUID { get }
}

public struct MyService: MyServiceType {
    public var id: UUID = .init()
}
public struct MockMyService: MyServiceType {
    public var id: UUID = .init()
}
public struct OtherService {}

@MainActor public class MainActorService: MainActorType {
    public var id: UUID = .init()
}

public struct MyParameterService {
    let parameter: Int
    init(_ parameter: Int) {
        self.parameter = parameter
    }
}

protocol MyServiceProviding {
    var myService: MyServiceType { get }
}

protocol FactoryProviding {
    static var instance: Self { get }
}

extension Scope {
    public static let session = Scope.Cached()
}

extension Container: MyServiceProviding {

    func unique<T>(key: StaticString = #function, _ factory: @escaping () -> T) -> T {
        Factory<T>(self, key: key, factory).unique.resolve()
    }

    func cached<T>(key: StaticString = #function, _ factory: @escaping () -> T) -> T {
        Factory<T>(self, key: key, factory).cached.resolve()
    }

    func instance<T>(key: StaticString = #function, _ factory: @escaping () -> T) -> T {
        Factory<T>(self, key: key, factory).unique.resolve()
    }

    func scope<T>(_ scope: Scope, key: StaticString = #function, _ factory: @escaping () -> T) -> T {
        Factory<T>(self, key: key, factory).scope(scope).resolve()
    }

    @MirrorFactory
    var uniqueService: MyServiceType {
        unique { MyService() }
    }

    @MirrorFactory
    public var cachedService: MyServiceType {
        Factory<MyServiceType>(self) { MyService() }()
    }

//    @MainActor
//    @MirrorFactory
//    var mirroredMainActorService: MainActorType {
//        scope(.cached) { MainActorService() }
//    }

    var currentService: Factory<MyServiceType> {
        Factory(self) { MyService() }
    }

    @DefineFactory({ MyService() })
    public var myService: MyServiceType

    @DefineFactory({ MyService() }, scope: .session)
    var myService2: MyServiceType

    @DefineFactory({ MainActorService() })
    var mainActorService1: MainActorService

    @available(iOS 13.0, macOS 10.15, *)
    @DefineFactory({ MainActorService() })
    var mainActorService2: MainActorType

//    @DefineParameterFactory({ p in MyParameterService(p) })
//    var parameterService1: (Int) -> MyParameterService

    func testMacro1() {
        let currentService1 = Container.shared.currentService()
        print(type(of: currentService1))

        Container.shared.currentService.register { MockMyService() }
        let currentService2 = Container.shared.currentService()
        print(type(of: currentService2))

        let myService1 = Container.shared.myService
        print(type(of: myService1))
        Container.shared.$myService.register {
            MockMyService()
        }

        let myService2 = Container.shared.myService
        print(type(of: myService2))

    }

    func testMacro2() {
        let service1 = Container.shared.mainActorService1
        print(type(of: service1))

    }

    func testMacro3() {
        Container.shared.manager.trace = true
        let myService3 = Container.shared.cachedService
        print("\(type(of: myService3)) \(myService3.id)")
        Container.shared.$cachedService.register {
            MockMyService()
        }
        let myService4 = Container.shared.cachedService
        print("\(type(of: myService4)) \(myService4.id)")
        let myService5 = Container.shared.cachedService
        print("\(type(of: myService5)) \(myService5.id)")
    }

}

Container.shared.testMacro1()
//Container.shared.testMacro2()
//Container.shared.testMacro3()
