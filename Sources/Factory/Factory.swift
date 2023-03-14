//
// Factory.swift
//
// GitHub Repo and Documentation: https://github.com/hmlongco/Factory
//
// Copyright © 2022 Michael Long. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

import Foundation

#if canImport(SwiftUI)
import SwiftUI
#endif

// MARK: - Factory

/// A Factory manages the dependency injection process for a specific object or service.
///
/// It's used to produce an object of the desired type when required. This may be a brand new instance or Factory may
/// return a previously cached value from the specified scope.
///
/// ## Defining a Factory
/// Let's define a Factory that returns an instance of `ServiceType`. To do that we need to extend a Factory `Container` and within
/// that container we define a new computed variable of type `Factory<ServiceType>`. The type must be explicitly defined, and is usually a
/// protocol to which the returned dependency conforms.
/// ```swift
/// extension Container {
///     var service: Factory<ServiceType> {
///         Factory(self) { MyService() }
///     }
/// }
/// ```
/// Inside the computed variable we define our Factory, passing it a reference to the enclosing container. We also provide it with
/// a closure that creates an instance of our dependency when required. That Factory is then returned to the caller, usually to be evaluated
/// (see `callAsFunction()` below). Every time we resolve this factory we'll get a new, unique instance of our object.
///
/// Factory also provides a bit of syntactic sugar that lets us do the same thing in a more convenient form,
/// ```swift
/// extension Container {
///     var service: Factory<ServiceType> {
///         self { MyService() }
///     }
/// }
/// ```
///
/// ## Transient
/// If you're concerned about building Factory's on the fly, don't be. Like SwiftUI Views, Factory structs and modifiers
/// are lightweight and transitory. They're created when needed and then immediately discarded once their purpose has
/// been served.
///
/// Other operations exist for Factory. See ``FactoryModifying``.
public struct Factory<T>: FactoryModifying {

    /// Public initializer creates a Factory capable of managing dependencies of the desired type.
    ///
    /// - Parameters:
    ///   - container: The bound container that manages registrations and scope caching for this Factory. The scope helper functions bind the
    ///   current container as well defining the scope.
    ///   - key: Hidden value used to differentiate different instances of the same type in the same container.
    ///   - factory: A factory closure that produces an object of the desired type when required.
    public init(_ container: ManagedContainer, key: String = #function, _ factory: @escaping () -> T) {
        self.registration = FactoryRegistration<Void,T>(id: "\(container.self).\(key)", container: container, factory: factory)
    }

    /// Evaluates the factory and returns an object or service of the desired type. The resolved instance may be brand new or Factory may
    /// return a cached value from the specified scope.
    ///
    /// To resolve the Factory  one simply calls the Factory as a function. Here we use the `shared` container that's provided for each
    /// and every container type.
    /// ```swift
    /// let service = Container.shared.service()
    /// ```
    /// The resolved instance may be brand new or Factory may return a cached value from the specified ``Scope``.
    ///
    /// If you're passing an instance of a container around to your views or view models, just call it directly.
    /// ```swift
    /// let service = container.service()
    /// ```
    /// Finally, you can also use the @Injected property wrapper and specify a keyPaths to the desired dependency.
    /// ```swift
    /// @Injected(\.service) var service: ServiceType
    /// ```
    /// Unless otherwise specified, the @Injected property wrapper looks for dependencies in the standard shared container provided by Factory,
    /// so the above example is functionally identical to the `Container.shared.service()` example shown earlier. Here's one pointing to
    /// your own container.
    /// ```swift
    /// @Injected(\MyCustomContainer.service) var service: ServiceType
    /// ```
    /// - Returns: An object or service of the desired type.
    public func callAsFunction() -> T {
        registration.resolve(with: ())
    }

    /// Registers a new factory closure capable of producing an object or service of the desired type.
    ///
    /// This factory overrides the original factory closure and clears the associated scope so that the next time this factory is resolved
    /// Factory will evaluate the new closure and return an instance of the newly registered object instead.
    ///
    /// Here's an example of registering a new Factory closure.
    /// ```swift
    /// container.service.register {
    ///     SomeService()
    /// }
    /// ```
    /// This is how default functionality is overridden in order to change the nature of the system at runtime, and is the primary mechanism
    /// used to provide mocks and testing doubles.
    ///
    /// Registration "overrides" are stored in the associated container. If the container ever goes our of scope, so
    /// will all of its registrations.
    ///
    /// The original factory closure is preserved, and may be restored by resetting the Factory to its original state.
    ///
    /// - Parameters:
    ///  - factory: A new factory closure that produces an object of the desired type when needed.
    /// Allows updating registered factory and scope.
    @discardableResult
    public func register(factory: @escaping () -> T) -> Self {
        registration.register(factory)
        return self
    }

    /// Internal parameters for this Factory including id, container, the factory closure itself, the scope,
    /// and others.
    public var registration: FactoryRegistration<Void,T>

}

// MARK: - ParameterFactory

/// Factory capable of taking parameters at runtime
///
/// Like it or not, some services require one or more parameters to be passed to them in order to be initialized correctly. In that case use `ParameterFactory`.
///
/// We define a ParameterFactory exactly as we do a normal factory with two exceptions: we need to specify the
/// parameter type, and we need to consume the passed parameter in our factory closure.
/// ```swift
/// extension Container {
///     var parameterService: ParameterFactory<Int, MyServiceType> {
///        self { ParameterService(value: $0) }
///     }
/// }
/// ```
/// Resolving it is straightforward. Just pass the parameter to the Factory.
/// ```Swift
/// let myService = Container.shared.parameterService(n)
/// ```
/// One caveat is that you can't use the `@Injected` property wrapper with `ParameterFactory` as there's no way to get
/// the needed parameters to the property wrapper before the wrapper is initialized. That being the case, you'll
/// probably need to reference the container directly and do something similar to the following.
///  ```swift
///  class MyClass {
///      var myService: MyServiceType
///      init(_ n: Int) {
///          myService = Container.shared.parameterService(n)
///      }
///  }
/// ```
/// If you need to pass more than one parameter just use a tuple, dictionary, or struct.
/// ```swift
/// var tupleService: ParameterFactory<(Int, Int), MultipleParameterService> {
///     self { (a, b) in
///         MultipleParameterService(a: a, b: b)
///     }
/// }
/// ```
/// Finally, if you define a scope keep in mind that the first argument passed will be used to create the dependency
/// and *that* dependency will be cached. Since the cached object will be returned from now on any arguments passed in
/// later requests will be ignored until the factory or scope is reset.
public struct ParameterFactory<P,T>: FactoryModifying {

