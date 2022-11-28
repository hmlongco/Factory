//
// Factory.swift
//
// GitHub Repo and Documentation: https://github.com/hmlongco/Factory
//
// Copyright ©2022 Michael Long. All rights reserved.
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

/// Factory manages the dependency injection process for a given object or service.
public struct Factory<T> {

    /// Initializes a Factory with a factory closure that returns a new instance of the desired type.
    public init(factory: @escaping () -> T) {
        self.registration = Registration<Void, T>(factory: factory, scope: nil)
    }

    /// Initializes with factory closure that returns a new instance of the desired type. The scope defines the lifetime of that instance.
    public init(scope: SharedContainer.Scope, factory: @escaping () -> T) {
        self.registration = Registration<Void, T>(factory: factory, scope: scope)
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
    /// This registration overrides the original factory and its result will be returned on all new object resolutions. Registering a new
    /// factory also clears the previous instance from the associated scope.
    ///
    /// All registrations are stored in SharedContainer.Registrations.
    public func register(factory: @escaping () -> T) {
        registration.register(factory: factory)
    }

    /// Deletes any registered factory override and resets this Factory to use the factory closure specified during initialization. Also
    /// resets the scope so that a new instance of the original type will be returned on the next resolution.
    public func reset() {
        registration.reset()
    }

    private let registration: Registration<Void, T>
}

/// ParameterFactory manages the dependency injection process for a given object or service that needs one or more arguments
/// passed to it during instantiation.
public struct ParameterFactory<P, T> {

    /// Initializes a Factory with a factory closure that returns a new instance of the desired type.
    public init(factory: @escaping (_ params: P) -> T) {
        self.registration = Registration<P, T>(factory: factory, scope: nil)
    }

    /// Initializes with factory closure that returns a new instance of the desired type. The scope defines the lifetime of that instance.
    public init(scope: SharedContainer.Scope, factory: @escaping (_ params: P) -> T) {
        self.registration = Registration<P, T>(factory: factory, scope: scope)
    }

    /// Resolves and returns an instance of the desired object type. This may be a new instance or one that was created previously and then cached,
    /// depending on whether or not a scope was specified when the factory was created.
    ///
    /// Note return type could of T could still be <T?> depending on original Factory specification.
    public func callAsFunction(_ params: P) -> T {
        registration.resolve(params)
    }

    /// Registers a new factory that will be used to create and return an instance of the desired object type.
    ///
    /// This registration overrides the original factory and its result will be returned on all new object resolutions. Registering a new
    /// factory also clears the previous instance from the associated scope.
    ///
    /// All registered factories are stored in SharedContainer.Registrations.
    public func register(factory: @escaping (_ params: P) -> T) {
        registration.register(factory: factory)
    }

    /// Deletes any registered factory override and resets this Factory to use the factory closure specified during initialization. Also
    /// resets the scope so that a new instance of the original type will be returned on the next resolution.
    public func reset() {
        registration.reset()
    }

    private let registration: Registration<P, T>
}

/// Empty convenience class for user dependencies.
public class Container: SharedContainer {
}

/// Base class for all containers.
open class SharedContainer {

    public class Registrations {

        /// Pushes the current set of registration overrides onto a stack. Useful when testing when you want to push the current set of registrations,
        /// add your own, test, then pop the stack to restore the world to its original state.
        public static func push() {
            defer { lock.unlock() }
            lock.lock()
            stack.append(registrations)
        }

        /// Pops a previously pushed registration stack. Does nothing if stack is empty.
        public static func pop() {
            defer { lock.unlock() }
            lock.lock()
            if let registrations = stack.popLast() {
                self.registrations = registrations
            }
        }

        /// Resets and deletes all registered factory overrides.
        public static func reset() {
            defer { lock.unlock() }
            lock.lock()
            registrations = [:]
        }

        /// Internal registration function used by Factory
        fileprivate static func register(id: UUID, factory: AnyFactory) {
            defer { lock.unlock() }
            lock.lock()
            registrations[id] = factory
        }

