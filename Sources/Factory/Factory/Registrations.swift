//
// Registrations.swift
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

/// Shared registration type for Factory and ParameterFactory. Used internally to manage the registration and resolution process.
public struct FactoryRegistration<P,T> {

    /// Type string for id and circular dependency chain check
    public let type: String
    /// ID used to manage registrations and cached values. Usually looks something like "service<MyApp.MyService>".
    public let id: String
    /// A strong reference to the container supporting this Factory.
    internal let container: ManagedContainer
    /// Typed factory with scope and factory.
    internal let factory: (P) -> T

    /// Mutable once flag
    internal var once: Bool = false

    /// Initializer for registration sets passed values and default scope from container manager.
    internal init(key: String, container: ManagedContainer, factory: @escaping (P) -> T) {
        self.type = String(reflecting: T.self) // expensive, only do once
        self.id = "\(key)<\(type)>"
        self.container = container
        self.factory = factory
    }

    /// Support function performs autoRegistrationCheck and returns properly initialized container.
    internal func unsafeCheckAutoRegistration() {
        if container.manager.autoRegistrationCheckNeeded {
            container.manager.autoRegistrationCheckNeeded = false
            container.manager.autoRegistering = true
            (container as? AutoRegistering)?.autoRegister()
            container.manager.autoRegistering = false
        }
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

        unsafeCheckAutoRegistration()

        let manager = container.manager
        let options = manager.options[id]
        let scope = options?.scope ?? manager.defaultScope
        let ttl = options?.ttl

        var current: (P) -> T

        if let found = options?.factoryForCurrentContext() as? TypedFactory<P,T> {
            current = found.factory
        } else if let found = manager.registrations[id] as? TypedFactory<P,T> {
            current = found.factory
        } else {
            current = factory
        }

        #if DEBUG
        if manager.dependencyChainTestMax > 0 {
            circularDependencyChainCheck(max: manager.dependencyChainTestMax)
        }

        let traceLevel = globalTraceResolutions.count
        var traceNew: String?
        if manager.trace {
            let wrapped = current
            current = {
                traceNew = "N" // detects if new instance created
                return wrapped($0)
            }
            globalTraceResolutions.append("")
        }
        #endif

        globalGraphResolutionDepth += 1
        let instance = scope?.resolve(using: manager.cache, id: id, ttl: ttl, factory: { current(parameters) }) ?? current(parameters)
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
            let indent = String(repeating: "    ", count: globalGraphResolutionDepth)
            let address = (((instance as? OptionalProtocol)?.hasWrappedValue ?? true)) ? Int(bitPattern: ObjectIdentifier(instance as AnyObject)) : 0
            let resolution = address == 0 ? "nil" : "\(traceNew ?? "C"):\(address)"
            globalTraceResolutions[traceLevel] = "\(globalGraphResolutionDepth): \(indent)\(container).\(id) = \(resolution)"
            if globalGraphResolutionDepth == 0 {
                globalTraceResolutions.forEach { globalLogger($0) }
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

    /// Registers a new factory closure capable of producing an object or service of the desired type. This factory overrides the original factory and
    /// the next time this factory is resolved Factory will evaluate the newly registered factory instead.
    /// - Parameters:
    ///   - id: ID of associated Factory.
    ///   - factory: Factory closure called to create a new instance of the service when needed.
    internal func register(_ factory: @escaping (P) -> T) {
        defer { globalRecursiveLock.unlock()  }
        globalRecursiveLock.lock()
        unsafeCheckAutoRegistration()
        if unsafeCanUpdateOptions() {
            let manager = container.manager
            manager.registrations[id] = TypedFactory(factory: factory)
            if manager.autoRegistering == false, let scope = manager.options[id]?.scope {
                let cache = (scope as? InternalScopeCaching)?.cache ?? manager.cache
                cache.removeValue(forKey: id)
            }
        }
    }

    /// Registers a new factory scope.
    /// - Parameter: - scope: New scope
    internal func scope(_ scope: Scope?) {
        defer { globalRecursiveLock.unlock()  }
        globalRecursiveLock.lock()
        unsafeCheckAutoRegistration()
        let manager = container.manager
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
        unsafeCheckAutoRegistration()
        let manager = container.manager
        var options = manager.options[id] ?? FactoryOptions()
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
        defer { globalRecursiveLock.unlock()  }
        globalRecursiveLock.lock()
        let manager = container.manager
        switch options {
        case .all:
            let cache = (manager.options[id]?.scope as? InternalScopeCaching)?.cache ?? manager.cache
            cache.removeValue(forKey: id)
            manager.registrations.removeValue(forKey: id)
            manager.options.removeValue(forKey: id)
        case .context:
            self.options {
                $0.argumentContexts = nil
                $0.contexts = nil
            }
        case .none:
            break
        case .registration:
            manager.registrations.removeValue(forKey: id)
        case .scope:
            let cache = (manager.options[id]?.scope as? InternalScopeCaching)?.cache ?? manager.cache
            cache.removeValue(forKey: id)
        }
    }

    #if DEBUG
    internal func circularDependencyChainCheck(max: Int) {
        let typeComponents = type.components(separatedBy: CharacterSet(charactersIn: "<>"))
        let typeName = typeComponents.count > 1 ? typeComponents[1] : typeComponents[0]
        let typeIndex = globalDependencyChain.firstIndex(where: { $0 == typeName })
        globalDependencyChain.append(typeName)
        if let index = typeIndex {
            let chain = globalDependencyChain[index...]
            let message = "FACTORY: Circular dependency chain - \(chain.joined(separator: " > "))"
            if globalDependencyChainMessages.filter({ $0 == message }).count == max {
                resetAndTriggerFatalError(message, #file, #line)
            } else {
                globalDependencyChain = [typeName]
                globalDependencyChainMessages.append(message)
            }
        }
    }
    #endif

}

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
            for arg in FactoryContext.arguments {
                if let found = contexts[arg] {
                    return found
                }
            }
            for (_, arg) in FactoryContext.runtimeArguments {
                if let found = contexts[arg] {
                    return found
                }
            }
        }
        if let contexts = contexts, !contexts.isEmpty {
            #if DEBUG
            if FactoryContext.isPreview, let found = contexts["preview"] {
                return found
            }
            if FactoryContext.isTest, let found = contexts["test"] {
                return found
            }
            #endif
            if FactoryContext.isSimulator, let found = contexts["simulator"] {
                return found
            }
            if !FactoryContext.isSimulator, let found = contexts["device"] {
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