    /// Public initializer creates a factory capable of taking parameters at runtime.
    /// ```swift
    /// var parameterService: ParameterFactory<Int, ParameterService> {
    ///     self { ParameterService(value: $0) }
    /// }
    /// ```
    /// - Parameters:
    ///   - container: The bound container that manages registrations and scope caching for this Factory. The scope helper functions bind the
    ///   current container as well defining the scope.
    ///   - key: Hidden value used to differentiate different instances of the same type in the same container.
    ///   - factory: A factory closure that produces an object of the desired type when required.
    public init(_ container: ManagedContainer, key: String = #function, _ factory: @escaping (P) -> T) {
        self.registration = FactoryRegistration<P,T>(id: "\(container.self).\(key)", container: container, factory: factory)
    }

    /// Resolves a factory capable of taking parameters at runtime.
    /// ```swift
    /// let service = container.parameterService(16)
    /// ```
    public func callAsFunction(_ parameters: P) -> T {
        registration.resolve(with: parameters)
    }

    /// Registers a new factory capable of taking parameters at runtime.
    /// ```swift
    /// container.parameterService.register { n in
    ///     ParameterService(value: n)
    /// }
    /// ```
    /// - Parameters:
    ///  - factory: A new factory closure that produces an object of the desired type when needed.
    @discardableResult
    public func register(factory: @escaping (P) -> T) -> Self {
        registration.register(factory)
        return self
    }

    /// Required registration
    public var registration: FactoryRegistration<P,T>

}

// MARK: - Factory Modifiers

/// Public protocol with functionality common to all Factory's. Used to add scope and decorator modifiers to Factory.
public protocol FactoryModifying {
    /// The parameter type of the Factory, if any. Will be `Void` on the standard Factory.
    associatedtype P
    /// The return type of the Factory's dependency.
    associatedtype T
    /// Internal information that desribes this Factory.
    var registration: FactoryRegistration<P,T> { get set }
}

// FactoryModifying Scope Functionality

extension FactoryModifying {
    /// Defines a dependency scope for this Factory. See ``Scope``.
    /// ```swift
    /// var service: Factory<ServiceType> {
    ///     self { MyService() }
    ///         .scope(.session)
    /// }
    /// ```
    @discardableResult
    public func scope(_ scope: Scope) -> Self {
        registration.scope(scope)
        return self
    }
    /// Syntactic sugar defines this Factory's dependency scope to be cached. See ``Scope/Cached-swift.class``.
    /// ```swift
    /// var service: Factory<ServiceType> {
    ///     factory { MyService() }
    ///         .cached
    /// }
    /// ```
    @inlinable public var cached: Self {
        scope(.cached)
    }
    /// Syntactic sugar defines this Factory's dependency scope to be graph. See ``Scope/Graph-swift.class``.
    /// ```swift
    /// var service: Factory<ServiceType> {
    ///     factory { MyService() }
    ///         .graph
    /// }
    /// ```
    @inlinable public var graph: Self {
        scope(.graph)
    }
    /// Syntactic sugar defines this Factory's dependency scope to be shared. See ``Scope/Graph-swift.class``.
    /// ```swift
    /// var service: Factory<ServiceType> {
    ///     self { MyService() }
    ///         .shared
    /// }
    /// ```
    @inlinable public var shared: Self {
        scope(.shared)
    }
    /// Syntactic sugar defines this Factory's dependency scope to be singleton. See ``Scope/Singleton-swift.class``.
    /// ```swift
    /// var service: Factory<ServiceType> {
    ///     self { MyService() }
    ///         .singleton
    /// }
    /// ```
    @inlinable public var singleton: Self {
        scope(.singleton)
    }
    /// Syntactic sugar defines defines unique scope. See ``Scope``.
    /// ```swift
    /// var service: Factory<ServiceType> {
    ///     self { MyService() }
    ///         .unique
    /// }
    /// ```
    /// While you can add the modifier, Factory's are unique by default.
    @inlinable public var unique: Self {
        scope(.unique)
    }
}

// FactoryModifying Decorator Functionality

extension FactoryModifying {
    /// Adds a factory specific decorator. The decorator will be *always* be called with the resolved dependency
    /// for further examination or manipulation.
    ///
    /// This includes previously created items that may have been cached by a scope.
    /// ```swift
    /// var decoratedService: Factory<ParentChildService> {
    ///    self { ParentChildService() }
    ///        .decorated {
    ///            $0.child.parent = $0
    ///        }
    /// }
    /// ```
    /// As shown, decorator can come in handy when you need to perform some operation or manipulation after the fact.
    @discardableResult
    public func decorator(_ decorator: @escaping (_ instance: T) -> Void) -> Self {
        registration.decorator(decorator)
        return self
    }
}

// FactoryModifying Context Functionality

extension FactoryModifying {
    /// Registers a factory closure to be used only when running in a specific context.
    ///
    /// A context might be be when running in SwiftUI preview mode, or when running unit tests.
    ///
    /// See <doc:Contexts>
    @discardableResult
    public func context(_ context: FactoryContext, factory: @escaping (P) -> T) -> Self {
        switch context {
        case .arg:
            registration.context(context, id: registration.id, factory: factory)
        default:
            #if DEBUG
            registration.context(context, id: registration.id, factory: factory)
            #endif
        }
        return self
    }
    /// Factory builder shortcut for context(.arg) { .. }
    @discardableResult
    public func onArg(_ argument: String, factory: @escaping (P) -> T) -> Self {
        context(.arg(argument), factory: factory)
    }
    /// Factory builder shortcut for context(.preview) { .. }
    @discardableResult
    public func onPreview(factory: @escaping (P) -> T) -> Self {
        context(.preview, factory: factory)
    }
    /// Factory builder shortcut for context(.test) { .. }
    @discardableResult
    public func onTest(factory: @escaping (P) -> T) -> Self {
        context(.test, factory: factory)
    }
    /// Factory builder shortcut for context(.debug) { .. }
    @discardableResult
    public func onDebug(factory: @escaping (P) -> T) -> Self {
        context(.debug, factory: factory)
    }
    /// Factory builder shortcut for context(.simulator) { .. }
    @discardableResult
    public func onSimulator(factory: @escaping (P) -> T) -> Self {
        context(.simulator, factory: factory)
    }
    /// Factory builder shortcut for context(.device) { .. }
    @discardableResult
    public func onDevice(factory: @escaping (P) -> T) -> Self {
        context(.device, factory: factory)
    }
}

