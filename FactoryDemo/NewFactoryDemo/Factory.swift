//
//  Factory.swift
//  Factory
//
//  Created by Michael Long on 1/15/23.
//

import Foundation

// MARK: - The Factory

/// A Factory manages the dependency injection process for a specific object or service and produces an object of the desired type
/// when required. This may be a brand new instance or Factory may return a previously cached value from the specified scope.
///
/// Let's define a Factory that returns an instance of `ServiceType`. To do that we need to extend a Factory `Container` and within
/// that container we define a new computed variable of type `Factory<ServiceType>`. The type must be explicity defined, and is usually a
/// protocol to which the returned dependency conforms.
///
/// extension Container {
///     var service: Factory<ServiceType> {
///         factory { MyService() }
///     }
/// }
///
/// Inside the computed variable we build our Factory, providing a factory closure that creates an instance of our object when needed. The factory
/// function creates our Factory for us, binding it to the current instance of its container. That Factory is then returned to the caller, usually
/// to be evaluated (see `callAsFunction()` below).
///
/// Every time we resolve this function we'll get a new, unique instance of our object. Factory also supports additional scopes we can use
/// to manage our dependencies lifecycle, and those can be added to the definition when needed. (See `Scope`.)
///
/// factory(scope: .shared) { MyService() }
///
/// Like SwftUI Views, Factory structs are lightweight and transitory. Ther're created when needed and then immediately discared once their purpose
/// has been served.
public struct Factory<T> {

    /// Private initializer which creates a new Factory capable of managing dependencies of the desired type. Use a container's `factory` function
    /// to create and return an instance of Factory.
    ///
    /// - Parameters:
    ///   - container: The bound container that manages registrations and scope caching for this Factory.
    ///   - scope: The cache (if any) used to manage the lifetime of the created object. Unique is the default. (no caching)
    ///   - key: Hidden value used to differentiate different instances of the same type in the same container.
    ///   - factory: A factory closure that produces an object of the desired type when required.
    fileprivate init(container: SharedContainer, scope: Scope, key: String, _ factory: @escaping () -> T) {
        self.id = "\(container.self).\(key)"
        self.container = container
        self.factory = TypedFactory(factory: factory)
        self.scope = scope
    }

//    /// Deprecated initializer
//    @available(*, deprecated, message: "Container method syntax preferred")
//    public init(scope: Scope = .unique, _ factory: @escaping () -> T) {
//        self.id = "\(Container.shared.self).\(UUID().uuidString)"
//        self.container = Container.shared
//        self.factory = TypedFactory(factory: factory)
//        self.scope = scope
//    }

    /// Evaluates the factory and returns an object or service of the desired type. The resolved instance may be brand new or Factory may
    /// return a cached value from the specified scope.
    ///
    /// let service = container.service()
    ///
    /// - Returns: An object or service of the desired type.
    public func callAsFunction() -> T {
        container.manager.resolve(self)
    }

    /// Registers a new factory closure capable of producing an object or service of the desired type. This factory overrides the original
    /// factory closure and clears the associated scope so that the next time this factory is resolved Factory will evaluate the new
    /// closure and return an instance of the newly registered object instead.
    ///
    /// container.service.register {
    ///     SomeService()
    /// }
    ///
    /// This is how default functionality is overriden in order to change the nature of the system at runtime, and is the primary mechanism
    /// used to provide mocks and testing doubles.
    ///
    /// The original factory closure is preserved, and may be restored by resetting the Factory to its original state.
    ///
    /// - Parameter factory: A new factory closure that produces an object of the desired type when needed.
    public func register(factory: @escaping () -> T) {
        container.manager.register(id: id, factory: factory)
    }

    /// Resets the Factory's behavior to its original state, removing any registraions and clearing any cached items from the specified scope.
    /// - Parameter options: options description
    public func reset(_ options: FactoryResetOptions = .all) {
        container.manager.reset(options: options, for: id)
    }

    /// Internal id used to manage registrations and cached values. Usually looks something like "MyApp.Container.service".
    internal var id: String
    /// A strong reference to the container supporting this Factory.
    internal let container: SharedContainer
    /// The originally registered factory closure used to produce an object of the desired type.
    internal let factory: TypedFactory<T>
    /// The scope responsible for managing the lifecycle of any objects created by this Factory.
    internal var scope: Scope

}

// MARK: - Containers

