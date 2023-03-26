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

    /// Id used to manage registrations and cached values. Usually looks something like "MyApp.Container.service".
    internal var id: String
    /// A strong reference to the container supporting this Factory.
    internal var container: ManagedContainer
    /// Typed factory with scope and factory.
    internal var factory: (P) -> T
    /// Once flag
    internal var once: Bool = false

    /// Initializer for registration sets passed values and default scope from container manager.
    internal init(id: String, container: ManagedContainer, factory: @escaping (P) -> T) {
        self.id = id
        self.container = container
        self.factory = factory
    }

    /// Support function performs autoRegistrationCheck and returns properly initialized container.
    internal func unsafeCheckAutoRegistration() {
        if container.manager.autoRegistrationCheckNeeded {
            container.manager.autoRegistrationCheckNeeded = false
            (container as? AutoRegistering)?.autoRegister()
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

        var factory: (P) -> T = factoryForCurrentContext(using: options)

        #if DEBUG
        if manager.dependencyChainTestMax > 0 {
            circularDependencyChainCheck(for: String(reflecting: T.self), max: manager.dependencyChainTestMax)
        }

        let traceLevel = globalTraceResolutions.count
        var traceNew = "C"
        if manager.trace {
            let wrapped = factory
            factory = {
                traceNew = "N" // detects if new instance created
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
        #endif

        #if DEBUG
        if manager.trace {
            let indent = String(repeating: "    ", count: globalGraphResolutionDepth)
            let type = type(of: instance)
            let address = Int(bitPattern: ObjectIdentifier(instance as AnyObject))
            let resolution = "\(globalGraphResolutionDepth): \(indent)\(id) = \(type) \(traceNew):\(address)"
            globalTraceResolutions[traceLevel] = resolution
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

    func factoryForCurrentContext(using options: FactoryOptions?) -> (P) -> T {
        if let options = options {
            if let contexts = options.argumentContexts, !contexts.isEmpty {
                for arg in FactoryContext.arguments {
                    if let found = contexts[arg] as? TypedFactory<P,T> {
                        return found.factory
                    }
                }
                for (_, arg) in FactoryContext.runtimeArguments {
                    if let found = contexts[arg] as? TypedFactory<P,T> {
                        return found.factory
                    }
                }
            }
            if let contexts = options.contexts, !contexts.isEmpty {
                #if DEBUG
                if FactoryContext.isPreview, let found = contexts["preview"] as? TypedFactory<P,T> {
                    return found.factory
                }
                if FactoryContext.isTest, let found = contexts["test"] as? TypedFactory<P,T> {
                    return found.factory
                }
                #endif
                if FactoryContext.isSimulator, let found = contexts["simulator"] as? TypedFactory<P,T> {
                    return found.factory
                }
                if !FactoryContext.isSimulator, let found = contexts["device"] as? TypedFactory<P,T> {
                    return found.factory
                }
                #if DEBUG
                if let found = contexts["debug"] as? TypedFactory<P,T> {
                    return found.factory
                }
                #endif
            }
        }
        if let found = container.manager.registrations[id] as? TypedFactory<P,T> {
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
        unsafeCheckAutoRegistration()
        let manager = container.manager
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
        var options = manager.options[id] ?? FactoryOptions(scope: manager.defaultScope)
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
    internal func circularDependencyChainCheck(for typeName: String, max: Int) {
        let typeComponents = typeName.components(separatedBy: CharacterSet(charactersIn: "<>"))
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
    /// Contexts
    var argumentContexts: [String:AnyFactory]?
    /// Contexts
    var contexts: [String:AnyFactory]?
    /// Decorator will be passed fully constructed instance for further configuration.
    var decorator: Any?
    /// Once flag for options
    var once: Bool = false
}

// Internal Factory type
internal protocol AnyFactory {}

internal struct TypedFactory<P,T>: AnyFactory {
    let factory: (P) -> T
}