        /// Internal resolution function used by Factory
        fileprivate static func factory(for id: UUID) -> AnyFactory? {
            defer { lock.unlock() }
            lock.lock()
            return registrations[id]
        }

        /// Internal reset function used by Factory
        fileprivate static func reset(_ id: UUID) {
            defer { lock.unlock() }
            lock.lock()
            registrations.removeValue(forKey: id)
        }

        private static var lock = NSLock()
        private static var registrations: [UUID: AnyFactory] = .init(minimumCapacity: 64)
        private static var stack: [[UUID: AnyFactory]] = []

    }

    /// Defines an abstract base implementation of a scope cache.
    public class Scope {

        fileprivate init() {
            defer { lock.unlock() }
            lock.lock()
            Self.scopes.append(self)
        }

        /// Resets the cache. Any factory using this cache will return a new instance after the cache is reset.
        public func reset() {
            defer { lock.unlock() }
            lock.lock()
            cache = [:]
        }

        /// Public query mechanism for cache empty
        public var isEmpty: Bool {
            defer { lock.unlock() }
            lock.lock()
            return cache.isEmpty
        }

        /// Internal cache resolution function used by Factory Registration
        fileprivate func resolve<T>(id: UUID, factory: () -> T) -> T {
            defer { lock.unlock() }
            lock.lock()
            if let box = cache[id] {
                if let instance = box.instance as? T {
                    if let optional = instance as? OptionalProtocol {
                        if optional.hasWrappedValue {
                           return instance
                        }
                    } else {
                        return instance
                    }
                }
            }
            let instance: T = factory()
            if let box = box(instance) {
                cache[id] = box
            }
            return instance
        }

        /// Internal reset function used by Factory
        fileprivate func reset(_ id: UUID) {
            defer { lock.unlock() }
            lock.lock()
            cache.removeValue(forKey: id)
        }

        /// Internal function correctly boxes cache value depending upon scope type
        fileprivate func box<T>(_ instance: T) -> AnyBox? {
            if let optional = instance as? OptionalProtocol {
                return optional.hasWrappedValue ? StrongBox<T>(boxed: instance) : nil
            } else {
                return StrongBox<T>(boxed: instance)
            }
        }

        private var lock = NSRecursiveLock()
        private var cache: [UUID: AnyBox] = .init(minimumCapacity: 64)

    }

    /// Defines decorator functions that will be called when a factory is resolved.
    public struct Decorator {

        /// Decorator function called when a factory registration is resolved. Useful for logging.
        public static var decorate: ((_ dependency: Any) -> Void)?

    }
}

extension SharedContainer.Scope {

    /// Defines a cached scope. The same instance will be returned by the factory until the cache is reset.
    public static let cached = Cached()
    public final class Cached: SharedContainer.Scope {
        public override init() {
            super.init()
        }
    }

    /// Defines a shared (weak) scope. The same instance will be returned by the factory as long as someone maintains a strong reference.
    public static let shared = Shared()
    public final class Shared: SharedContainer.Scope {
        public override init() {
            super.init()
        }
        fileprivate override func box<T>(_ instance: T) -> AnyBox? {
            if let optional = instance as? OptionalProtocol {
                if let unwrapped = optional.wrappedValue, type(of: unwrapped) is AnyObject.Type {
                    return WeakBox(boxed: unwrapped as AnyObject)
                }
            } else if type(of: instance as Any) is AnyObject.Type {
                return WeakBox(boxed: instance as AnyObject)
            }
            return nil
        }
    }

    /// Defines a singleton scope. The same instance will always be returned by the factory.
    public static let singleton = Singleton()
    public final class Singleton: SharedContainer.Scope {
        public override init() {
            super.init()
        }
    }

    /// Resets all scope caches.
    public static func reset(includingSingletons: Bool = false) {
        Self.scopes.forEach {
            if !($0 is Singleton) || includingSingletons {
                $0.reset()
            }
        }
    }

