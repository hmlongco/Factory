//
//  Alternatives.swift
//  NewFactoryDemo
//
//  Created by Michael Long on 9/18/22.
//

import Foundation

public struct NewFactory<T> {
    fileprivate init(_ container: NewContainer, key: String = #function, _ factory: @escaping () -> T) {
        self.container = container
        self.registration = container.registration(id: "\(container).\(T.self).\(key)", container: container, factory: factory)
    }
    public func callAsFunction() -> T {
        registration.resolve()
    }
    @discardableResult public func register(factory: @escaping () -> T) -> Self {
        registration.register(factory: factory)
        return self
    }
    @discardableResult public func context(factory: @escaping () -> T) -> Self {
        registration.context(factory: factory)
        return self
    }
    @discardableResult public func scope(_ scope: NewFactoryScope) -> Self {
        registration.scope(scope)
        return self
    }
    @discardableResult public func once(_ transform: (_ factory: NewFactory<T>) -> Void) -> Self {
        registration.perform(once: transform(self))
        return self
    }
    public func reset() {
        container.registrations.removeValue(forKey: registration.id)
    }
    internal let container: NewContainer
    internal let registration: NewRegistration<T>
}

public final class NewContainer {
    public static var shared = NewContainer()
    internal func registration<T>(id: String, container: NewContainer, factory: @escaping FactoryType<T>) -> NewRegistration<T> {
        defer { lock.unlock() }
        lock.lock()
        // autoRegistrationCheck
        // print("REGISTRATION \(id)")
        if let registration = registrations[id] as? NewRegistration<T> {
            return registration
        }
        let registration = NewRegistration<T>(id: id, factory: factory)
        registrations[id] = registration
        return registration
    }
    internal var lock = NSRecursiveLock()
    internal var registrations: [String:AnyRegistration] = [:]
}

internal protocol AnyRegistration {}

internal protocol CacheProviding: AnyObject{
    associatedtype T
    var cached: T? { get set }
}

internal typealias FactoryType<T> = () -> T

internal class NewRegistration<T>: AnyRegistration, CacheProviding {
    init(id: String, factory: @escaping FactoryType<T>) {
        self.id = id
        self.factory = factory
    }
    internal func resolve() -> T {
        defer { lock.unlock() }
        lock.lock()
        let instance: T = context?() ?? registration?() ?? factory()
        return instance
    }
    internal func register(factory: @escaping FactoryType<T>) {
        defer { lock.unlock() }
        lock.lock()
        registration = factory
        cached = nil
    }
    internal func context(factory: @escaping () -> T) {
        defer { lock.unlock() }
        lock.lock()
        context = factory
        cached = nil
    }
    internal func perform(once: @autoclosure () -> Void) {
        defer { lock.unlock() }
        lock.lock()
        if hasPeformedOnce == false {
            hasPeformedOnce = true
            print("PERFORMING ONCE")
            once()
        }
    }
    internal func scope(_ newScope: NewFactoryScope) {
        defer { lock.unlock() }
        lock.lock()
        scope = newScope
        cached = nil
    }
    internal var lock = NSRecursiveLock()
    internal var id: String
    internal var factory: FactoryType<T>
    internal var registration: FactoryType<T>?
    internal var context: FactoryType<T>?
    internal var scope: NewFactoryScope?
    internal var cached: T?
    internal var hasPeformedOnce: Bool = false
}


public class NewFactoryScope {}
public extension NewFactoryScope {
    static var cached: NewFactoryScope = NewFactoryScope()
    static var shared: NewFactoryScope = NewFactoryScope()
    static var singleton: NewFactoryScope = NewFactoryScope()
}

extension NewContainer {
    public func callAsFunction<T>(key: String = #function, factory: @escaping () -> T) -> NewFactory<T> {
        NewFactory(self, key: key, factory)
    }
}


struct ContextService {
    var name: String
}

extension NewContainer {
    fileprivate var contextService: NewFactory<ContextService> {
        self { ContextService(name: "FACTORY") }
            .context { ContextService(name: "CONTEXT") }
    }
    fileprivate var onceService: NewFactory<ContextService> {
        self { ContextService(name: "FACTORY") }
            .once { $0.context { ContextService(name: "CONTEXT-ONCE") } }
    }
}

extension NewContainer {
    var service: NewFactory<MyServiceType> {
        self { MyService() }
    }
    var cachedService: NewFactory<MyServiceType> {
        self { MyService() }
            .scope(.singleton)
    }
    var namedService: NewFactory<MyServiceType> {
        self { MyService() }
    }
    var constructedService: NewFactory<MyConstructedService> {
        self { MyConstructedService(service: self.service()) }
    }
    func parameterized(_ n: Int) -> NewFactory<ParameterService> {
        self { ParameterService(count: n) }
    }
}

@propertyWrapper public struct NewInjected<T> {
    private var dependency: T
    public init(_ keyPath: KeyPath<NewContainer, NewFactory<T>>) {
        self.dependency = NewContainer.shared[keyPath: keyPath]()
    }
    public var wrappedValue: T {
        get { return dependency }
        mutating set { dependency = newValue }
    }
}

class Test1 {

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

    // Constructor
    init(container: NewContainer = NewContainer.shared) {
        // construct from container
        service2 = container.constructedService()

        // save container for lazy resolution
        self.container = container

        container.service.register { MockServiceN(8) }

        print(service.text())
        print(service2.text())

        print("CONTEXT = \(container.contextService().name)")
        container.contextService.context {
            ContextService(name: "CONTEXT-REVISED")
        }
        print("CONTEXT = \(container.contextService().name)")

        print("ONCE = \(container.onceService().name)")
        container.onceService.context {
            ContextService(name: "CONTEXT-REVISED")
        }
        print("ONCE = \(container.onceService().name)")
    }

}

