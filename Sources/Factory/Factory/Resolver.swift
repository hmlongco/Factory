//
//  Resolver.swift
//  
//
//  Created by Michael Long on 4/30/23.
//

import Foundation

/// When protocol is applied to a container it enables a typed registration/resolution mode.
public protocol Resolving: ManagedContainer {

    /// Registers a new type and associated factory closure with this container.
    func register<T>(_ type: T.Type, factory: @escaping () -> T) -> Factory<T>

    /// Returns a registered factory for this type from this container.
    func factory<T>(_ type: T.Type) -> Factory<T>?

    /// Resolves a type from this container.
    func resolve<T>(_ type: T.Type) -> T?

}

extension Resolving {

    /// Registers a new type and associated factory closure with this container.
    ///
    /// Also returns Factory for further specialization for scopes, decorators, etc.
    @discardableResult
    public func register<T>(_ type: T.Type = T.self, factory: @escaping () -> T) -> Factory<T> {
        defer { globalRecursiveLock.unlock() }
        globalRecursiveLock.lock()
        // Perform autoRegistration check
        unsafeCheckAutoRegistration()
        // Add register to persist in container, and return factory so user can specialize if desired
        return Factory(self, key: "*", factory).register(factory: factory)
    }

    /// Returns a registered factory for this type from this container. Use this function to set options and previews after the initial
    /// registration.
    ///
    /// Note that nothing will be applied if initial registration is not found.
    public func factory<T>(_ type: T.Type = T.self) -> Factory<T>? {
        defer { globalRecursiveLock.unlock() }
        globalRecursiveLock.lock()
        // Perform autoRegistration check
        unsafeCheckAutoRegistration()
        // if we have a registration for this type, then build registration and factory for it
        if let factory = manager.registrations["*<\(String(reflecting: type))>"] as? TypedFactory<Void,T> {
            return Factory(FactoryRegistration<Void,T>(key: "*", container: self, factory: factory.factory))
        }
        // otherwise return nil
        return nil
    }

    /// Resolves a type from this container.
    public func resolve<T>(_ type: T.Type = T.self) -> T? {
        return factory(type)?.registration.resolve(with: ())
    }

}

extension Factory {
    fileprivate init(_ registration: FactoryRegistration<Void,T>) {
        self.registration = registration
    }
}
