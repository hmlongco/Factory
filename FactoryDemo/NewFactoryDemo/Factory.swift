//
//  Factory.swift
//  FactoryDemo
//
//  Created by Michael Long on 1/15/23.
//

import Foundation

/// Factory manages the dependency injection process for a specific object or service.
public struct Factory<T> {

    /// New initializer
    public init(_ container: SharedContainer, scope: Scope? = .unique, dif: Int = #line, _ factory: @escaping () -> T) {
        self.id = "\(container.manager.managerID).\(T.self).\(dif)"
        self.container = container
        self.factory = TypedFactory(factory: factory)
        self.scope = scope
    }

    /// Old initializer
    @available(*, deprecated, message: "Container method syntax preferred")
    public init(scope: Scope? = .unique, _ factory: @escaping () -> T) {
        self.id = "\(Container.shared.manager.managerID).\(UUID().uuidString)"
        self.container = Container.shared
        self.factory = TypedFactory(factory: factory)
        self.scope = scope
    }

    public func callAsFunction() -> T {
        container.manager.resolve(self)
    }

    public func register(factory: @escaping () -> T) {
        container.manager.register(id: id, factory: factory)
    }

    public func reset(_ options: FactoryResetOptions = .all) {
        container.manager.reset(options: options, for: id)
    }

    internal let id: String
    internal let container: SharedContainer
    internal let factory: TypedFactory<T>
    internal let scope: Scope?

}

/// ContainerManager manages the registration, resolution, and scope caching mechanisms for a given container.
public class ContainerManager {
    
    public init() {}

    public func reset() {
        defer { globalRecursiveLock.unlock() }
        globalRecursiveLock.lock()
        registrations = [:]
        cache.reset()
    }

    public func resetAllRegistrations() {
        defer { globalRecursiveLock.unlock() }
        globalRecursiveLock.lock()
        registrations = [:]
    }

    public func resetAllScopes() {
        defer { globalRecursiveLock.unlock() }
        globalRecursiveLock.lock()
        cache.reset()
    }

    public func reset(scope: Scope) {
        defer { globalRecursiveLock.unlock() }
        globalRecursiveLock.lock()
        cache.reset(scope: scope)
    }

    internal func resolve<T>(_ factory: Factory<T>) -> T {
        defer { globalRecursiveLock.unlock() }
        globalRecursiveLock.lock()

        if autoRegistrationCheck {
            (factory.container as? AutoRegistering)?.autoRegister()
            autoRegistrationCheck = false
        }

        let current: TypedFactory<T> = registrations[factory.id] as? TypedFactory<T> ?? factory.factory

        #if DEBUG
        let typeComponents = String(describing: T.self).components(separatedBy: CharacterSet(charactersIn: "<>"))
        let typeName = typeComponents.count > 1 ? typeComponents[1] : typeComponents[0]
        let typeIndex = globalDependencyChain.firstIndex(where: { $0 == typeName })
        globalDependencyChain.append(typeName)
        if let index = typeIndex {
            let message = "circular dependency chain - \(globalDependencyChain[index...].joined(separator: " > "))"
            globalDependencyChain = []
            globalGraphResolutionDepth = 0
            globalRecursiveLock = NSRecursiveLock()
            triggerFatalError(message, #file, #line)
        }
        #endif

        print("RESOLVING \(factory.id)")

        globalGraphResolutionDepth += 1
        let instance = factory.scope?.resolve(from: cache, id: factory.id, factory: current) ?? current.factory()
        globalGraphResolutionDepth -= 1

        if globalGraphResolutionDepth == 0 {
            Scope.graph.cache.resetIfNeeded()
        }

        #if DEBUG
        globalDependencyChain.removeLast()
        #endif

        decorator?(instance)

        return instance
    }

    internal func register<T>(id: String, factory: @escaping () -> T) {
        defer { globalRecursiveLock.unlock() }
        globalRecursiveLock.lock()
        registrations[id] = TypedFactory<T>(factory: factory)
        cache.removeValue(forKey: id)
    }

    internal func reset(options: FactoryResetOptions, for id: String) {
        guard options != .none else { return }
        defer { globalRecursiveLock.unlock() }
        globalRecursiveLock.lock()
        switch options {
        case .registration:
            registrations.removeValue(forKey: id)
        case .scope:
            cache.removeValue(forKey: id)
        default:
            registrations.removeValue(forKey: id)
            cache.removeValue(forKey: id)
        }
    }

    // Public variables
    public let managerID = UUID().uuidString
    public var decorator: ((Any) -> ())?

    // Internal variables
    internal var autoRegistrationCheck = true
    internal var registrations: [String:AnyFactory] = .init(minimumCapacity: 32)
    internal var cache = Scope.Cache()
}

// Internal types
internal protocol AnyFactory {
}

internal struct TypedFactory<T>: AnyFactory {
    let factory: () -> T
}

// Scopes

public class Scope {

    fileprivate init() {}