    private static var scopes: [SharedContainer.Scope] = []

}

#if swift(>=5.1)
/// Convenience property wrapper takes a factory and creates an instance of the desired type.
@propertyWrapper public struct Injected<T> {
    private var dependency: T
    public init(_ factory: Factory<T>) {
        self.dependency = factory()
    }
    public var wrappedValue: T {
        get { return dependency }
        mutating set { dependency = newValue }
    }
}

/// Convenience property wrapper takes a factory and creates an instance of the desired type the first time the wrapped value is requested.
@propertyWrapper public struct LazyInjected<T> {
    private var factory: Factory<T>
    private var dependency: T!
    private var initialize = true
    public init(_ factory: Factory<T>) {
        self.factory = factory
    }
    public var wrappedValue: T {
        mutating get {
            if initialize {
                dependency = factory()
                initialize = false
            }
            return dependency
        }
        mutating set {
            dependency = newValue
        }
    }
}

@propertyWrapper public struct WeakLazyInjected<T> {
    private var factory: Factory<T>
    private weak var dependency: AnyObject?
    private var initialize = true
    public init(_ factory: Factory<T>) {
        self.factory = factory
    }
    public var wrappedValue: T? {
        mutating get {
            if initialize {
                dependency = factory() as AnyObject
                initialize = false
            }
            return dependency as? T
        }
        mutating set {
            dependency = newValue as AnyObject
        }
    }
}
#endif

/// Enable automatic registrations
public protocol AutoRegistering {
    static func registerAllServices()
}

extension Container {
    /// Statically allocated var performs automatic registration check one time and one time only.
    fileprivate static var autoRegistrationCheck: Void  = {
        (Container.self as? AutoRegistering.Type)?.registerAllServices()
    }()
}

/// Internal box protocol for factories
private protocol AnyFactory {}

/// Typed factory container
private struct TypedFactory<P, T>: AnyFactory {
    let factory: (P) -> T
}

/// Internal registration manager for factories.
private struct Registration<P, T> {

    let id: UUID = UUID()
    let factory: (P) -> T
    let scope: SharedContainer.Scope?

    /// Resolves registration returning cached value from scope or new instance from factory. This is pretty much the heart of Factory.
    func resolve(_ params: P) -> T {
        let _ = Container.autoRegistrationCheck
        let currentFactory: (P) -> T = (SharedContainer.Registrations.factory(for: id) as? TypedFactory<P, T>)?.factory ?? factory
        let instance: T = scope?.resolve(id: id, factory: { currentFactory(params) }) ?? currentFactory(params)
        SharedContainer.Decorator.decorate?(instance)
        return instance
    }

    /// Registers a factory override and resets cache.
    func register(factory: @escaping (_ params: P) -> T) {
        SharedContainer.Registrations.register(id: id, factory: TypedFactory<P, T>(factory: factory))
        scope?.reset(id)
    }

    /// Removes a factory override and resets cache.
    func reset() {
        SharedContainer.Registrations.reset(id)
        scope?.reset(id)
    }

}

/// Internal protocol used to evaluate optional types for caching
private protocol OptionalProtocol {
    var hasWrappedValue: Bool { get }
    var wrappedType: Any.Type { get }
    var wrappedValue: Any? { get }
}

extension Optional: OptionalProtocol {
    var hasWrappedValue: Bool {
        switch self {
        case .none:
            return false
        case .some:
            return true
        }
    }
    var wrappedType: Any.Type {
        Wrapped.self
    }
    var wrappedValue: Any? {
        switch self {
        case .none:
            return nil
        case .some(let value):
            return value
        }
    }
}

/// Internal box protocol for scope functionality
private protocol AnyBox {
    var instance: Any { get }
}

/// Strong box for cached and singleton scopes
private struct StrongBox<T>: AnyBox {
    let boxed: T
    var instance: Any {
        boxed as Any
    }
}

/// Weak box for shared scope
private struct WeakBox: AnyBox {
    weak var boxed: AnyObject?
    var instance: Any {
        boxed as Any
    }
}
