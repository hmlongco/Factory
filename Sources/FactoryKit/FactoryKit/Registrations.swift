//
// Registrations.swift
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

import Foundation

/// Shared registration type for Factory and ParameterFactory. Used internally to manage the registration and resolution process.
public nonisolated struct FactoryRegistration<P,T> {

    /// Key used to manage registrations and cached values.
    internal let key: FactoryKey
    /// A strong reference to the container supporting this Factory.
    internal let container: ManagedContainer
    /// Typed factory with scope and factory.
    internal let factory: ParameterFactoryType<P, T>

    /// Mutable once flag
    internal var once: Bool = false

    /// Initializer for registration sets passed values and default scope from container manager.
    internal init(key: StaticString, container: ManagedContainer, factory: @escaping ParameterFactoryType<P,T>) {
        self.key = FactoryKey(type: T.self, key: key)
        self.container = container
        self.factory = factory
    }

    /// Resolves a Factory, returning an instance of the desired type. All roads lead here.
    ///
    /// - Parameter factory: Factory wanting resolution.
    /// - Returns: Instance of the desired type.
    internal func resolve(with parameters: P) -> T {
        defer { globalRecursiveLock.unlock()  }
        globalRecursiveLock.lock()

        container.unsafeCheckAutoRegistration()

        let manager: ContainerManager = container.manager
        let options: FactoryOptions? = manager.options[key]

        var current: (P) -> T

        #if DEBUG
        let traceIndex: Int = globalTraceResolutions.count
        let traceLevel: Int = Scope.graph.depth
        var traceNewType: String
        #endif

        if let found = options?.factoryForCurrentContext() as? TypedFactory<P,T> {
            #if DEBUG
            traceNewType = "O" // .onTest, .onDebug, etc.
            #endif
            current = found.factory
        } else if let found = manager.registrations[key] as? TypedFactory<P,T> {
            #if DEBUG
            traceNewType = "R" // .register {}
            #endif
            current = found.factory
        } else {
            #if DEBUG
            traceNewType = "F" // Factory { ... }
            #endif
            current = factory
        }

        #if DEBUG
        if globalTraceFlag {
            let indent = String(repeating: "    ", count: traceLevel)
            let entry = "\(traceLevel): \(indent)\(type(of: container)).\(key.key)<\(T.self)>"
            globalTraceResolutions.append(entry)
        }

        if globalCircularDependencyTesting, globalCircularDependencyKeys.insert(key).0 == false {
            globalTraceResolutions.forEach { globalLogger($0) }
            let message = "FACTORY: Circular dependency on \(type(of: container)).\(key.key)"
            resetAndTriggerFatalError(message, #file, #line)
        }
        #endif

        Scope.graph.enter()

        let (instance, instantiated): (T, Bool)
        if let scope = options?.scope ?? manager.defaultScope {
            let parameterizedKey = options?.scopeOnParameters == true ? key.parameterized(parameters) : key
            (instance, instantiated) = scope.resolve(using: manager.cache, key: parameterizedKey, ttl: options?.ttl, factory: { current(parameters) }) }
        else {
            (instance, instantiated) = (current(parameters), true)
        }

        Scope.graph.leave()

        #if DEBUG
        if globalCircularDependencyTesting {
            globalCircularDependencyKeys.remove(key)
        }

        if globalTraceFlag {
            let address = Int(bitPattern: ObjectIdentifier(instance as AnyObject))
            let type = type(of: instance as Any)
            let entry = globalTraceResolutions[traceIndex]
            globalTraceResolutions[traceIndex] = "\(entry) = \(instantiated ? traceNewType : "C"):\(address) \(type)"
            if traceLevel == 0 {
                globalTraceResolutions.forEach { globalLogger($0) }
                globalTraceResolutions = []
            }
        }
        #endif

        if let decorator = options?.decorator as? (T, Bool) -> Void {
            decorator(instance, instantiated)
        }
        if let decorator = manager.state.decorator {
            decorator(instance)
        }

        return instance
    }

}

extension FactoryRegistration {

    /// Registers a new factory closure capable of producing an object or service of the desired type. This factory overrides the original factory and
    /// the next time this factory is resolved Factory will evaluate the newly registered factory instead.
    /// - Parameters:
    ///   - id: ID of associated Factory.
    ///   - factory: Factory closure called to create a new instance of the service when needed.
    internal func register(_ factory: @escaping (P) -> T) {
        defer { globalRecursiveLock.unlock()  }
        globalRecursiveLock.lock()
        container.unsafeCheckAutoRegistration()
        if unsafeCanUpdateOptions() {
            let manager = container.manager
            manager.registrations[key] = TypedFactory(factory: factory)
            if manager.autoRegistering == false, let scope = manager.options[key]?.scope {
                let cache = (scope as? InternalScopeCaching)?.cache ?? manager.cache
                cache.removeValue(forKey: key)
            }
        }
    }

    /// Registers a new factory scope.
    /// - Parameter: - scope: New scope
    internal func scope(_ scope: Scope?) {
        defer { globalRecursiveLock.unlock()  }
        globalRecursiveLock.lock()
        container.unsafeCheckAutoRegistration()
        let manager = container.manager
        if var options = manager.options[key] {
            if once == options.once && scope !== options.scope {
                options.scope = scope
                manager.options[key] = options
                manager.cache.removeValue(forKey: key)
            }
        } else {
            manager.options[key] = FactoryOptions(scope: scope)
        }
    }

    /// Registers a new context.
    internal func context(_ context: FactoryContextType, key: FactoryKey, factory: @escaping (P) -> T) {
        options { options in
            switch context {
            case .arg(let arg):
                if options.argumentContexts == nil {
                    options.argumentContexts = [:]
                }
                options.argumentContexts?[arg] = TypedFactory(factory: factory)
            case .args(let args):
                if options.argumentContexts == nil {
                    options.argumentContexts = [:]
                }
                args.forEach { arg in
                    options.argumentContexts?[arg] = TypedFactory(factory: factory)
                }
            default:
                if options.contexts == nil {
                    options.contexts = [:]
                }
                options.contexts?["\(context)"] = TypedFactory(factory: factory)
            }
            // #146 container.manager.cache.removeValue(forKey: key)
        }
    }

    /// Registers a new decorator.
    internal func decorator(_ decorator: @escaping (T, Bool) -> Void) {
        options { options in
            options.decorator = decorator
        }
    }

    /// Support function resets the behavior for a specific Factory to its original state, removing any associated registrations and clearing
    /// any cached instances from the specified scope.
    /// - Parameters:
    ///   - options: Reset option: .all, .registration, .scope, .none
    ///   - id: ID of item to remove from the appropriate cache.
    internal func reset(options: FactoryResetOptions) {
        defer { globalRecursiveLock.unlock()  }
        globalRecursiveLock.lock()
        let manager = container.manager
        switch options {
        case .all:
            let cache = (manager.options[key]?.scope as? InternalScopeCaching)?.cache ?? manager.cache
            cache.removeValue(forKey: key)
            manager.registrations.removeValue(forKey: key)
            manager.options.removeValue(forKey: key)
        case .context:
            self.options {
                $0.argumentContexts = nil
                $0.contexts = nil
            }
        case .none:
            break
        case .registration:
            manager.registrations.removeValue(forKey: key)
        case .scope:
            let cache = (manager.options[key]?.scope as? InternalScopeCaching)?.cache ?? manager.cache
            cache.removeValue(forKey: key)
        }
    }

    /// Support function for options mutation.
    internal func options(mutate: (_ options: inout FactoryOptions) -> Void) {
        defer { globalRecursiveLock.unlock()  }
        globalRecursiveLock.lock()
        container.unsafeCheckAutoRegistration()
        let manager = container.manager
        var options = manager.options[key] ?? FactoryOptions()
        if options.once == once {
            mutate(&options)
            manager.options[key] = options
        }
    }

    /// Support function for one-time only option updates
    internal func unsafeCanUpdateOptions() -> Bool {
        let options = container.manager.options[key]
        return options == nil || options?.once == once
    }

}

extension FactoryRegistration: @unchecked Sendable where P: Sendable, T: Sendable {}

// MARK: - Protocols and Types

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

internal struct FactoryOptions {
    /// Managed scope for this factory instance
    var scope: Scope?
    /// Scope cache value also based on ParameterFactory parameter
    var scopeOnParameters: Bool = false
    /// Time to live option for scopes
    var ttl: TimeInterval?
    /// Contexts
    var argumentContexts: [String:AnyFactory]?
    /// Contexts
    var contexts: [String:AnyFactory]?
    /// Decorator will be passed fully constructed instance for further configuration.
    var decorator: Any?
    /// Once flag for options
    var once: Bool = false
}

extension FactoryOptions {
    /// Internal function to return factory based on current context
    func factoryForCurrentContext() -> AnyFactory?  {
        if let contexts = argumentContexts, !contexts.isEmpty {
            for arg in FactoryContext.current.arguments {
                if let found = contexts[arg] {
                    return found
                }
            }
            for (_, arg) in FactoryContext.current.runtimeArguments {
                if let found = contexts[arg] {
                    return found
                }
            }
        }
        if let contexts = contexts, !contexts.isEmpty {
            #if DEBUG
            if FactoryContext.current.isPreview, let found = contexts["preview"] {
                return found
            }
            if FactoryContext.current.isTest, let found = contexts["test"] {
                return found
            }
            #endif
            if FactoryContext.current.isSimulator, let found = contexts["simulator"] {
                return found
            }
            if !FactoryContext.current.isSimulator, let found = contexts["device"] {
                return found
            }
            #if DEBUG
            if let found = contexts["debug"] {
                return found
            }
            #endif
        }
        return nil
    }

}

// Internal Factory type
internal protocol AnyFactory {}

internal struct TypedFactory<P,T>: AnyFactory {
    let factory: (P) -> T
}