    internal func resolve<T>(from cache: Cache, id: String, factory: TypedFactory<T>) -> T {
        if let cached: T = unboxed(box: cache.value(forKey: id)) {
            return cached
        }
        let instance = factory.factory()
        if let box = box(instance) {
            cache.set(value: box, forKey: id)
        }
        return instance
    }

    /// Internal function returns unboxed value if exists
    fileprivate func unboxed<T>(box: AnyBox?) -> T? {
        if let box = box as? StrongBox<T> {
            return box.boxed
        }
        return nil
    }

    /// Internal function correctly boxes cache value depending upon scope type
    fileprivate func box<T>(_ instance: T) -> AnyBox? {
        if let optional = instance as? OptionalProtocol {
            return optional.hasWrappedValue ? StrongBox<T>(scopeID: scopeID, boxed: instance) : nil
        }
        return StrongBox<T>(scopeID: scopeID, boxed: instance)
    }

    internal let scopeID: UUID = UUID()

}

extension Scope {
    class Cache {
        @inlinable internal func value(forKey key: String) -> AnyBox? {
            cache[key]
        }
        @inlinable internal func set(value: AnyBox, forKey key: String)  {
            cache[key] = value
        }
        @inlinable internal func removeValue(forKey key: String) {
            cache.removeValue(forKey: key)
        }
        /// Internal function to clear cache if needed
        @inlinable internal func resetIfNeeded() {
            if !cache.isEmpty {
                cache = [:]
            }
        }
        internal func reset() {
            cache = [:]
        }
        internal func reset(scope: Scope) {
            cache = cache.filter { $1.scopeID != scope.scopeID }
        }
        private var cache: [String:AnyBox] = .init(minimumCapacity: 32)
    }
}

extension Scope {

    /// Defines a cached scope. The same instance will be returned by the factory until the cache is reset.
    public static let cached = Cached()
    public final class Cached: Scope {
        public override init() {
            super.init()
        }
    }

    /// Defines the graph scope. A single instance of a given type will be returned during a given resolution cycle.
    ///
    /// This scope is managed and cleared by the main resolution function at the end of each resolution cycle.
    public static let graph = Graph()
    public final class Graph: Scope {
        public override init() {
            super.init()
        }
        internal override func resolve<T>(from cache: Cache, id: String, factory: TypedFactory<T>) -> T {
            // ignores passed cache
            return super.resolve(from: self.cache, id: id, factory: factory)
        }
        /// Private shared cache
        internal var cache = Cache()
    }

    /// Defines a shared (weak) scope. The same instance will be returned by the factory as long as someone maintains a strong reference.
    public static let shared = Shared()
    public final class Shared: Scope {
        public override init() {
            super.init()
        }
        /// Internal function returns cached value if exists
        fileprivate override func unboxed<T>(box: AnyBox?) -> T? {
            if let box = box as? WeakBox, let instance = box.boxed as? T {
                if let optional = instance as? OptionalProtocol {
                    if optional.hasWrappedValue {
                        return instance
                    }
                } else {
                    return instance
                }
            }
            return nil
        }
        /// Override function correctly boxes weak cache value
        fileprivate override func box<T>(_ instance: T) -> AnyBox? {
            if let optional = instance as? OptionalProtocol {
                if let unwrapped = optional.wrappedValue, type(of: unwrapped) is AnyObject.Type {
                    return WeakBox(scopeID: scopeID, boxed: unwrapped as AnyObject)
                }
            } else if type(of: instance as Any) is AnyObject.Type {
                return WeakBox(scopeID: scopeID, boxed: instance as AnyObject)
            }
            return nil
        }
    }

    /// Defines the singleton scope. The same instance will always be returned by the factory.
    public static let singleton = Singleton()
    public final class Singleton: Scope {
        public override init() {
            super.init()
        }
    }

    /// Empty definition defines the unique scope. Without a scope cache a new instance will always be returned by the factory.
    public static let unique: Scope? = nil

}

// Containers

public protocol SharedContainer: AnyObject {
    static var shared: Self { get }
    var manager: ContainerManager { get set }
}

extension SharedContainer {

    // scoped factory providers

    @inlinable public func cached<T>(dif: Int = #line, factory: @escaping () -> T) -> Factory<T> {
        Factory(self, scope: .cached, dif: dif, factory)
    }

    @inlinable public func custom<T>(_ scope: Scope?, dif: Int = #line, factory: @escaping () -> T) -> Factory<T> {
        Factory(self, scope: scope, dif: dif, factory)
    }

    @inlinable public func graph<T>(dif: Int = #line, factory: @escaping () -> T) -> Factory<T> {
        Factory(self, scope: .graph, dif: dif, factory)
    }

    @inlinable public func shared<T>(dif: Int = #line, factory: @escaping () -> T) -> Factory<T> {
        Factory(self, scope: .shared, dif: dif, factory)
    }

    @inlinable public func singleton<T>(dif: Int = #line, factory: @escaping () -> T) -> Factory<T> {
        Factory(self, scope: .singleton, dif: dif, factory)
    }

