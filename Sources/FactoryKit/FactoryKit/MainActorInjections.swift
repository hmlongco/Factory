//
//  MainActorInjections.swift
//  FactoryKit
//
//  Lock-free lazy injection for @MainActor-isolated types.
//

import Foundation

/// A lock-free lazy injection property wrapper for `@MainActor`-isolated types.
///
/// Behaves identically to ``LazyInjected`` but omits all locking since
/// main actor isolation already guarantees single-threaded access.
///
/// Swift property wrappers cannot detect their enclosing type's actor isolation,
/// so a separate wrapper is the best compromise until FactoryKit adopts Swift macros.
/// A `@Injected` macro could inspect the enclosing declaration at compile time and
/// expand to the correct code automatically — eliminating the need to choose
/// between ``LazyInjected`` and ``MainActorLazyInjected`` manually. Macros can
/// replace property wrappers entirely: an `@attached(peer)` emits a private backing
/// stored property, and `@attached(accessor)` adds get/set — no wrapper struct, no
/// lock allocation, no per-access lock acquisition. Just a plain optional + nil check.
@MainActor
@propertyWrapper
public struct MainActorLazyInjected<T> {

    private var dependency: T?
    private var initialized = false
    private let thunk: () -> Factory<T>

    /// Initializes with a keyPath into the default Container.
    public init(_ keyPath: KeyPath<Container, Factory<T>>) {
        self.thunk = { Container.shared[keyPath: keyPath] }
    }

    /// Initializes with a keyPath into a custom SharedContainer subclass.
    public init<C: SharedContainer>(_ keyPath: KeyPath<C, Factory<T>>) {
        self.thunk = { C.shared[keyPath: keyPath] }
    }

    /// The resolved dependency. Resolved lazily on first access.
    public var wrappedValue: T {
        mutating get {
            if !initialized {
                dependency = thunk()()
                initialized = true
            }
            return dependency!
        }
        mutating set {
            dependency = newValue
            initialized = true
        }
    }

    /// Projected value provides access to resolve/reset and the underlying factory.
    public var projectedValue: MainActorLazyInjected<T> {
        get { self }
        mutating set { self = newValue }
    }

    /// The underlying Factory.
    public var factory: Factory<T> {
        thunk()
    }

    /// Re-resolves the dependency, optionally resetting the factory first.
    @discardableResult
    public mutating func resolve(reset options: FactoryResetOptions = .none) -> T {
        let factory = thunk()
        factory.reset(options)
        let value = factory()
        dependency = value
        initialized = true
        return value
    }

    /// Returns the resolved dependency if it has been initialized, nil otherwise.
    public func resolvedOrNil() -> T? {
        initialized ? dependency : nil
    }
}
