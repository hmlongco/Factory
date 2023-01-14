//
//  Alternatives.swift
//  NewFactoryDemo
//
//  Created by Michael Long on 9/18/22.
//

import Foundation

public struct NewFactory<T> {
    public init(_ factory: @escaping () -> T) {
        self.container = NewContainer.shared
        self.factory = factory
    }
    public init(_ container: FactoryContainer, _ factory: @escaping () -> T) {
        self.container = container
        self.factory = factory
    }
    public func callAsFunction() -> T {
        container.registrations.resolve(id: id, factory: factory)
    }
    public func register(factory: @escaping () -> T) {
        container.registrations.register(id: id, factory: factory)
    }
    public func name(_ name: String) -> Self {
        var mutable = self
        mutable.name = name
        return mutable
    }
    public func scope(_ scope: NewFactoryScope) -> Self {
        var mutable = self
        mutable.scope = scope
        return mutable
    }
    public func reset() {
        container.registrations.reset(id: id)
    }
    private var id: String {
        "\(container).\(T.self).\(name)"
    }
    private let container: FactoryContainer
    private let factory: () -> T
    private var name: String = "*"
    private var scope: NewFactoryScope?
}

private struct NewRegistration<T> {}

public class NewFactoryScope {}
public extension NewFactoryScope {
    static var cached: NewFactoryScope = NewFactoryScope()
    static var shared: NewFactoryScope = NewFactoryScope()
    static var singleton: NewFactoryScope = NewFactoryScope()
}

public class Registrations {
    fileprivate func resolve<T>(id: String, factory: () -> T) -> T {
        defer { lock.unlock() }
        lock.lock()
        print("RESOLVING \(id)")
        return registrations[id]?() as? T ?? factory()
    }
    fileprivate func register<T>(id: String, factory: @escaping () -> T) {
        defer { lock.unlock() }
        lock.lock()
        registrations[id] = factory
    }
    fileprivate func reset(id: String) {
        defer { lock.unlock() }
        lock.lock()
        registrations.removeValue(forKey: id)
    }
    internal var lock = NSRecursiveLock()
    internal var registrations: [String:(() -> Any)] = [:]
}




public protocol FactoryContainer: AnyObject {
    var registrations: Registrations { get }
}

extension FactoryContainer {
    public func factory<T>(factory: @escaping () -> T) -> NewFactory<T> {
        NewFactory(self, factory)
    }
    public func container<T>(factory: @escaping () -> T) -> NewFactory<T> {
        NewFactory(self, factory)
    }
}



public protocol InjectableContainer: FactoryContainer {
    static var shared: Self { get }
}

public final class NewContainer: InjectableContainer {
    public static var shared = NewContainer()
    public var registrations: Registrations = Registrations()
}

extension NewContainer {
    static var oldSchool = NewFactory<MyServiceType> { MyService() }
        .scope(.shared)
}


extension NewContainer {
    var service: NewFactory<MyServiceType> {
        .init(self) { MyService() }
    }
    var cachedService: NewFactory<MyServiceType> {
        .init(self) { MyService() }
            .scope(.singleton)
    }
    var namedService: NewFactory<MyServiceType> {
        .init(self) { MyService() }
            .name("test")
    }
    var constructedService: NewFactory<MyConstructedService> {
        .init(self) { MyConstructedService(service: self.service()) }
    }
    func parameterized(_ n: Int) -> NewFactory<ParameterService> {
        .init(self) { ParameterService(count: n) }
    }
}




public final class MyContainer: InjectableContainer {
    public static var shared = MyContainer()
    public var registrations: Registrations = Registrations()
}

extension MyContainer {
    var anotherService: NewFactory<MyServiceType> {
        factory { MyService() }
    }
}


//public class PureContainer: NewFactoryContainer {
//    public var manager = ContainerManager()
//    lazy var anotherService = NewFactory<MyServiceType>(self) {
//        MyService()
//    }
//    lazy var constructedService = NewFactory<MyConstructedService>(self) {
//        MyConstructedService(service: self.anotherService())
//    }
//}


@propertyWrapper public struct NewInjected<T> {
    private var dependency: T
    public init(_ keyPath: KeyPath<NewContainer, NewFactory<T>>) {
        self.dependency = NewContainer.shared[keyPath: keyPath]()
    }
    public init<C:InjectableContainer>(_ keyPath: KeyPath<C, NewFactory<T>>) {
        self.dependency = C.shared[keyPath: keyPath]()
    }
    public var wrappedValue: T {
        get { return dependency }
        mutating set { dependency = newValue }
    }
}



class Test1 {

    // Old factory static service Locator
    let oldSchool = NewContainer.oldSchool()

    // New shared service Locator
    let service = NewContainer.shared.constructedService()

    // Constructor initialized from container
    let service2: MyConstructedService

    // Lazy initialized from container
    private let container: NewContainer
    private lazy var service3: MyConstructedService = container.constructedService()
    private lazy var service4: MyServiceType = container.service()

    // Injected property from default shared container
    @NewInjected(\.constructedService) var constructed

    // Injected property from custom container
    @NewInjected(\MyContainer.anotherService) var anotherService

    // Constructor
    init(container: NewContainer) {
        // construct from container
        service2 = container.constructedService()

        // save container for lazy resolution
        self.container = container

        container.service.register { MockServiceN(8) }

        print(constructed.text())
        print(service.text())
        print(service2.text())
    }

}

