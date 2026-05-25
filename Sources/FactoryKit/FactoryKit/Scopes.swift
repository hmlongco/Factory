//
// Scopes.swift
//
// GitHub Repo and Documentation: https://github.com/hmlongco/Factory
//
// Copyright © 2022-2025 Michael Long. All rights reserved.
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

import CoreFoundation
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
///
/// Class is @unchecked Sendable as all public state is managed via global locking mechanisms
public class Scope: @unchecked Sendable {

    fileprivate init() {}

    /// Internal function returns cached value if it exists. Otherwise it creates a new instance and caches that value for later reference.
    internal func resolve<T>(using cache: Cache, key: FactoryKey, ttl: TimeInterval?, factory: () -> T) -> (T, Bool) {
        cache.resolve(key: key, ttl: ttl, scope: self, factory: factory)
    }

    /// Internal function returns unboxed value if it exists
    internal func unboxed<T>(box: AnyBox?) -> T? {
        (box as? StrongBox<T>)?.boxed
    }

    /// Internal function correctly boxes value depending upon scope type
    fileprivate func box<T>(_ instance: T) -> AnyBox? {
        if let optional = instance as? OptionalProtocol {
            if optional.hasWrappedValue {
                return StrongBox<T>(scopeID: scopeID, timestamp: currentTimestamp(), boxed: instance)
            }
            return nil
        }
        return StrongBox<T>(scopeID: scopeID, timestamp: currentTimestamp(), boxed: instance)
    }

    internal let scopeID: UUID = UUID()

}

// MARK: - Scopes

extension Scope {

    /// A reference to the default cached scope manager.
    public static let cached = Cached()
    /// Defines a cached scope. The same instance will be returned by the factory until the cache is reset.
    public final class Cached: Scope, @unchecked Sendable {
        public override init() {
            super.init()
        }
        internal override func resolve<T>(using cache: Cache, key: FactoryKey, ttl: TimeInterval?, factory: () -> T) -> (T, Bool) {
            cache.resolve(key: key, ttl: ttl, scope: self, factory: factory, exclusiveCreation: true)
        }
    }

    /// A reference to the default graph scope manager.
    public static let graph = Graph()
    /// Defines the graph scope. A single instance of a given type will be returned during a given resolution cycle.
    ///
    /// This scope is managed and cleared by the main resolution function at the end of each resolution cycle.
    /// Thread safety: Each thread gets its own graph cache via thread-local storage, so concurrent
    /// resolutions do not interfere with each other's resolution cycles.
    public final class Graph: Scope, @unchecked Sendable  {
        internal override init() {
            super.init()
        }
        internal override func resolve<T>(using cache: Cache, key: FactoryKey, ttl: TimeInterval?, factory: () -> T) -> (T, Bool) {
            // Use the thread-local graph cache instead of the container's cache
            let graphCache = threadLocalCache
            return super.resolve(using: graphCache, key: key, ttl: ttl, factory: factory)
        }
        /// Enter a new resolution level on the current thread
        internal func enter() {
            let current = threadLocalDepth
            threadLocalDepth = current + 1
        }
        /// Leave the current resolution level on the current thread
        internal func leave() {
            let current = threadLocalDepth - 1
            threadLocalDepth = current
            if current == 0 {
                threadLocalCache.reset()
            }
        }
        /// Reset graph scope (used in error recovery)
        internal func reset() {
            threadLocalDepth = 0
            threadLocalCache.reset()
        }
        /// Depth of current resolution level (per-thread)
        public var depth: Int {
            threadLocalDepth
        }

        // MARK: - Thread-Local Storage

        private static let depthKey: pthread_key_t = {
            var key: pthread_key_t = 0
            pthread_key_create(&key, nil)
            return key
        }()

        private static let cacheKey: pthread_key_t = makePthreadKey { rawPointer in
            Unmanaged<Cache>.fromOpaque(rawPointer).release()
        }

        private var threadLocalDepth: Int {
            get {
                Int(bitPattern: pthread_getspecific(Graph.depthKey))
            }
            set {
                pthread_setspecific(Graph.depthKey, UnsafeRawPointer(bitPattern: newValue))
            }
        }