// FactoryModifying Once Functionality

extension FactoryModifying {
    /// Adds ability to mutate Factory on first instantiation only.
    @discardableResult
    public func once() -> Self {
        registration.options { options in
            options.once = true
        }
        var mutable = self
        mutable.registration.once = true
        return mutable
    }
}

// FactoryModifying Common Functionality

extension FactoryModifying {
    /// Resets the Factory's behavior to its original state, removing any registrations and clearing any cached items from the specified scope.
    /// - Parameter options: options description
    public func reset(_ options: FactoryResetOptions = .all) {
        registration.reset(options: options)
    }
}

// FactoryModifying Deprecated Functionality

extension FactoryModifying {
    /// Allows registering new factory closure and updating scope used after the fact.
    /// - Parameters:
    ///  - scope: Optional parameter that lets the registration redefine the scope used for this dependency.
    ///  - factory: A new factory closure that produces an object of the desired type when needed.
    @available(*, deprecated, message: "Use container.service.scope(.cached).register { Service() } instead")
    @discardableResult
    public func register(scope: Scope?, factory: @escaping (P) -> T) -> Self {
        registration.register(factory)
        registration.scope(scope)
        return self
    }
}

// MARK: - Container

/// This is the default Container provided for your convenience by Factory.
///
/// Containers are used by Factory to manage object creation, object resolution, and object lifecycles in general.
/// ```swift
/// extension Container {
///     var service: Factory<ServiceType> {
///         self { MyService() }
///     }
/// }
/// ```
///  Registrations and scope caches will persist as long as the associated container remains in scope.
///
///  See <doc:Containers> for more information.
public final class Container: SharedContainer {
    /// Define the default shared container.
    public static var shared = Container()
    /// Define the container's manager.
    public var manager: ContainerManager = ContainerManager()
    /// Public initializer
    public init() {}
}

// MARK: - SharedContainer

/// SharedContainer defines the protocol all Containers must adopt if they want to support Service Locator style injection or support any of the injection property wrappers.
///
/// Here's an example of reaching out to a Conatiner's shared instance for dependency resolution.
/// ```swift
/// class ContentViewModel {
///     let service: MyServiceType = Container.shared.service()
/// }
/// ```
/// The default ``Container`` provided is a SharedContainer. It can be used in both roles as needed.
///
///  See <doc:Containers> for more information.
public protocol SharedContainer: ManagedContainer {
    /// Defines a single "shared" container for that container type.
    ///
    /// This container is used by the various @Injected property wrappers to resolve the keyPath to a given Factory. Care should be taken in
    /// mixed environments where you're passing container references AND using the @Injected property wrappers.
    static var shared: Self { get }
}

// MARK: - ManagedContainer

/// ManagedContainer defines the core protocol all Containers must adopt.
///
/// If a container only supports ManagedContainer then the container must be instantiated and passed as an instance. Here's
/// an example of passing such a container to a view model for dependency resolution.
/// ```swift
/// class ContentViewModel {
///     let service: MyServiceType
///     init(container: Container) {
///         service = container.service()
///     }
/// }
/// ```
///  See <doc:Containers> for more information.
public protocol ManagedContainer: AnyObject {
    /// Defines the ContainerManager used to manage registrations, resolutions, and scope caching for that container. Encapsulating the code in
    /// this fashion makes creating and using your own custom containers much simpler.
    var manager: ContainerManager { get }
}

/// Defines the default factory helpers for containers
extension ManagedContainer {
    /// Syntactic sugar allows container to create a properly bound Factory.
    @inlinable public func callAsFunction<T>(key: String = #function, _ factory: @escaping () -> T) -> Factory<T> {
        Factory(self, key: key, factory)
    }
    /// Syntactic sugar allows container to create a properly bound ParameterFactory.
    @inlinable public func callAsFunction<P,T>(key: String = #function, _ factory: @escaping (P) -> T) -> ParameterFactory<P,T> {
        ParameterFactory(self, key: key, factory)
    }
    /// Defines a decorator for the container. This decorator will see every dependency resolved by this container.
    public func decorator(_ decorator: ((Any) -> ())?) {
        manager.decorator = decorator
    }
    /// Defines a with function to allow container transformation on assignment.
    @discardableResult
    public func with(_ transform: (Self) -> Void) -> Self {
        transform(self)
        return self
    }
}

// MARK: - ContainerManager

/// ContainerManager manages the registration and scope caching storage mechanisms for a given container.
///
/// Every container requires a ContainerManager.
///
/// ContainerManager also implements several functions tha can be used to reset the container
/// to a pristine state, as well as push/pop methods that can save and restore the current state.
///
/// Those functions are designed primarily for testing.
public class ContainerManager {

    /// Public initializer
    public init() {}

    #if DEBUG
    /// Public variable exposing dependency chain test maximum
    public var dependencyChainTestMax: Int = 10

    /// Public var enabling factory resolution trace statements in debug mode for ALL containers.
    public var trace: Bool {
        get { globalTraceFlag }
        set { globalTraceFlag = newValue }
    }

    /// Public access to logging facility in debug mode for ALL containers.
    public var logger: (String) -> Void {
        get { globalLogger }
        set { globalLogger = newValue }
    }
    #endif

