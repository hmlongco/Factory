//
// Resolver.swift
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
        return Factory(self, key: globalResolverKey, factory).register(factory: factory)
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
        let key = FactoryKey(type: T.self, key: globalResolverKey)
        if let factory = manager.registrations[key] as? TypedFactory<Void,T> {
            return Factory(FactoryRegistration<Void,T>(key: globalResolverKey, container: self, factory: factory.factory))
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