    @inlinable public func unique<T>(dif: Int = #line, factory: @escaping () -> T) -> Factory<T> {
        Factory(self, scope: .unique, dif: dif, factory)
    }

}

public final class Container: SharedContainer {
    public static var shared = Container()
    public var manager = ContainerManager()
}


/// Automatic registrations

public protocol AutoRegistering {
    func autoRegister()
}

// Property wrappers

#if swift(>=5.1)

/// Convenience property wrapper takes a factory and creates an instance of the desired type.
@propertyWrapper public struct Injected<T> {
    private let factory: Factory<T>
    private var dependency: T
    public init(_ keyPath: KeyPath<Container, Factory<T>>) {
        self.factory = Container.shared[keyPath: keyPath]
        self.dependency = factory()
    }
    public init<C:SharedContainer>(_ keyPath: KeyPath<C, Factory<T>>) {
        self.factory = C.shared[keyPath: keyPath]
        self.dependency = factory()
    }
    public var wrappedValue: T {
        get { return dependency }
        mutating set { dependency = newValue }
    }
    public var projectedValue: Injected<T> {
        get { return self }
        mutating set { self = newValue }
    }
    public mutating func resolve(reset options: FactoryResetOptions = .none) {
        factory.reset(options)
        dependency = factory()
    }
}

/// Convenience property wrapper takes a factory and creates an instance of the desired type the first time the wrapped value is requested.
@propertyWrapper public struct LazyInjected<T> {
    private var factory: Factory<T>
    private var dependency: T!
    private var initialize = true
    public init(_ keyPath: KeyPath<Container, Factory<T>>) {
        self.factory = Container.shared[keyPath: keyPath]
    }
    public init<C:SharedContainer>(_ keyPath: KeyPath<C, Factory<T>>) {
        self.factory = C.shared[keyPath: keyPath]
    }
    public var wrappedValue: T {
        mutating get {
            if initialize {
                resolve()
            }
            return dependency
        }
        mutating set {
            dependency = newValue
        }
    }
    public var projectedValue: LazyInjected<T> {
        get { return self }
        mutating set { self = newValue }
    }
    public mutating func resolve(reset options: FactoryResetOptions = .none) {
        factory.reset(options)
        dependency = factory()
        initialize = false
    }
}

/// Convenience property wrapper takes a factory and creates an instance of the desired type the first time the wrapped value is requested. This
/// wrapper maintains a weak reference to the object in question, so it must exist elsewhere.
@propertyWrapper public struct WeakLazyInjected<T> {
    private var factory: Factory<T>
    private weak var dependency: AnyObject?
    private var initialize = true
    public init(_ keyPath: KeyPath<Container, Factory<T>>) {
        self.factory = Container.shared[keyPath: keyPath]
    }
    public init<C:SharedContainer>(_ keyPath: KeyPath<C, Factory<T>>) {
        self.factory = C.shared[keyPath: keyPath]
    }
    public var wrappedValue: T? {
        mutating get {
            if initialize {
                resolve()
            }
            return dependency as? T
        }
        mutating set {
            dependency = newValue as AnyObject
        }
    }
    public var projectedValue: WeakLazyInjected<T> {
        get { return self }
        mutating set { self = newValue }
    }
    public mutating func resolve(reset options: FactoryResetOptions = .none) {
        factory.reset(options)
        dependency = factory() as AnyObject
        initialize = false
    }
}

#endif

/// Reset options for factory and registrations
public enum FactoryResetOptions {
    case all
    case none
    case registration
    case scope
}

// Internal Utilities

/// Master recursive lock
private var globalRecursiveLock = NSRecursiveLock()

/// Master graph resolution depth counter
private var globalGraphResolutionDepth = 0

#if DEBUG
/// Internal array used to check for circular dependency cycles
private var globalDependencyChain: [String] = []
#endif

/// Internal protocol used to evaluate optional types for caching
public protocol OptionalProtocol {
    var hasWrappedValue: Bool { get }
    var wrappedValue: Any? { get }
}

extension Optional: OptionalProtocol {
    @inlinable public var hasWrappedValue: Bool {
        wrappedValue != nil
    }
    @inlinable public var wrappedValue: Any? {
        if case .some(let value) = self {
            return value
        }
        return nil
    }
}

/// Internal box protocol for scope functionality
internal protocol AnyBox {
    var scopeID: UUID { get }
}
internal struct StrongBox<T>: AnyBox {
    let scopeID: UUID
    let boxed: T
}

/// Weak box for shared scope
private struct WeakBox: AnyBox {
    let scopeID: UUID
    weak var boxed: AnyObject?
}

#if DEBUG
/// Allow unit test interception of any fatal errors that may occur running the circular dependency check
/// Variation of solution: https://stackoverflow.com/questions/32873212/unit-test-fatalerror-in-swift#
internal var triggerFatalError = Swift.fatalError
#endif