/// Containers are used by Factory to manage object creation, object resolution, and object lifecycles in general.
///
/// Registrations and scope caches will persist as long as the associated container remains in scope.
///
/// SharedContainer defines the protocol all Containers must adopt.
public protocol SharedContainer: AnyObject {
    /// Defines a single "shared" container for that container type.
    ///
    /// This container is used by the various @Injected property wrappers to resolve the keyPath to a given Factory. Care should be taken in
    /// mixed environments where you're passing container references and using the @Injected property wrappers.
    static var shared: Self { get }
    /// Defines the ContainerManager used to manage registrations, resolutions, and scope caching for that container. Ecapsulating the code in
    /// this fashion makes creating and using your own custom containers much simpler.
    var manager: ContainerManager { get set }
}

/// Defines factory providers for containers
extension SharedContainer {
    /// Creates and returns a Factory struct associated with to the current `shared` container. The default scope is `unique` unless otherwise
    /// specified.
    public static func factory<T>(scope: Scope = .unique, key: String = #function, _ factory: @escaping () -> T) -> Factory<T> {
        Factory(container: shared, scope: scope, key: key, factory)
    }
    /// Creates and returns a Factory struct associated with the current` container. The default scope is `unique` unless otherwise specified.
    public func factory<T>(scope: Scope = .unique, key: String = #function, _ factory: @escaping () -> T) -> Factory<T> {
        Factory(container: self, scope: scope, key: key, factory)
    }
}

/// Default "Convenience" Container
public final class Container: SharedContainer {
    public static var shared = Container()
    public var manager = ContainerManager()
}

// MARK: - ContainerManager

/// ContainerManager encapsulates and manages the registration, resolution, and scope caching mechanisms for a given container.
public class ContainerManager {

    /// Public initializer
    public init() {}

    /// Resolves a Factory, returning an instance of the desired type. All roads lead here.
    ///
    /// - Parameter factory: Factory wanting resolution.
    /// - Returns: Instance of the desired type.
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

        // print("RESOLVING \(factory.id)")

        globalGraphResolutionDepth += 1
        let instance = factory.scope.resolve(using: cache, id: factory.id, factory: current)
        globalGraphResolutionDepth -= 1

        if globalGraphResolutionDepth == 0 {
            Scope.graph.cache.reset()
        }

#if DEBUG
        globalDependencyChain.removeLast()
#endif

        decorator?(instance)

        return instance
    }

    /// Registers a new factory closure capable of producing an object or service of the desired type. This factory overrides the original factory and
    /// the next time this factory is resolved Factory will evaluate the newly registered factory instead.
    /// - Parameters:
    ///   - id: ID of associated Factory.
    ///   - factory: Factory closure called to create a new instance of the service when needed.
    internal func register<T>(id: String, factory: @escaping () -> T) {
        defer { globalRecursiveLock.unlock() }
        globalRecursiveLock.lock()
        registrations[id] = TypedFactory<T>(factory: factory)
        cache.removeValue(forKey: id)
    }

    /// Support function resets the behavior for a specific Factory to its original state, removing any assocatioed registraions and clearing
    /// any cached instances from the specified scope.
    /// - Parameters:
    ///   - options: Reset option: .all, .registration, .scope, .none
    ///   - id: ID of item to remove from the appropriate cache.
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

    /// Support closure allows all
    public var decorator: ((Any) -> ())?

    // Internals
    internal typealias FactoryMap = [String:AnyFactory]

    internal var autoRegistrationCheck = true
    internal lazy var registrations: FactoryMap = .init(minimumCapacity: 32)
    internal lazy var cache: Scope.Cache = Scope.Cache()
    internal lazy var stack: [(FactoryMap, Scope.Cache.CacheMap, Bool)] = []
}


extension ContainerManager {

    /// Resets the Container to its original state, removing all registrations and clearing the scope cache.
    public func reset(options: FactoryResetOptions = .all) {
        guard options != .none else { return }
        defer { globalRecursiveLock.unlock() }
        globalRecursiveLock.lock()
        switch options {
        case .registration:
            registrations = [:]
        case .scope:
            cache.reset()
        default:
            registrations = [:]
            cache.reset()
        }
    }

    /// Clears any cached values associated with a specific scope.
    public func reset(scope: Scope) {
        defer { globalRecursiveLock.unlock() }
        globalRecursiveLock.lock()
        cache.reset(scope: scope)
    }

    /// Test function pushes the current registration and cache states
    public func push() {
        defer { globalRecursiveLock.unlock() }
        globalRecursiveLock.lock()
        stack.append((registrations, cache.cache, autoRegistrationCheck))
    }

    /// Test function pops and restores a previously pushed registration and cache state
    public func pop() {
        defer { globalRecursiveLock.unlock() }
        globalRecursiveLock.lock()
        if let state = stack.popLast() {
            registrations = state.0
            cache.cache = state.1
            autoRegistrationCheck = state.2
        }
    }

}

// MARK: - Scopes

public class Scope {

    fileprivate init() {}

