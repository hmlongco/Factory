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
        Factory(self) { MyService() }
    }
}

// Example of service with constructor injection that requires another services
extension Container {
    var constructedService: Factory<MyConstructedService> {
        factory { MyConstructedService(service: self.service()) }
    }
}

// Examples of scoped and named registrations in a Factory 2.0 container
extension Container {
    var cachedService: Factory<MyServiceType> {
        factory(scope: .singleton) { MyService() }
    }
    var namedService: Factory<MyServiceType> {
        factory(name: "test") { MyService() }
    }
}

// Example of parameterized functional registration in a Factory 2.0 container
extension Container {
    func parameterized(_ n: Int) -> Factory<ParameterService> {
        factory { ParameterService(count: n) }
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
        factory { MyService() }
    }
    var service4: Factory<MyServiceType> {
        shared { MyService() }
    }
}

// Example of a custom container
public final class MyContainer: SharedContainer {
    public static var shared = MyContainer()
    public var registrations = Registrations()
}

// Example of registration in a custom container
extension MyContainer {
    var anotherService: Factory<MyServiceType> {
        factory { MyService() }
    }
}
