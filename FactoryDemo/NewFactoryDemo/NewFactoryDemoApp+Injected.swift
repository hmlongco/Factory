//
//  FactoryDemoApp+Injected.swift
//  FactoryDemo
//
//  Created by Michael Long on 1/15/23.
//

import Foundation

// Example of static Factory 1.0 registration
//extension Container {
//    static var oldSchool = Factory<MyServiceType> {
//        MyService()
//    }
//}

// Example of static Factory 2.0 registration, still not recommended as bound to a single container
// and no longer works with @Injected property wrappers.
extension Container {
    static var newSchool: Factory<MyServiceType> {
        factory { MyService() }
    }
}

// Example of basic registration in a Factory 2.0 container
extension Container {
    var service: Factory<MyServiceType> {
        Factory(self) { MyService() }
    }
}

// Example of basic factory registration using convenience function
extension Container {
    var convenientService: Factory<MyServiceType> {
        factory { MyService() }
    }
}

// Examples of scoped services in a Factory 2.0 container
extension Container {
    var standardService: Factory<MyServiceType> {
        factory { MyService() } // unique
    }
    var cachedService: Factory<MyServiceType> {
        factory { MyService() }.cached
    }
    var singletonService: Factory<SimpleService> {
        factory { SimpleService() }.singleton
    }
    var sharedService: Factory<MyServiceType> {
        factory { MyService() }
            .decorator { print("DECORATING \($0.id)") }
            .shared
    }
}

// Example of service with constructor injection that requires another services
extension Container {
    var constructedService: Factory<MyConstructedService> {
        factory {
            MyConstructedService(service: self.cachedService())
        }
    }
}

// Example of parameterized functional registration in a Factory 2.0 container
extension Container {
    func parameterized(_ n: Int) -> Factory<ParameterService> {
        factory { ParameterService(count: n) }
    }
}

// Example of correctly handling multiple instances of the same type
extension Container {
    var string1: Factory<String> {
        factory { "String 1" }
    }
    var string2: Factory<String> {
        factory { "String 2" }
    }
    var string3: Factory<String> {
        factory { "String 3" }
    }
    var string4: Factory<String> {
        factory { "String 4" }
    }
}

extension Scope {
    static let mine = Cached()
}

extension Container: AutoRegistering {
    public func autoRegister() {
        service.register { MockServiceN(0) }
        cachedService.register { MockServiceN(2) }
        decorator {
            print("RESOLVED \(type(of: $0))")
        }
    }
}

// Example of a custom container with default factories
public final class MyContainer: SharedContainer {

    public static var shared = MyContainer()
    public var manager = ContainerManager()

    var sample1: Factory<MyServiceType> {
        factory { MyService() }
    }
    var sample2: Factory<MyServiceType> {
        factory { MyService() }
            .custom(scope: .mine)
    }

}


// Example of extending a custom container with factory
extension MyContainer {
    var anotherService: Factory<MyServiceType> {
        factory { MyService() }
    }
}

// Circular

class CircularA {
    @Injected(\.circularB) var circularB
}

class CircularB {
    @Injected(\.circularC) var circularC
}

class CircularC {
    @Injected(\.circularA) var circularA
}

extension Container {

    var circularA: Factory<CircularA> { factory { CircularA() } }
    var circularB: Factory<CircularB> { factory { CircularB() } }
    var circularC: Factory<CircularC> { factory { CircularC() } }

    func testCircularDependencies() {
        let a = Container.shared.circularA()
        print(a)
    }
}

// Circular

class GraphBaseClass {
    let id = UUID().uuidString
    @Injected(\.graphDependency) var dependency1
    @Injected(\.graphDependency) var dependency2
}

class GraphDependencyClass {
    let id = UUID().uuidString
    @Injected(\.sharedService) var sharedService
}

extension Container {
    var graphBase: Factory<GraphBaseClass> { factory { GraphBaseClass() } }
    var graphDependency: Factory<GraphDependencyClass> { factory { GraphDependencyClass() }.graph }
}

// Static

extension MyContainer {
    static var staticTest: Factory<MyServiceType> {
        factory { MyService() }
            .decorator { print("STATIC \($0.id)") }
            .shared
    }
}
