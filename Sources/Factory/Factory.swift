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
        self.factory = factory
    }

    /// Initializes with factory closure that returns a new instance of the desired type. The scope defines the lifetime of that instance.
    public init(scope: SharedContainer.Scope, factory: @escaping () -> T) {
        self.factory = factory
        self.scope = scope
    }

    /// Resolves and returns an instance of the desired object type. This may be a new instance or one that was created previously and then cached,
    /// depending on whether or not a scope was specified when the factory was created.
    ///
    /// Note return type could of T could still be <T?> depending on original Factory specification.
    public func callAsFunction() -> T {
        defer { globalRecursiveLock.unlock() }
        globalRecursiveLock.lock()
        if let instance: T = scope?.cached(id) {
            SharedContainer.Decorator.cached?(instance)
            return instance
        } else {
            let instance: T = SharedContainer.Registrations.resolve(id: id) ?? factory()
            scope?.cache(id: id, instance: instance)
            SharedContainer.Decorator.created?(instance)
            return instance
        }
    }

    /// Registers a new factory that will be used to create and return an instance of the desired object type.
    ///
    /// This registration overrides the orginal factory and its result will be returned on all new object resolutions. Registering a new
    /// factory also clears the previous instance from the associated scope.
    ///
    /// All registrations are stored in SharedContainer.Registrations.
    public func register(factory: @escaping () -> T) {
        defer { globalRecursiveLock.unlock() }
        globalRecursiveLock.lock()
        SharedContainer.Registrations.register(id: id, factory: factory)
        scope?.reset(id)
    }

    /// Deletes any registered factory override and resets this Factory to use the factory closure specified during initialization. Also
    /// resets the scope so that a new instance of the original type will be returned on the next resolution.
    public func reset() {
        defer { globalRecursiveLock.unlock() }
        globalRecursiveLock.lock()
        SharedContainer.Registrations.reset(id)
        scope?.reset(id)
    }

    private let id: UUID = UUID()
    private var factory: () -> T
    private var scope: SharedContainer.Scope?
}

/// Empty convenience class for user dependencies.
public class Container: SharedContainer {

}

/// Base class for all containers.
open class SharedContainer {

    public class Registrations {

        /// Pushes the current set of registration overrides onto a stack. Useful when testing when you want to push the current set of registions,
        /// add your own, test, then pop the stack to restore the world to its original state.
        public static func push() {
            defer { globalRecursiveLock.unlock() }
            globalRecursiveLock.lock()
            stack.append(registrations)
        }

        /// Pops a previously pushed registration stack. Does nothing if stack is empty.
        public static func pop() {
            defer { globalRecursiveLock.unlock() }
            globalRecursiveLock.lock()
            if let registrations = stack.popLast() {
                self.registrations = registrations
            }
        }

        /// Resets and deletes all registered factory overrides.
        public static func reset() {
            defer { globalRecursiveLock.unlock() }
            globalRecursiveLock.lock()
            registrations = [:]
        }

        /// Internal registration function used by Factory
        fileprivate static func register<T>(id: UUID, factory: @escaping () -> T) {
            registrations[id] = factory
        }

        /// Internal resolution function used by Factory
        fileprivate static func resolve<T>(id: UUID) -> T? {
            if let instance = registrations[id]?() {
                // following needed to successfully unwrap cached Any into <T?>'s and <T>'s
                return instance as? T? ?? instance as? T
            }
            return nil
        }

        /// Internal reset function used by Factory
        fileprivate static func reset(_ id: UUID) {
            registrations.removeValue(forKey: id)
        }

        private static var registrations: [UUID:() -> Any] = [:]
        private static var stack: [[UUID:() -> Any]] = []

    }

    /// Defines an abstract base implementation of a scope cache.
    public class Scope {

        fileprivate init(box: @escaping (_ instance: Any) -> AnyBox) {
            defer { globalRecursiveLock.unlock() }
            globalRecursiveLock.lock()
            self.box = box
            Self.scopes.append(self)
        }