        private var threadLocalCache: Cache {
            if let raw = pthread_getspecific(Graph.cacheKey) {
                return Unmanaged<Cache>.fromOpaque(raw).takeUnretainedValue()
            }
            let cache = Cache(minimumCapacity: 16)
            pthread_setspecific(Graph.cacheKey, Unmanaged.passRetained(cache).toOpaque())
            return cache
        }
    }

    /// A reference to the default shared scope manager.
    public static let shared = Shared()
    /// Defines a shared (weak) scope. The same instance will be returned by the factory as long as someone maintains a strong reference.
    public final class Shared: Scope, @unchecked Sendable  {
        public override init() {
            super.init()
        }
        internal override func unboxed<T>(box: AnyBox?) -> T? {
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
                    return WeakBox(scopeID: scopeID, timestamp: currentTimestamp(), boxed: unwrapped as AnyObject)
                }
            } else if type(of: instance as Any) is AnyObject.Type {
                return WeakBox(scopeID: scopeID, timestamp: currentTimestamp(), boxed: instance as AnyObject)
            }
            return nil
        }
    }

    /// A reference to the default singleton scope manager.
    #if swift(>=5.5)
    @TaskLocal public static var singleton = Singleton()
    #else
    public static let singleton = Singleton()
    #endif
    /// Defines the singleton scope. The same instance will always be returned by the factory.
    public final class Singleton: Scope, InternalScopeCaching, @unchecked Sendable  {
        public override init() {
            self.cache = Cache()
            super.init()
        }
        internal init(from: Singleton) {
            self.cache = from.cache.clone()
            super.init()
        }
        internal override func resolve<T>(using cache: Cache, key: FactoryKey, ttl: TimeInterval?, factory: () -> T) -> (T, Bool) {
            // Use our own cache with exclusive creation to guarantee the factory runs exactly once
            self.cache.resolve(key: key, ttl: ttl, scope: self, factory: factory, exclusiveCreation: true)
        }
        /// Private shared cache
        internal var cache: Cache
        /// Reset
        public func reset() {
            globalRecursiveLock.withLock {
                cache.reset()
            }
        }
        /// For testing
        public func clone() -> Singleton {
            .init(from: self)
        }
    }

    /// A reference to the default unique scope.
    ///
    /// If no scope cache is specified then Factory is running in unique mode.
    public static let unique = Unique()
    
    /// Defines the unique scope. A new instance of a given type will be returned on every resolution cycle.
    public final class Unique: Scope, @unchecked Sendable  {
        public override init() {
            super.init()
        }
        internal override func resolve<T>(using cache: Cache, key: FactoryKey, ttl: TimeInterval?, factory: () -> T) -> (T, Bool) {
            (factory(), true)
        }
    }

}

// MARK: - Caching

extension Scope {
    /// Internal class that manages scope caching for containers and scopes.
    ///
    /// Thread safety: All access is protected by an internal CrossPlatformLock, allowing
    /// cache operations to be performed without holding the global recursive lock.
    /// Per-key creation locks use a sleeping mutex to avoid spinning during factory creation.
    internal final class Cache {
        typealias CacheMap = [FactoryKey:AnyBox]

        private let lock = CrossPlatformLock()
        private let creationLockGuard = CrossPlatformLock()
        /// Per-key creation locks for exclusive creation (singleton guarantee).
        private var creationLocks: [FactoryKey: MutexLock] = [:]

        /// Internal support functions
        @inlinable @inline(__always) func value(forKey key: FactoryKey) -> AnyBox? {
            lock.withLock { cache[key] }
        }
        @inlinable @inline(__always) func set(value: AnyBox, forKey key: FactoryKey)  {
            lock.withLock { cache[key] = value }
        }
        @inlinable @inline(__always) func set(timestamp: Double, forKey key: FactoryKey)  {
            lock.withLock { cache[key]?.timestamp = timestamp }
        }
        @inlinable @inline(__always) func removeValue(forKey key: FactoryKey) {
            lock.withLock { cache = cache.filter { $0.key.normalized() != key } }
            creationLockGuard.withLock {
                creationLocks = creationLocks.filter { $0.key.normalized() != key }
            }
        }
        internal func reset(scopeID: UUID) {
            lock.withLock { cache = cache.filter { $1.scopeID != scopeID } }
            creationLockGuard.withLock {
                creationLocks.removeAll(keepingCapacity: true)
            }
        }
        /// Internal function to clear cache if needed
        internal func reset() {
            lock.withLock {
                cache.removeAll(keepingCapacity: true)
            }
            creationLockGuard.withLock {
                creationLocks.removeAll(keepingCapacity: true)
            }
        }

