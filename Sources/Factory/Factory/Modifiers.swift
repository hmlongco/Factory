//
// Modifiers.swift
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

/// Public protocol with functionality common to all Factory's. Used to add scope and decorator modifiers to Factory.
public protocol FactoryModifying {
    /// The parameter type of the Factory, if any. Will be `Void` on the standard Factory.
    associatedtype P
    /// The return type of the Factory's dependency.
    associatedtype T
    /// Internal information that describes this Factory.
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
    public var cached: Self {
        registration.scope(.cached)
        return self
    }
    /// Syntactic sugar defines this Factory's dependency scope to be graph. See ``Scope/Graph-swift.class``.
    /// ```swift
    /// var service: Factory<ServiceType> {
    ///     factory { MyService() }
    ///         .graph
    /// }
    /// ```
    public var graph: Self {
        registration.scope(.graph)
        return self
    }
    /// Syntactic sugar defines this Factory's dependency scope to be shared. See ``Scope/Shared-swift.class``.
    /// ```swift
    /// var service: Factory<ServiceType> {
    ///     self { MyService() }
    ///         .shared
    /// }
    /// ```
    public var shared: Self {
        registration.scope(.shared)
        return self
    }
    /// Syntactic sugar defines this Factory's dependency scope to be singleton. See ``Scope/Singleton-swift.class``.
    /// ```swift
    /// var service: Factory<ServiceType> {
    ///     self { MyService() }
    ///         .singleton
    /// }
    /// ```
    public var singleton: Self {
        registration.scope(.singleton)
        return self
    }
    /// Syntactic sugar defines defines unique scope. See ``Scope``.
    /// ```swift
    /// var service: Factory<ServiceType> {
    ///     self { MyService() }
    ///         .unique
    /// }
    /// ```
    /// While you can add the modifier, Factory's are unique by default.
    public var unique: Self {
        registration.scope(.unique)
        return self
    }

    /// Adds time to live option for scopes. If the dependency has been cached for longer than the timeToLive period the
    /// cached item will be discarded and a new instance created.
    @discardableResult
    public func timeToLive(_ seconds: TimeInterval) -> Self {
        registration.options { options in
            options.ttl = seconds
        }
        return self
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
    public func context(_ contexts: FactoryContext..., factory: @escaping (P) -> T) -> Self {
        for context in contexts {
            switch context {
            case .arg, .args, .device, .simulator:
                registration.context(context, id: registration.id, factory: factory)
            default:
                #if DEBUG
                registration.context(context, id: registration.id, factory: factory)
                #endif
                break
            }
        }
        return self
    }
    /// Factory builder shortcut for context(.arg("test") { .. }
    @discardableResult
    public func onArg(_ argument: String, factory: @escaping (P) -> T) -> Self {
        context(.arg(argument), factory: factory)
    }
    /// Factory builder shortcut for context(.args["test1","test2") { .. }
    @discardableResult
    public func onArgs(_ args: [String], factory: @escaping (P) -> T) -> Self {
        context(.args(args), factory: factory)
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