        /// Resets the cache. Any factory using this cache will return a new instance after the cache is reset.
        public func reset() {
            defer { globalRecursiveLock.unlock() }
            globalRecursiveLock.lock()
            cache = [:]
        }

        /// Public query mechanism for cache empty
        public var isEmpty: Bool {
            defer { globalRecursiveLock.unlock() }
            globalRecursiveLock.lock()
            return cache.isEmpty
        }

        /// Internal cache resolution function used by Factory
        fileprivate func cached<T>(_ id: UUID) -> T? {
            if let instance = cache[id]?.instance {
                // following needed to successfully unwrap cached Any into <T?>'s and <T>'s
                return instance as? T? ?? instance as? T
            }
            return nil
        }

        /// Internal cache function used by Factory
        fileprivate func cache(id: UUID, instance: Any) {
            cache[id] = box(instance) // last instance always cached, even if nil
        }

        /// Internal reset function used by Factory
        fileprivate func reset(_ id: UUID) {
            cache.removeValue(forKey: id)
        }

        private var box: (_ instance: Any) -> AnyBox
        private var cache = [UUID:AnyBox](minimumCapacity: 32)

    }

    /// Defines decorator functions that will be called when a factory is resolved.
    public struct Decorator {

        /// Decorator function called when a factory is resolved and the instance is retrieved from a scope cache. Useful for logging.
        public static var cached: ((_ dependency: Any) -> Void)?

        /// Decorator function called when a factory is resolved and a new instance is created. Useful for logging.
        public static var created: ((_ dependency: Any) -> Void)?

    }
}

extension SharedContainer.Scope {

    /// Defines a cached scope. The same instance will be returned by the factory until the cache is reset.
    public static let cached = Cached()
    public final class Cached: SharedContainer.Scope {
        public init() {
            super.init { StrongBox(instance: $0 as AnyObject) }
        }
    }

    /// Defines a shared (weak) scope. The same instance will be returned by the factory as long as someone maintains a strong reference.
    public static let shared = Shared()
    public final class Shared: SharedContainer.Scope {
        public init() {
            super.init { WeakBox(instance: $0 as AnyObject) }
        }
    }

    /// Defines a singleton scope. The same instance will always be returned by the factory.
    public static let singleton = Singleton()
    public final class Singleton: SharedContainer.Scope {
        public init() {
            super.init { StrongBox(instance: $0 as AnyObject) }
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
    private var factory:  Factory<T>
    private var dependency: T!
    public init(_ factory: Factory<T>) {
        self.factory = factory
    }
    public var wrappedValue: T {
        mutating get {
            if dependency == nil {
                dependency = factory()
            }
            return dependency
        }
        mutating set {
            dependency = newValue
        }
    }
}
#endif

/// Resolving an instance of a service is a recursive process (service A needs a B which needs a C).
private final class FactoryRecursiveLock {
    init() {
        pthread_mutexattr_init(&recursiveMutexAttr)
        pthread_mutexattr_settype(&recursiveMutexAttr, PTHREAD_MUTEX_RECURSIVE)
        pthread_mutex_init(&recursiveMutex, &recursiveMutexAttr)
    }
    @inline(__always)
    final func lock() {
        pthread_mutex_lock(&recursiveMutex)
    }
    @inline(__always)
    final func unlock() {
        pthread_mutex_unlock(&recursiveMutex)
    }
    private var recursiveMutex = pthread_mutex_t()
    private var recursiveMutexAttr = pthread_mutexattr_t()
}

/// Lock used for multi-threaded protection around registrations and scope caches
private var globalRecursiveLock = FactoryRecursiveLock()

/// Internal box protocol for scope functionality
private protocol AnyBox {
    var instance: AnyObject? { get }
}

/// Strong box for cached and singleton scopes
private struct StrongBox: AnyBox {
    let instance: AnyObject?
}

/// Weak box for shared scope
private struct WeakBox: AnyBox {
    weak var instance: AnyObject?
}