    /// Internal function returns cached value if it exists. Otherwise it creates a new instance and caches that value for later reference.
    internal func resolve<T>(using cache: Cache, id: String, factory: TypedFactory<T>) -> T {
        if let cached: T = unboxed(box: cache.value(forKey: id)) {
            return cached
        }
        let instance = factory.factory()
        if let box = box(instance) {
            cache.set(value: box, forKey: id)
        }
        return instance
    }

    /// Internal function returns unboxed value if it exists
    fileprivate func unboxed<T>(box: AnyBox?) -> T? {
        if let box = box as? StrongBox<T> {
            return box.boxed
        }
        return nil
    }

    /// Internal function correctly boxes value depending upon scope type
    fileprivate func box<T>(_ instance: T) -> AnyBox? {
        if let optional = instance as? OptionalProtocol {
            return optional.hasWrappedValue ? StrongBox<T>(scopeID: scopeID, boxed: instance) : nil
        }
        return StrongBox<T>(scopeID: scopeID, boxed: instance)
    }

    internal let scopeID: UUID = UUID()

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
        internal override func resolve<T>(using cache: Cache, id: String, factory: TypedFactory<T>) -> T {
            // ignores passed cache
            return super.resolve(using: self.cache, id: id, factory: factory)
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

    /// Defines the unique scope. Without a scope cache a new instance will always be returned by the factory.
    public static let unique = Unique()
    public final class Unique: Scope {
        public override init() {
            super.init()
        }
        internal override func resolve<T>(using cache: Cache, id: String, factory: TypedFactory<T>) -> T {
            factory.factory()
        }
    }

}

extension Scope {

    internal class Cache {
        
        @inlinable func value(forKey key: String) -> AnyBox? {
            cache[key]
        }
        @inlinable func set(value: AnyBox, forKey key: String)  {
            cache[key] = value
        }
        @inlinable func removeValue(forKey key: String) {
            cache.removeValue(forKey: key)
        }
        /// Internal function to clear cache if needed
        @inlinable func reset() {
            if !cache.isEmpty {
                cache = [:]
            }
        }
        internal func reset(scope: Scope) {
            cache = cache.filter { $1.scopeID != scope.scopeID }
        }
        typealias CacheMap = [String:AnyBox]
        var cache: [String:AnyBox] = .init(minimumCapacity: 32)
    }

}

/// MARK: - Automatic registrations

public protocol AutoRegistering {
    func autoRegister()
}

// MARK: - Property wrappers

#if swift(>=5.1)

/// Convenience property wrapper takes a factory and resolves an instance of the desired type.
/// Property wrapper keyPaths resolve to the "shared" container required for each Container type.
@propertyWrapper public struct Injected<T> {

    private var dependency: T

    /// Initializes the property wrapper. The dependency is resolved on initialization.
    /// - Parameter keyPath: KeyPath to a Factory on the default Container.
    public init(_ keyPath: KeyPath<Container, Factory<T>>) {
        self.dependency = Container.shared[keyPath: keyPath]()
    }

    /// Initializes the property wrapper. The dependency is resolved on initialization.
    /// - Parameter keyPath: KeyPath to a Factory on the specfied Container.
    public init<C:SharedContainer>(_ keyPath: KeyPath<C, Factory<T>>) {
        self.dependency = C.shared[keyPath: keyPath]()
    }

    /// Manages the wrapped dependency.
    public var wrappedValue: T {
        get { return dependency }
        mutating set { dependency = newValue }
    }
}

/// Convenience property wrapper takes a factory and resolves an instance of the desired type the first time the wrapped value is requested.
///
/// Note that LazyInjected maintains a reference to the Factory, and, as such, to the Factory's Container. This means that Container will never
/// go out of scope as long as this property wrapper exists.
@propertyWrapper public struct LazyInjected<T> {

    private var factory: Factory<T>
    private var dependency: T!
    private var initialize = true

    /// Initializes the property wrapper. The dependency isn't resolved until the wrapped value is accessed for the first time.
    /// - Parameter keyPath: KeyPath to a Factory on the default Container.
    public init(_ keyPath: KeyPath<Container, Factory<T>>) {
        self.factory = Container.shared[keyPath: keyPath]
    }

    /// Initializes the property wrapper. The dependency isn't resolved until the wrapped value is accessed for the first time.
    /// - Parameter keyPath: KeyPath to a Factory on the specfied Container.
    public init<C:SharedContainer>(_ keyPath: KeyPath<C, Factory<T>>) {
        self.factory = C.shared[keyPath: keyPath]
    }

    /// Manages the wrapped dependency, which is resolved when this value is accessed for the first time.
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

    /// Unwraps the property wrapper granting access to the resolve/reset function.
    public var projectedValue: LazyInjected<T> {
        get { return self }
        mutating set { self = newValue }
    }