    /// Alias for Factory registration map.
    internal typealias FactoryMap = [String:AnyFactory]
    /// Alias for Factory options map.
    internal typealias FactoryOptionsMap = [String:FactoryOptions]
    /// Alias for Factory once set.
    internal typealias FactoryOnceSet = Set<String>

    /// Internal closure decorates all factory resolutions for this container.
    internal var decorator: ((Any) -> ())?
    /// Flag indicating autoregistration check needs to be performed and executed if needed.
    internal var autoRegistrationCheckNeeded = true
    /// Updated registrations for Factory's.
    internal lazy var registrations: FactoryMap = .init(minimumCapacity: 32)
    /// Updated options for Factory's.
    internal lazy var options: FactoryOptionsMap = .init(minimumCapacity: 32)
    /// Scope cache for Factory's managed by this container.
    internal lazy var cache: Scope.Cache = Scope.Cache()
    /// Push/Pop stack for registrations, options, cache, and so on.
    internal lazy var stack: [(FactoryMap, FactoryOptionsMap, Scope.Cache.CacheMap, Bool)] = []

}

extension ContainerManager {

    /// Resets the Container to its original state, removing all registrations and clearing all scope caches.
    public func reset(options: FactoryResetOptions = .all) {
        guard options != .none else {
            return
        }
        defer { globalRecursiveLock.unlock()  }
        globalRecursiveLock.lock()
        switch options {
        case .registration:
            self.registrations.removeAll(keepingCapacity: true)
        case .context:
            for (key, option) in self.options {
                var mutable = option
                mutable.argumentContexts = [:]
                mutable.contexts = [:]
                self.options[key] = mutable
            }
        case .scope:
            self.cache.reset()
        default:
            self.registrations.removeAll(keepingCapacity: true)
            self.options.removeAll(keepingCapacity: true)
            self.cache.reset()
            self.autoRegistrationCheckNeeded = true
        }
    }

    /// Clears any cached values associated with a specific scope, leaving the other scope caches intact.
    public func reset(scope: Scope) {
        defer { globalRecursiveLock.unlock()  }
        globalRecursiveLock.lock()
        cache.reset(scopeID: scope.scopeID)
    }

    /// Test function pushes the current registration and cache states
    public func push() {
        defer { globalRecursiveLock.unlock()  }
        globalRecursiveLock.lock()
        stack.append((registrations, options, cache.cache, autoRegistrationCheckNeeded))
    }

    /// Test function pops and restores a previously pushed registration and cache state
    public func pop() {
        defer { globalRecursiveLock.unlock()  }
        globalRecursiveLock.lock()
        if let state = stack.popLast() {
            registrations = state.0
            options = state.1
            cache.cache = state.2
            autoRegistrationCheckNeeded = state.3
        }
    }

}

// MARK: - Scope

/// Scopes are used to define the lifetime of resolved dependencies. Factory provides several scope types,
/// including `Singleton`, `Cached`, `Graph`, and `Shared`.
///
/// When a scope is associated with a Factory the first time the dependency is resolved a reference to that object
/// is cached. The next time that Factory is resolved a reference to the originally cached object will be returned.
///
/// That behavior can vary according to the scope type (e.g. Shared or Graph)
/// ```swift
/// extension Container {
///     var service: Factory<ServiceType> {
///         self { MyService() }
///             .singleton
///     }
/// }
/// ```
/// Scopes work hand in hand with Containers to managed object lifecycles. If the container ever goes our of scope, so
/// will all of its cached references.
///
/// If no scope is associated with a given Factory then the scope is considered to be unique and a new instance
/// of the dependency will be created each and every time that factory is resolved.
public class Scope {

    fileprivate init() {}

    /// Internal function returns cached value if it exists. Otherwise it creates a new instance and caches that value for later reference.
    internal func resolve<T>(using cache: Cache, id: String, factory: () -> T) -> T {
        if let cached: T = unboxed(box: cache.value(forKey: id)) {
            return cached
        }
        let instance = factory()
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

    /// A reference to the default cached scope manager.
    public static let cached = Cached()
    /// Defines a cached scope. The same instance will be returned by the factory until the cache is reset.
    public final class Cached: Scope {
        public override init() {
            super.init()
        }
    }

    /// A reference to the default graph scope manager.
    public static let graph = Graph()
    /// Defines the graph scope. A single instance of a given type will be returned during a given resolution cycle.
    ///
    /// This scope is managed and cleared by the main resolution function at the end of each resolution cycle.
    public final class Graph: Scope {
        public override init() {
            super.init()
        }
        internal override func resolve<T>(using cache: Cache, id: String, factory: () -> T) -> T {
            // ignores passed cache
            return super.resolve(using: self.cache, id: id, factory: factory)
        }
        /// Private shared cache
        internal var cache = Cache()
    }

    /// A reference to the default shared scope manager.
    public static let shared = Shared()
    /// Defines a shared (weak) scope. The same instance will be returned by the factory as long as someone maintains a strong reference.
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

    /// A reference to the default singleton scope manager.
    public static let singleton = Singleton()
    /// Defines the singleton scope. The same instance will always be returned by the factory.
    public final class Singleton: Scope {
        public override init() {
            super.init()
        }
    }

    /// A reference to the default unique scope.
    ///
    /// If no scope cache is specified then Factory is running in unique more.
    public static let unique = Unique()
    /// Defines the unique scope. A new instance of a given type will be returned on evver resolution cycle.
    public final class Unique: Scope {
        public override init() {
            super.init()
        }
        internal override func resolve<T>(using cache: Cache, id: String, factory: () -> T) -> T {
            factory()
        }
    }

}

extension Scope {
    /// Internal class that manages scope caching for containers and scopes.
    internal class Cache {
        typealias CacheMap = [String:AnyBox]
        /// Internal support functions
        @inlinable func value(forKey key: String) -> AnyBox? {
            cache[key]
        }
        @inlinable func set(value: AnyBox, forKey key: String)  {
            cache[key] = value
        }
        @inlinable func removeValue(forKey key: String) {
            cache.removeValue(forKey: key)
        }
        internal func reset(scopeID: UUID) {
            cache = cache.filter { $1.scopeID != scopeID }
        }
        /// Internal function to clear cache if needed
        @inlinable func reset() {
            if !cache.isEmpty {
                cache.removeAll(keepingCapacity: true)
            }
        }
        var cache: CacheMap = .init(minimumCapacity: 32)
        #if DEBUG
        internal var isEmpty: Bool {
            cache.isEmpty
        }
        #endif
   }
}

// MARK: - Scope Defaults

/// Protocol allows container to specifer a default scope for all managed factories.
///
/// ```swift
/// extension Container: ScopeDefaults {
///     var defaultScope: Scope = .graph
/// }
/// ```
/// Implemented as protocol since attempting to set via AutoRegister would be too late for first factory resolved.
public protocol ScopeDefaults {
    /// Variable allows container to specifer a default scope other than unique for all managed factories.
    var defaultScope: Scope { get }
}

// MARK: - Automatic Registrations

/// Adds an registration "hook" to a `Container`.
///
/// Add this protocol to a container to support first-time registration of needed dependencies prior to first resolution
/// of a dependency on that container.
/// ```swift
/// extension Container: AutoRegistering {
///     func autoRegister() {
///         someService.register {
///             CrossModuleService()
///         }
///     }
/// }
///```
/// The `autoRegister` function is called on each instantiated container prior to
/// the first resolution of a Factory on that container.
///
/// > Warning: Calling `container.manager.reset(options: .all)` restores the container to it's initial state
/// and autoRegister will be called again if it exists.
public protocol AutoRegistering {
    /// User provided function that supports first-time registration of needed dependencies prior to first resolution
    /// of a dependency on that container.
    func autoRegister()
}

// MARK: - Property wrappers

#if swift(>=5.1)

/// Convenience property wrapper takes a factory and resolves an instance of the desired type.
///
/// Property wrappers implement an annotation pattern to resolving dependencies, similar to using
/// EnvironmentObject in SwiftUI.
/// ```swift
/// class MyViewModel {
///    @Injected(\.myService) var service
///    @Injected(\MyCustomContainer.myService) var service
/// }
/// ```
/// The provided keypath resolves to a Factory definition on the `shared` container required for each Container type.
/// The short version of the keyPath resolves to the default container, while the expanded version
/// allows you to point an instance on your own customer container type.
///
/// > Note: The @Injected property wrapper will be resolved on **intialization**. In the above example
/// the referenced dependencies will be acquired when the parent class is created.
@propertyWrapper public struct Injected<T> {

