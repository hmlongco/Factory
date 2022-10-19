//
//  Alternatives.swift
//  FactoryDemo
//
//  Created by Michael Long on 9/18/22.
//

import Foundation
import Factory

public struct AltFactory<T> {

    /// Initializes a Factory with a factory closure that returns a new instance of the desired type.
    public init(_ factory: @autoclosure @escaping () -> T) {
        self.registration = AltRegistration<Void, T>(factory: factory)
    }

    /// Initializes a Factory with a factory closure that returns a new instance of the desired type.
    public init(_ container: AnyObject, _ factory: @autoclosure @escaping () -> T) {
        self.registration = AltRegistration<Void, T>(factory: factory)
    }

    /// Resolves and returns an instance of the desired object type. This may be a new instance or one that was created previously and then cached,
    /// depending on whether or not a scope was specified when the factory was created.
    ///
    /// Note return type could of T could still be <T?> depending on original Factory specification.
    public func callAsFunction() -> T {
        registration.resolve(())
    }

    /// Registers a new factory that will be used to create and return an instance of the desired object type.
    ///
    /// This registration overrides the orginal factory and its result will be returned on all new object resolutions. Registering a new
    /// factory also clears the previous instance from the associated scope.
    ///
    /// All registrations are stored in SharedContainer.Registrations.
    public func register(factory: @autoclosure @escaping () -> T) {
       // registration.register(factory: factory)
    }

    /// Deletes any registered factory override and resets this Factory to use the factory closure specified during initialization. Also
    /// resets the scope so that a new instance of the original type will be returned on the next resolution.
    public func reset() {
        //registration.reset()
    }

    private let registration: AltRegistration<Void, T>
}

private struct AltRegistration<P, T> {

    let id: UUID = UUID()
    let factory: (P) -> T

    func resolve(_ p: P) -> T {
        factory(p)
    }

}

class AltContainer1 {
    static var shared = AltContainer1()
}
class AltContainer2 {
    static var shared = AltContainer2()
}

extension AltContainer1 {
    var constructedService: AltFactory<MyConstructedService> {
        .init(MyConstructedService(service: self.supporting()) )
    }
    var supporting: AltFactory<MyServiceType> {
        .init(MyService() )
    }
}


extension AltContainer2 {
    var constructedService: AltFactory<MyConstructedService> {
        .init(self, MyConstructedService(service: self.supporting()) )
    }
    var supporting: AltFactory<MyServiceType> {
        .init(self, MyService() )
    }
}


extension Container {
    static let constructedService = Factory {
        MyConstructedService(service: supporting())
    }
    static let supporting = Factory<MyServiceType> {
        MyService()
    }
}

class Test1 {
    let service = AltContainer1.shared.constructedService()
}
class Test2 {
    let service = Container.constructedService()
}