    /// Allows the user to force a Factory resolution.
    public mutating func resolve(reset options: FactoryResetOptions = .none) {
        factory.reset(options)
        dependency = factory()
        initialize = false
    }
}

/// Convenience property wrapper takes a factory and resolves an instance of the desired type the first time the wrapped value is requested. This
/// wrapper maintains a weak reference to the object in question, so it must exist elsewhere.
///
/// Note that WeakLazyInjected maintains a reference to the Factory, and, as such, to the Factory's Container. This means that Container will never
/// go out of scope as long as this property wrapper exists.
@propertyWrapper public struct WeakLazyInjected<T> {

    private var factory: Factory<T>
    private weak var dependency: AnyObject?
    private var initialize = true

    /// Initializes the property wrapper. The dependency isn't resolved until the wrapped value is accessed for the first time.
    /// - Parameter keyPath: KeyPath to a Factory on the default Container.
    public init(_ keyPath: KeyPath<Container, Factory<T>>) {
        self.factory = Container.shared[keyPath: keyPath]
    }

    /// Initializes the property wrapper. The dependency isn't resolved until the wrapped value is accessed for the first time.
    /// - Parameter keyPath: KeyPath to a Factory on the specfied Container.
    public init<C:SharedContainer>(_ keyPath: KeyPath<C, Factory<T>>) {
        self.factory = C.shared[keyPath: keyPath]
    }

    /// Manages the wrapped dependency, which is resolved when this value is accessed for the first time.
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

    /// Unwraps the property wrapper granting access to the resolve/reset function.
    public var projectedValue: WeakLazyInjected<T> {
        get { return self }
        mutating set { self = newValue }
    }

    /// Allows the user to force a Factory resolution.
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

// MARK: - Internal Variables

/// Master recursive lock
private var globalRecursiveLock = NSRecursiveLock()

/// Master graph resolution depth counter
private var globalGraphResolutionDepth = 0

#if DEBUG
/// Internal array used to check for circular dependency cycles
private var globalDependencyChain: [String] = []
#endif

// MARK: - Internal Protocols and Types

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

// Internal Factory type
internal protocol AnyFactory {
}

internal struct TypedFactory<T>: AnyFactory {
    let factory: () -> T
}

/// Internal box protocol for scope functionality
internal protocol AnyBox {
    var scopeID: UUID { get }
}

/// Strong box for strong references to a type
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

/// Defines factory providers for containers
// extension SharedContainer {
    //    /// Defines the default factory scope builder for containers
    //    public var scope: FactoryBuilder {
    //        FactoryBuilder(container: self)
    //    }
    //    /// Defines the default static factory scope builder for containers
    //    public static var scope: FactoryBuilder {
    //        FactoryBuilder(container: shared)
    //    }
    //    public static var factory: FactoryBuilder {
    //        FactoryBuilder(container: shared)
    //    }
    //    public var factory: FactoryBuilder {
    //        FactoryBuilder(container: self)
    //    }
// }

//// MARK: Container Factory Builders
//
///// Wraps a container and provides a base for Factory scope builder functionality.
//public struct FactoryBuilder {
//    fileprivate let container: SharedContainer
//}
//
///// Factory scope builders
//extension FactoryBuilder {
//    /// Helper function to return a Factory bound to the current container and with .cached scope.
//    public func cached<T>(key: String = #function, _ factory: @escaping () -> T) -> Factory<T> {
//        Factory(container: container, scope: .cached, key: key, factory)
//    }
//    /// Helper function to return a Factory bound to the current container and with a custom scope.
//    public func custom<T>(_ scope: Scope, key: String = #function, _ factory: @escaping () -> T) -> Factory<T> {
//        Factory(container: container, scope: scope, key: key, factory)
//    }
//    /// Helper function to return a Factory bound to the current container and with .graph scope.
//    public func graph<T>(key: String = #function, _ factory: @escaping () -> T) -> Factory<T> {
//        Factory(container: container, scope: .graph, key: key, factory)
//    }
//    /// Helper function to return a Factory bound to the current container and with .shared scope.
//    public func shared<T>(key: String = #function, _ factory: @escaping () -> T) -> Factory<T> {
//        Factory(container: container, scope: .shared, key: key, factory)
//    }
//    /// Helper function to return a Factory bound to the current container and with .singleton scope.
//    public func singleton<T>(key: String = #function, _ factory: @escaping () -> T) -> Factory<T> {
//        Factory(container: container, scope: .singleton, key: key, factory)
//    }
//    /// Helper function to return a Factory bound to the current container and with .unique scope.
//    public func unique<T>(key: String = #function, _ factory: @escaping () -> T) -> Factory<T> {
//        Factory(container: container, scope: .unique, key: key, factory)
//    }
//}

