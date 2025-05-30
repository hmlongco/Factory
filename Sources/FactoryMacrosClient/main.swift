import FactoryMacros

public protocol MyServiceType {}
public protocol MainActorType {}

public struct MyService: MyServiceType {}
public struct MockMyService: MyServiceType {}
public struct OtherService {}

@MainActor public class MainActorService: MainActorType {}

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

}

Container.shared.testMacro1()
Container.shared.testMacro2()
