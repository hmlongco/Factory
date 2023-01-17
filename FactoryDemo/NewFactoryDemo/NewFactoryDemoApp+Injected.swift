//
//  FactoryDemoApp+Injected.swift
//  FactoryDemo
//
//  Created by Michael Long on 1/15/23.
//

import Foundation

// Example of Factory 1.0 registration
extension Container {
    static var oldSchool = Factory<MyServiceType> { MyService() }
}

// Example of same registration in a Factory 2.0 container
extension Container {
    var service: Factory<MyServiceType> {
        Factory(self) {
            MyService()
        }
    }
}

// Example of service with constructor injection that requires another services
extension Container {
    var constructedService: Factory<MyConstructedService> {
        .init(self) {
            MyConstructedService(service: self.cachedService())
        }
    }
}

// Examples of scoped and named registrations in a Factory 2.0 container
extension Container {
    var cachedService: Factory<MyServiceType> {
        cached { MyService() }
    }
    var singletonService: Factory<SimpleService> {
        singleton { SimpleService() }
    }
    var sharedService: Factory<MyServiceType> {
        shared { MyService() }
    }
    var namedService1: Factory<MyServiceType> {
        unique { MyService() }
    }
    var namedService2: Factory<MyServiceType> {
        Factory(self) { MyService() }
    }
    var string1: Factory<String> {
        Factory(self) { "String 1" }
    }
    var string2: Factory<String> {
        Factory(self) { "String 2" }
    }
}

// Example of parameterized functional registration in a Factory 2.0 container
extension Container {
    func parameterized(_ n: Int) -> Factory<ParameterService> {
        unique { ParameterService(count: n) }
    }
}

// Example of Factory 2.0 registrations
extension SharedContainer {
    var service1: Factory<MyServiceType> {
        Factory(self) { MyService() }
    }
    var service2: Factory<MyServiceType> {
        .init(self) { MyService() }
    }
    var service3: Factory<MyServiceType> {
        unique { MyService() }
    }
    var service4: Factory<MyServiceType> {
        shared { MyService() }
    }
    var service5: Factory<MyServiceType> {
        custom(.mine) { MyService() }
    }
}

extension Scope {
    static let mine = Cached()
}

extension Container: AutoRegistering {
    public func autoRegister() {
        service.register { MockServiceN(0) }
        cachedService.register { MockServiceN(2) }
        // manager.decorator = { print("RESOLVING \(type(of: $0))") }
    }
}

// Example of a custom container
public final class MyContainer: SharedContainer {

    public static var shared = MyContainer()
    public var manager = ContainerManager()

    var sample: Factory<MyServiceType> { shared { MyService() } }

}

// Example of registration in a custom container
extension MyContainer {
    var anotherService: Factory<MyServiceType> {
        unique { MyService() }
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

    var circularA: Factory<CircularA> { unique { CircularA() } }
    var circularB: Factory<CircularB> { unique { CircularB() } }
    var circularC: Factory<CircularC> { unique { CircularC() } }

    func testCircularDependencies() {
        let a = Container.shared.circularA()
        print(a)
    }
}

// Circular

class GraphBaseClass {
    @Injected(\.graphDependency) var dependency1
    @Injected(\.graphDependency) var dependency2
}

class GraphDependencyClass {
    let id = UUID().uuidString
}

extension Container {
    var graphBase: Factory<GraphBaseClass> { graph { GraphBaseClass() } }
    var graphDependency: Factory<GraphDependencyClass> { graph { GraphDependencyClass() } }

}
