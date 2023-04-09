//
// Containers.swift
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
/// Here's an example of reaching out to a Container's shared instance for dependency resolution.
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
    /// Syntactic sugar allows container to create a factory where registration is promised before resolution.
    public func promised<T>(key: String = #function) -> Factory<T?>  {
        Factory<T?>(self, key: key) {
            #if DEBUG
            if self.manager.promiseTriggersError {
                resetAndTriggerFatalError("\(T.self) was not registered", #file, #line)
            } else {
                return nil
            }
            #else
            nil
            #endif
        }
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
/// ContainerManager also implements several functions that can be used to reset the container
/// to a pristine state, as well as push/pop methods that can save and restore the current state.
///
/// Those functions are designed primarily for testing.
public final class ContainerManager {

    /// Public initializer
    public init() {}

    /// Default scope
    public var defaultScope: Scope?

    #if DEBUG
    /// Public variable exposing dependency chain test maximum
    public var dependencyChainTestMax: Int = 8

    /// Public variable promise behavior
    public var promiseTriggersError: Bool = FactoryContext.isDebug

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

    internal func isEmpty(_ options: FactoryResetOptions) -> Bool {
        defer { globalRecursiveLock.unlock() }
        globalRecursiveLock.lock()
        switch options {
        case .all:
            return registrations.isEmpty && cache.isEmpty && self.options.isEmpty
        case .context:
            return self.options.allSatisfy { $1.argumentContexts == nil && $1.contexts == nil }
        case .none:
            return true
        case .registration:
            return registrations.isEmpty
        case .scope:
            return cache.isEmpty
        }
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
    /// Flag indicating auto registration check needs to be performed and executed if needed.
    internal var autoRegistrationCheckNeeded = true
    /// Flag indicating auto registration is in process.
    internal var autoRegistering = false
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
        defer { globalRecursiveLock.unlock()  }
        globalRecursiveLock.lock()
        switch options {
        case .all:
            self.registrations.removeAll(keepingCapacity: true)
            self.options.removeAll(keepingCapacity: true)
            self.cache.reset()
            self.autoRegistrationCheckNeeded = true
        case .context:
            for (key, option) in self.options {
                var mutable = option
                mutable.argumentContexts = nil
                mutable.contexts = nil
                self.options[key] = mutable
            }
        case .none:
            break
        case .registration:
            self.registrations.removeAll(keepingCapacity: true)
            self.autoRegistrationCheckNeeded = true
        case .scope:
            self.cache.reset()
        }
    }

    /// Clears any cached values associated with a specific scope, leaving the other scope caches intact.
    public func reset(scope: Scope) {
        defer { globalRecursiveLock.unlock()  }
        globalRecursiveLock.lock()
        switch scope {
        case is Scope.Singleton:
            #if DEBUG
            logger("FACTORY: Singleton scope not managed by container")
            #endif
            break
        default:
            cache.reset(scopeID: scope.scopeID)
        }
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