    private var reference: BoxedFactoryReference
    private var dependency: T

    /// Initializes the property wrapper. The dependency is resolved on initialization.
    /// - Parameter keyPath: KeyPath to a Factory on the default Container.
    public init(_ keyPath: KeyPath<Container, Factory<T>>) {
        self.reference = FactoryReference<Container, T>(keypath: keyPath)
        self.dependency = Container.shared[keyPath: keyPath]()
    }

    /// Initializes the property wrapper. The dependency is resolved on initialization.
    /// - Parameter keyPath: KeyPath to a Factory on the specified Container.
    public init<C:SharedContainer>(_ keyPath: KeyPath<C, Factory<T>>) {
        self.reference = FactoryReference<C, T>(keypath: keyPath)
        self.dependency = C.shared[keyPath: keyPath]()
    }

    /// Manages the wrapped dependency.
    public var wrappedValue: T {
        get { return dependency }
        mutating set { dependency = newValue }
    }

    /// Unwraps the property wrapper granting access to the resolve/reset function.
    public var projectedValue: Injected<T> {
        get { return self }
        mutating set { self = newValue }
    }

    /// Grants access to the internal Factory.
    public var factory: Factory<T> {
        reference.factory()
    }

    /// Allows the user to force a Factory resolution at their descretion.
    public mutating func resolve(reset options: FactoryResetOptions = .none) {
        factory.reset(options)
        dependency = factory()
    }
}

/// Convenience property wrapper takes a factory and resolves an instance of the desired type the first time the wrapped value is requested.
///
/// Property wrappers implement an annotation pattern to resolving dependencies, similar to using
/// EnvironmentObject in SwiftUI.
/// ```swift
/// class MyViewModel {
///    @LazyInjected(\.myService) var service
///    @LazyInjected(\MyCustomContainer.myService) var service
/// }
/// ```
/// The provided keypath resolves to a Factory definition on the `shared` container required for each Container type.
/// The short version of the keyPath resolves to the default container, while the expanded version
/// allows you to point an instance on your own customer container type.
///
/// > Note: Lazy injection is resolved the first time the dependency is referenced by the code, and **not** on initilization.
@propertyWrapper public struct LazyInjected<T> {

    private var reference: BoxedFactoryReference
    private var dependency: T!
    private var initialize = true

    /// Initializes the property wrapper. The dependency isn't resolved until the wrapped value is accessed for the first time.
    /// - Parameter keyPath: KeyPath to a Factory on the default Container.
    public init(_ keyPath: KeyPath<Container, Factory<T>>) {
        self.reference = FactoryReference<Container, T>(keypath: keyPath)
    }

    /// Initializes the property wrapper. The dependency isn't resolved until the wrapped value is accessed for the first time.
    /// - Parameter keyPath: KeyPath to a Factory on the specified Container.
    public init<C:SharedContainer>(_ keyPath: KeyPath<C, Factory<T>>) {
        self.reference = FactoryReference<C, T>(keypath: keyPath)
    }