        /// Atomic get-or-create: returns cached value if present, otherwise executes
        /// the factory closure (without holding the cache lock) and stores the result.
        ///
        /// Takes the `scope` directly instead of closure trampolines for unbox/box,
        /// eliminating 2 heap-allocated closure contexts per resolve call.
        ///
        /// When `exclusiveCreation` is true (used by singleton/cached scope), a per-key lock
        /// ensures only one thread ever executes the factory for a given key. Other threads
        /// wait and receive the cached result.
        ///
        /// When `exclusiveCreation` is false (default), concurrent cache misses for the same
        /// key may both create instances. First write wins — matches Swift's `lazy var` semantics.
        internal func resolve<T>(
            key: FactoryKey,
            ttl: TimeInterval?,
            scope: Scope,
            factory: () -> T,
            exclusiveCreation: Bool = false
        ) -> (T, Bool) {
            // Fast path: check cache
            if let existing = lock.withLock({ cache[key] }) {
                if let cached: T = scope.unboxed(box: existing) {
                    if let ttl = ttl {
                        let now = currentTimestamp()
                        if (existing.timestamp + ttl) > now {
                            lock.withLock { cache[key]?.timestamp = now }
                            return (cached, false)
                        }
                        // TTL expired — fall through to slow path
                    } else {
                        return (cached, false)
                    }
                }
            }

            if exclusiveCreation {
                // Singleton/cached guarantee: per-key lock ensures only one thread creates.
                //
                // NOTE: The per-key MutexLock is non-recursive. A circular dependency on
                // scoped factories (e.g. A → B → A, all singletons) will deadlock the
                // calling thread in release builds. In DEBUG builds, circular dependencies
                // are detected earlier by `globalCircularDependencyKeys` in `resolveSlow`
                // before reaching this point. This trade-off is acceptable: circular
                // dependencies are always programmer errors, and DEBUG detection covers
                // the development cycle.
                let keyLock: MutexLock = creationLockGuard.withLock {
                    if let existing = creationLocks[key] {
                        return existing
                    } else {
                        let newLock = MutexLock()
                        creationLocks[key] = newLock
                        return newLock
                    }
                }

                return keyLock.withLock {
                    defer {
                        // Auto-prune: creation lock served its purpose, free the MutexLock.
                        // Any thread already holding a reference to this lock is unaffected.
                        creationLockGuard.withLock { _ = creationLocks.removeValue(forKey: key) }
                    }

                    // Double-check cache after acquiring per-key lock
                    if let existing = lock.withLock({ cache[key] }), let cached: T = scope.unboxed(box: existing) {
                        if let ttl = ttl {
                            let now = currentTimestamp()
                            if (existing.timestamp + ttl) > now {
                                lock.withLock { cache[key]?.timestamp = now }
                                return (cached, false)
                            }
                        } else {
                            return (cached, false)
                        }
                    }

                    let instance = factory()
                    if let boxed = scope.box(instance) {
                        lock.withLock { cache[key] = boxed }
                    }
                    return (instance, true)
                }
            }

            // Non-exclusive: create instance WITHOUT holding cache lock (first-write-wins)
            let instance = factory()

            // Write back
            if let boxed = scope.box(instance) {
                lock.withLock { cache[key] = boxed }
            }

            return (instance, true)
        }

        var cache: CacheMap
        internal init(minimumCapacity: Int = 32) {
            self.cache = .init(minimumCapacity: minimumCapacity)
        }
        internal init(copy: CacheMap) {
            self.cache = copy
        }
        internal func clone() -> Cache {
            lock.withLock { .init(copy: cache) }
        }
        /// Returns a snapshot of the cache dictionary under the internal lock.
        internal func snapshot() -> CacheMap {
            lock.withLock { cache }
        }
        /// Replaces the cache dictionary under the internal lock.
        internal func restore(_ map: CacheMap) {
            lock.withLock { cache = map }
        }
        #if DEBUG
        internal var isEmpty: Bool {
            lock.withLock { cache.isEmpty }
        }
        #endif
    }
}

// MARK: - Scope Protocols

internal protocol InternalScopeCaching {
    var cache: Scope.Cache { get }
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
