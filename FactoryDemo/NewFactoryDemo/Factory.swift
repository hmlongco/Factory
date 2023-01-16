//
//  Factory.swift
//  FactoryDemo
//
//  Created by Michael Long on 1/15/23.
//

import Foundation

// The Factory

public struct Factory<T> {
    /// New private initializer
    public init(_ container: SharedContainer, scope: Scope? = nil, name: String = "*", _ factory: @escaping () -> T) {
        let id = "\(container.registrations.id).\(T.self).\(name)"
        self.container = container
        self.registration = Registration(id: id, factory: factory, scope: scope)
    }
    public init(container: SharedContainer, scope: Scope? = nil, name: String = "*", _ factory: @escaping () -> T) {
        let id = "\(container.registrations.id).\(T.self).\(name)"
        self.container = container
        self.registration = Registration(id: id, factory: factory, scope: scope)
    }
    /// Old initializer
    @available(*, deprecated, message: "Container factory method preferred")
    public init(scope: Scope? = nil, name: String = "*", _ factory: @escaping () -> T) {
        let id = "\(Container.shared.registrations.id).\(UUID().uuidString)"
        self.container = Container.shared
        self.registration = Registration(id: id, factory: factory, scope: scope)
    }
    public func callAsFunction() -> T {
        container.registrations.resolve(registration)
    }
    public func register(factory: @escaping () -> T) {
        container.registrations.register(id: registration.id, factory: factory)
    }
    public func reset() {
        container.registrations.reset(id: registration.id)
    }
    private let container: SharedContainer
    private let registration: Registration<T>
}

// Registration Management

public struct Registration<T> {
    public var id: String
    public let factory: () -> T
    public var scope: Scope?
}

public struct Registrations {
    fileprivate let id = UUID().uuidString
    fileprivate func resolve<T>(_ registration: Registration<T>) -> T {
        defer { lock.unlock() }
        lock.lock()
        print("RESOLVING \(registration.id)")
        let factory: () -> T = registrations[registration.id] as? () -> T ?? registration.factory
        let dependency = registration.scope?.resolve(id: registration.id, factory: factory) ?? factory()
        return dependency
    }
    fileprivate mutating func register<T>(id: String, factory: @escaping () -> T) {
        defer { lock.unlock() }
        lock.lock()
        registrations[id] = factory
    }
    fileprivate mutating func reset(id: String) {
        defer { lock.unlock() }
        lock.lock()
        registrations.removeValue(forKey: id)
    }
    internal var lock = NSRecursiveLock()
    internal var registrations: [String:(() -> Any)] = [:]
}

// Scopes

public class Scope {
    public func resolve<T>(id: String, factory: @escaping () -> T) -> T {
        print("SCOPE \(id)")
        return factory()
    }
}
public extension Scope {
    static var cached: Scope = Scope()
    static var graph: Scope = Scope()
    static var shared: Scope = Scope()
    static var singleton: Scope = Scope()
    static var unique: Scope = Scope()
}

// Containers

public protocol SharedContainer: AnyObject {
    static var shared: Self { get }
    var registrations: Registrations { get set }
}

extension SharedContainer {
    public func factory<T>(scope: Scope? = .none, name: String = "*", factory: @escaping () -> T) -> Factory<T> {
        Factory(self, scope: scope, name: name, factory)
    }
    public func shared<T>(scope: Scope? = .none, name: String = "*", factory: @escaping () -> T) -> Factory<T> {
        Factory(self, scope: scope, name: name, factory)
    }
    public func unique<T>(scope: Scope? = .none, name: String = "*", factory: @escaping () -> T) -> Factory<T> {
        Factory(self, scope: scope, name: name, factory)
    }
}

public final class Container: SharedContainer {
    public static var shared = Container()
    public var registrations = Registrations()
}

// Property wrappers

@propertyWrapper public struct Injected<T> {
    private var dependency: T
    public init(_ keyPath: KeyPath<Container, Factory<T>>) {
        self.dependency = Container.shared[keyPath: keyPath]()
    }
    public init<C:SharedContainer>(_ keyPath: KeyPath<C, Factory<T>>) {
        self.dependency = C.shared[keyPath: keyPath]()
    }
    public var wrappedValue: T {
        get { return dependency }
        mutating set { dependency = newValue }
    }
}

@propertyWrapper public struct LazyInjected<T> {
    private let factory: Factory<T>
    public init(_ keyPath: KeyPath<Container, Factory<T>>) {
        self.factory = Container.shared[keyPath: keyPath]
    }
    public init<C:SharedContainer>(_ keyPath: KeyPath<C, Factory<T>>) {
        self.factory = C.shared[keyPath: keyPath]
    }
    public lazy var wrappedValue: T = factory()
}
