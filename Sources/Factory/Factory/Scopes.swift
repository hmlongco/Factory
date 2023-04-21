//
// Scopes.swift
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
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

import Foundation

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
    internal func resolve<T>(using cache: Cache, id: String, ttl: TimeInterval?, factory: () -> T) -> T {
        if let box = cache.value(forKey: id), let cached: T = unboxed(box: box) {
            if let ttl = ttl {
                let now = CFAbsoluteTimeGetCurrent()
                if (box.timestamp + ttl) > now {
                    cache.set(timestamp: now, forKey: id)
                    return cached
                }
            } else {
                return cached
            }
        }
        let instance = factory()
        if let box = box(instance) {
             cache.set(value: box, forKey: id)
        }
        return instance
    }

    /// Internal function returns unboxed value if it exists
    fileprivate func unboxed<T>(box: AnyBox?) -> T? {
        (box as? StrongBox<T>)?.boxed
    }

    /// Internal function correctly boxes value depending upon scope type
    fileprivate func box<T>(_ instance: T) -> AnyBox? {
        if let optional = instance as? OptionalProtocol {
            if optional.hasWrappedValue {
                return StrongBox<T>(scopeID: scopeID, timestamp: CFAbsoluteTimeGetCurrent(), boxed: instance)
            }
            return nil
        }
        return StrongBox<T>(scopeID: scopeID, timestamp: CFAbsoluteTimeGetCurrent(), boxed: instance)
    }

    internal let scopeID: UUID = UUID()

}

// MARK: - Scopes

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
        internal override func resolve<T>(using cache: Cache, id: String, ttl: TimeInterval?, factory: () -> T) -> T {
            // ignore container's cache in favor of our own
            return super.resolve(using: self.cache, id: id, ttl: ttl, factory: factory)
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
                    return WeakBox(scopeID: scopeID, timestamp: CFAbsoluteTimeGetCurrent(), boxed: unwrapped as AnyObject)
                }
            } else if type(of: instance as Any) is AnyObject.Type {
                return WeakBox(scopeID: scopeID, timestamp: CFAbsoluteTimeGetCurrent(), boxed: instance as AnyObject)
            }
            return nil
        }
    }

    /// A reference to the default singleton scope manager.
    public static let singleton = Singleton()
    /// Defines the singleton scope. The same instance will always be returned by the factory.
    public final class Singleton: Scope, InternalScopeCaching {
        public override init() {
            super.init()
        }
        internal override func resolve<T>(using cache: Cache, id: String, ttl: TimeInterval?, factory: () -> T) -> T {
            // ignore container's cache in favor of our own
            return super.resolve(using: self.cache, id: id, ttl: ttl, factory: factory)
        }
        /// Private shared cache
        internal var cache = Cache()
        /// Reset
        public func reset() {
            defer { globalRecursiveLock.unlock()  }
            globalRecursiveLock.lock()
            cache.reset()
        }
    }

    /// A reference to the default unique scope.
    ///
    /// If no scope cache is specified then Factory is running in unique more.
    public static let unique = Unique()
    /// Defines the unique scope. A new instance of a given type will be returned on every resolution cycle.
    public final class Unique: Scope {
        public override init() {
            super.init()
        }
        internal override func resolve<T>(using cache: Cache, id: String, ttl: TimeInterval?, factory: () -> T) -> T {
            factory()
        }
    }

}

// MARK: - Caching

extension Scope {
    /// Internal class that manages scope caching for containers and scopes.
    internal final class Cache {
        typealias CacheMap = [String:AnyBox]
        /// Internal support functions
        @inlinable func value(forKey key: String) -> AnyBox? {
            cache[key]
        }
        @inlinable func set(value: AnyBox, forKey key: String)  {
            cache[key] = value
        }
        @inlinable func set(timestamp: Double, forKey key: String)  {
            cache[key]?.timestamp = timestamp
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

// MARK: - Scope Protocols

internal protocol InternalScopeCaching {
    var cache: Scope.Cache { get }
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
    var timestamp: Double { get set }
}

/// Strong box for strong references to a type
internal struct StrongBox<T>: AnyBox {
    let scopeID: UUID
    var timestamp: Double
    let boxed: T
}

/// Weak box for shared scope
internal struct WeakBox: AnyBox {
    let scopeID: UUID
    var timestamp: Double
    weak var boxed: AnyObject?
}