    /// Manages the wrapped dependency, which is resolved when this value is accessed for the first time.
    public var wrappedValue: T {
        mutating get {
            defer { globalRecursiveLock.unlock()  }
            globalRecursiveLock.lock()
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

    /// Grants access to the internal Factory.
    public var factory: Factory<T> {
        reference.factory()
    }

    /// Allows the user to force a Factory resolution at their descretion.
    public mutating func resolve(reset options: FactoryResetOptions = .none) {
        factory.reset(options)
        dependency = factory()
        initialize = false
    }
}

/// Convenience property wrapper takes a factory and resolves an instance of the desired type the first time the wrapped value is requested.
///
/// This wrapper maintains a weak reference to the object in question, so it must exist elsewhere.t
/// It's useful for delegate patterns and parent/child relationships.
///
/// Property wrappers implement an annotation pattern to resolving dependencies, similar to using
/// EnvironmentObject in SwiftUI.
///
/// ```swift
/// class MyViewModel {
///    @LazyInjected(\.myService) var service
///    @LazyInjected(\MyCustomContainer.myService) var service
/// }
/// ```
/// The provided keypath resolves to a Factory definition on the `shared` container required for each Container type.
/// The short version of the keyPath resolves to the default container, while the expanded version
/// allows you to point an instance on your own customer container type.
///
/// > Note: Lazy injection is resolved the first time the dependency is referenced by the code, **not** on initilization.
@propertyWrapper public struct WeakLazyInjected<T> {

    private var reference: BoxedFactoryReference
    private weak var dependency: AnyObject?
    private var initialize = true

    /// Initializes the property wrapper. The dependency isn't resolved until the wrapped value is accessed for the first time.
    /// - Parameter keyPath: KeyPath to a Factory on the default Container.
    public init(_ keyPath: KeyPath<Container, Factory<T>>) {
        self.reference = FactoryReference<Container, T>(keypath: keyPath)
    }

    /// Initializes the property wrapper. The dependency isn't resolved until the wrapped value is accessed for the first time.
    /// - Parameter keyPath: KeyPath to a Factory on the specified Container.
    public init<C:SharedContainer>(_ keyPath: KeyPath<C, Factory<T>>) {
        self.reference = FactoryReference<C, T>(keypath: keyPath)
    }

    /// Manages the wrapped dependency, which is resolved when this value is accessed for the first time.
    public var wrappedValue: T? {
        mutating get {
            defer { globalRecursiveLock.unlock()  }
            globalRecursiveLock.lock()
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

    /// Grants access to the internal Factory.
    public var factory: Factory<T> {
        reference.factory()
    }

    /// Allows the user to force a Factory resolution at their descretion.
    public mutating func resolve(reset options: FactoryResetOptions = .none) {
        factory.reset(options)
        dependency = factory() as AnyObject
        initialize = false
    }
}

#if os(iOS) || os(macOS) || os(tvOS) || os(watchOS)
/// Immediate injection property wrapper for SwiftUI ObservableObjects.
///
/// This wrapper is meant for use in SwiftUI Views and exposes bindable objects similar to that of SwiftUI @StateObject
/// and @EnvironmentObject.
///
/// Like the other Injected property wrappers, InjectedObject wraps obtains the dependency from the Factory keypath
/// and provides it to a wrapped instance of StateObject. Updating object state will trigger view update.
/// ```swift
/// struct ContentView: View {
///     @InjectedObject(\.contentViewModel) var model
///     var body: some View {
///         ...
///     }
/// }
/// ```
/// ContentViewModel must, of course, be of type ObservableObject and is registered like any other service
/// or dependency.
/// ```swift
/// extension Container {
///     var contentViewModel: Factory<ContentViewModel> {
///         self { ContentViewModel() }
///     }
/// }
/// ```
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
@frozen @propertyWrapper public struct InjectedObject<T>: DynamicProperty where T: ObservableObject {
    @StateObject fileprivate var dependency: T
    /// Initializes the property wrapper. The dependency is resolved on initialization.
    /// - Parameter keyPath: KeyPath to a Factory on the default Container.
    public init(_ keyPath: KeyPath<Container, Factory<T>>) {
        self._dependency = StateObject(wrappedValue: Container.shared[keyPath: keyPath]())
    }
    /// Initializes the property wrapper. The dependency is resolved on initialization.
    /// - Parameter keyPath: KeyPath to a Factory on the specified Container.
    public init<C:SharedContainer>(_ keyPath: KeyPath<C, Factory<T>>) {
        self._dependency = StateObject(wrappedValue: C.shared[keyPath: keyPath]())
    }
    /// Manages the wrapped dependency.
    @MainActor public var wrappedValue: T {
        get { dependency }
    }
    /// Manages the wrapped dependency.
    @MainActor public var projectedValue: ObservedObject<T>.Wrapper {
        return $dependency
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension InjectedObject {
    /// Simple initializer with passed parameter bypassing injection.
    ///
    /// Still has issue with attempting to pass dependency into existing view when existing InjectedObject has keyPath.
    /// https://forums.swift.org/t/allow-property-wrappers-with-multiple-arguments-to-defer-initialization-when-wrappedvalue-is-not-specified
    public init(_ wrappedValue: T) {
        self._dependency = StateObject(wrappedValue: wrappedValue)
    }
}
#endif

/// Boxed wrapper to provide a Factory when asked
internal protocol BoxedFactoryReference {
    func factory<T>() -> Factory<T>
}

/// Helps resolve a reference to an injected factory's shared container without actually storing a Factory along
/// with its hard, reference-counted pointer to that container.
internal struct FactoryReference<C: SharedContainer, T>: BoxedFactoryReference {
    /// The stored factory keypath on the container
    let keypath: KeyPath<C, Factory<T>>
    /// Resolves the current shared container on the given type and returns the Factory referenced by the keyPath.
    /// Note that types matched going in, so it's safe to explicitly cast it coming back out.
    func factory<T>() -> Factory<T> {
        C.shared[keyPath: keypath] as! Factory<T>
    }
}

#endif

// MARK: - Public Protocols and Types

/// Context types available for special purpose factory registrations.
public enum FactoryContext: Equatable {
    /// Context used when application is launched with a particular argument.
    case arg(String)
    /// Context used when application is running in Xcode Preview mode.
    case preview
    /// Context used when application is running in Xcode Unit Test mode.
    case test
    /// Context used when application is running in Xcode DEBUG mode.
    case debug
    /// Context used when application is running within an Xcode simulator.
    case simulator
    /// Context used when application is running on an actual device.
    case device
}

extension FactoryContext {
    /// Proxy for application arguments.
    internal static var arguments: [String] = ProcessInfo.processInfo.arguments
    /// Proxy check for application running in preview mode.
    internal static var isPreview: Bool = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    /// Proxy check for application running in unit test mode.
    internal static var isTest: Bool = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    /// Proxy check for application running in simulator.
    internal static var isSimulator: Bool = ProcessInfo.processInfo.environment["SIMULATOR_UDID"] != nil
}

/// Reset options for Factory's and Container's
public enum FactoryResetOptions {
    /// Resets registration and scope caches
    case all
    /// Performs no reset actions on this container
    case none
    /// Resets registrations on this container
    case registration
    /// Resets context-based registrations on this container
    case context
    /// Resets all scope caches on this container
    case scope
}

/// Shared registration type for Factory and ParameterFactory. Used internally to manage the registration and resolution process.
public struct FactoryRegistration<P,T> {

    /// Id used to manage registrations and cached values. Usually looks something like "MyApp.Container.service".
    internal var id: String
    /// A strong reference to the container supporting this Factory.
    internal var container: ManagedContainer
    /// Typed factory with scope and factpry.
    internal var factory: (P) -> T
    /// Once flag
    internal var once: Bool = false

    /// Internal calculated value
    internal var defaultScope: Scope? {
        (container as? ScopeDefaults)?.defaultScope
    }

    /// Tnitializer for registration sets passed values and default scope from container manager.
    internal init(id: String, container: ManagedContainer, factory: @escaping (P) -> T) {
        self.id = id
        self.container = container
        self.factory = factory
    }

    /// Support function performs autoRegistrationCheck and returns properly initialized container.
    internal func unsafeCheckecContainer() -> ManagedContainer {
        if container.manager.autoRegistrationCheckNeeded {
            container.manager.autoRegistrationCheckNeeded = false
            (container as? AutoRegistering)?.autoRegister()
        }
        return container
    }

    /// Support function for one-time only option updates
    internal func unsafeCanUpdateOptions() -> Bool {
        let options = container.manager.options[id]
        return options == nil || options?.once == once
    }

    /// Resolves a Factory, returning an instance of the desired type. All roads lead here.
    ///
    /// - Parameter factory: Factory wanting resolution.
    /// - Returns: Instance of the desired type.
    internal func resolve(with parameters: P) -> T {
        defer { globalRecursiveLock.unlock()  }
        globalRecursiveLock.lock()

        let manager = unsafeCheckecContainer().manager
        let options = manager.options[id]
        let scope = options?.scope ?? defaultScope

        var factory: (P) -> T = factoryForCurrentContext(using: options)

        #if DEBUG
        if manager.dependencyChainTestMax > 0 {
            circularDependencyChainCheck(for: String(reflecting: T.self), max: manager.dependencyChainTestMax)
        }

        let traceLevel = globalTraceResolutions.count
        var traceNew = false
        if manager.trace {
            let wrapped = factory
            factory = {
                traceNew = true // detects if new instance created
                return wrapped($0)
            }
            globalTraceResolutions.append("")
        }
        #endif

        globalGraphResolutionDepth += 1
        let instance = scope?.resolve(using: manager.cache, id: id, factory: { factory(parameters) }) ?? factory(parameters)
        globalGraphResolutionDepth -= 1

        if globalGraphResolutionDepth == 0 {
            Scope.graph.cache.reset()
            #if DEBUG
            globalDependencyChainMessages = []
            #endif
        }

        #if DEBUG
        if !globalDependencyChain.isEmpty {
            globalDependencyChain.removeLast()
        }

        if manager.trace {
            let indent = String(repeating: " ", count: globalGraphResolutionDepth * 4)
            let type = type(of: instance)
            let address = Int(bitPattern: ObjectIdentifier(instance as AnyObject))
            let new = traceNew ? "N" : "C"
            let traced = "\(globalGraphResolutionDepth): \(indent)\(id) = \(type) \(new):\(address)"
            globalTraceResolutions[traceLevel] = traced
            if globalGraphResolutionDepth == 0 {
                globalTraceResolutions.forEach { manager.logger($0) }
                globalTraceResolutions = []
            }
        }
        #endif

        if let decorator = options?.decorator as? (T) -> Void {
            decorator(instance)
        }
        manager.decorator?(instance)

        return instance
    }

    func factoryForCurrentContext(using options: FactoryOptions?) -> (P) -> T {
        let manager = container.manager
        if let contexts = options?.argumentContexts, !contexts.isEmpty {
            for arg in FactoryContext.arguments {
                if let found = contexts["arg=\(arg)"] as? TypedFactory<P,T> {
                    return found.factory
                }
            }
        }
        if let contexts = options?.contexts, !contexts.isEmpty {
            #if DEBUG
            if FactoryContext.isPreview, let found = contexts["preview"] as? TypedFactory<P,T> {
                return found.factory
            }
            if FactoryContext.isTest, let found = contexts["test"] as? TypedFactory<P,T> {
                return found.factory
            }
            if FactoryContext.isSimulator, let found = contexts["simulator"] as? TypedFactory<P,T> {
                return found.factory
            }
            #endif
            if !FactoryContext.isSimulator, let found = contexts["device"] as? TypedFactory<P,T> {
                return found.factory
            }
            #if DEBUG
            if let found = contexts["debug"] as? TypedFactory<P,T> {
                return found.factory
            }
            #endif
        }
        if let found = manager.registrations[id] as? TypedFactory<P,T> {
            return found.factory
        }
        return factory
    }

    /// Registers a new factory closure capable of producing an object or service of the desired type. This factory overrides the original factory and
    /// the next time this factory is resolved Factory will evaluate the newly registered factory instead.
    /// - Parameters:
    ///   - id: ID of associated Factory.
    ///   - factory: Factory closure called to create a new instance of the service when needed.
    internal func register(_ factory: @escaping (P) -> T) {
        defer { globalRecursiveLock.unlock()  }
        globalRecursiveLock.lock()
        let manager = unsafeCheckecContainer().manager
        if unsafeCanUpdateOptions() {
            manager.registrations[id] = TypedFactory(factory: factory)
            manager.cache.removeValue(forKey: id)
        }
    }

    /// Registers a new factory scope.
    /// - Parameter: - scope: New scope
    internal func scope(_ scope: Scope?) {
        defer { globalRecursiveLock.unlock()  }
        globalRecursiveLock.lock()
        let manager = unsafeCheckecContainer().manager
        if var options = manager.options[id] {
            if once == options.once && scope !== options.scope {
                options.scope = scope
                manager.options[id] = options
                manager.cache.removeValue(forKey: id)
            }
        } else {
            manager.options[id] = FactoryOptions(scope: scope)
        }
    }

    /// Registers a new context.
    internal func context(_ context: FactoryContext, id: String, factory: @escaping (P) -> T) {
        options { options in
            switch context {
            case .arg(let arg):
                if options.argumentContexts == nil {
                    options.argumentContexts = [:]
                }
                options.argumentContexts?["arg=\(arg)"] = TypedFactory(factory: factory)
            default:
                if options.contexts == nil {
                    options.contexts = [:]
                }
                options.contexts?["\(context)"] = TypedFactory(factory: factory)
            }
            self.container.manager.cache.removeValue(forKey: id)
        }
    }

    /// Registers a new decorator.
    internal func decorator(_ decorator: @escaping (T) -> Void) {
        options { options in
            options.decorator = decorator
        }
    }

    /// Support function for options mutation.
    internal func options(mutate: (_ options: inout FactoryOptions) -> Void) {
        defer { globalRecursiveLock.unlock()  }
        globalRecursiveLock.lock()
        let manager = unsafeCheckecContainer().manager
        var options = manager.options[id] ?? FactoryOptions(scope: defaultScope)
        if options.once == once {
            mutate(&options)
            manager.options[id] = options
        }
    }

    /// Support function resets the behavior for a specific Factory to its original state, removing any associated registrations and clearing
    /// any cached instances from the specified scope.
    /// - Parameters:
    ///   - options: Reset option: .all, .registration, .scope, .none
    ///   - id: ID of item to remove from the appropriate cache.
    internal func reset(options: FactoryResetOptions) {
        guard options != .none else { return }
        defer { globalRecursiveLock.unlock()  }
        globalRecursiveLock.lock()
        let manager = container.manager
        switch options {
        case .registration:
            manager.registrations.removeValue(forKey: id)
        case .context:
            self.options {
                $0.argumentContexts = [:]
                $0.contexts = [:]
            }
        case .scope:
            manager.cache.removeValue(forKey: id)
        default:
            manager.registrations = manager.registrations.filter { !$0.key.hasPrefix(id) }
            manager.options.removeValue(forKey: id)
            manager.cache.removeValue(forKey: id)
        }
    }

    #if DEBUG
    internal func circularDependencyChainCheck(for typeName: String, max: Int) {
        let typeComponents = typeName.components(separatedBy: CharacterSet(charactersIn: "<>"))
        let typeName = typeComponents.count > 1 ? typeComponents[1] : typeComponents[0]
        let typeIndex = globalDependencyChain.firstIndex(where: { $0 == typeName })
        globalDependencyChain.append(typeName)
        if let index = typeIndex {
            let chain = globalDependencyChain[index...]
            let message = "circular dependency chain - \(chain.joined(separator: " > "))"
            if globalDependencyChainMessages.filter({ $0 == message }).count == max {
                globalDependencyChain = []
                globalDependencyChainMessages = []
                globalGraphResolutionDepth = 0
                globalRecursiveLock = RecursiveLock()
                globalTraceResolutions = []
                triggerFatalError(message, #file, #line)
            } else {
                globalDependencyChain = [typeName]
                globalDependencyChainMessages.append(message)
            }
        }
    }
    #endif

}

// MARK: - Internal Protocols and Types

internal struct FactoryOptions {
    /// Managed scope for this factory instance
    var scope: Scope?
    /// Contexts
    var argumentContexts: [String:AnyFactory]?
    /// Contexts
    var contexts: [String:AnyFactory]?
    /// Decorator will be passed fully constructed instance for further configuration.
    var decorator: Any?
    /// Onve flag for options
    var once: Bool = false
}

// Internal Factory type
internal protocol AnyFactory {}

internal struct TypedFactory<P,T>: AnyFactory {
    let factory: (P) -> T
}

/// Internal protocol used to evaluate optional types for caching
internal protocol OptionalProtocol {
    var hasWrappedValue: Bool { get }
    var wrappedValue: Any? { get }
}

extension Optional: OptionalProtocol {
    @inlinable internal var hasWrappedValue: Bool {
        wrappedValue != nil
    }
    @inlinable internal var wrappedValue: Any? {
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

/// Strong box for strong references to a type
internal struct StrongBox<T>: AnyBox {
    let scopeID: UUID
    let boxed: T
}

/// Weak box for shared scope
internal struct WeakBox: AnyBox {
    let scopeID: UUID
    weak var boxed: AnyObject?
}

// MARK: - Locking

internal final class RecursiveLock {
    init() {
        pthread_mutexattr_init(&mutexAttr)
        pthread_mutexattr_settype(&mutexAttr, PTHREAD_MUTEX_RECURSIVE)
        pthread_mutex_init(&mutex, &mutexAttr)
    }
    deinit {
        pthread_mutex_destroy(&mutex)
        pthread_mutexattr_destroy(&mutexAttr)
    }
    @inlinable final func lock() {
        pthread_mutex_lock(&globalRecursiveLock.mutex)
    }
    @inlinable final func unlock() {
        pthread_mutex_unlock(&globalRecursiveLock.mutex)
    }
    private var mutex = pthread_mutex_t()
    private var mutexAttr = pthread_mutexattr_t()
}

/// Master recursive lock
private var globalRecursiveLock = RecursiveLock()

// MARK: - Internal Variables

/// Master graph resolution depth counter
private var globalGraphResolutionDepth = 0

#if DEBUG
/// Internal variables used for debugging
private var globalDependencyChain: [String] = []
private var globalDependencyChainMessages: [String] = []
private var globalTraceFlag: Bool = false
private var globalTraceResolutions: [String] = []
private var globalLogger: (String) -> Void = { print($0) }

/// Allow unit test interception of any fatal errors that may occur running the circular dependency check
/// Variation of solution: https://stackoverflow.com/questions/32873212/unit-test-fatalerror-in-swift#
internal var triggerFatalError = Swift.fatalError
#endif
