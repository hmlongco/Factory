//
// Factory.swift
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

// MARK: - Factory

/// A Factory manages the dependency injection process for a specific object or service.
///
/// It's used to produce an object of the desired type when required. This may be a brand new instance or Factory may
/// return a previously cached value from the specified scope.
///
/// ## Defining a Factory
/// Let's define a Factory that returns an instance of `ServiceType`. To do that we need to extend a Factory `Container` and within
/// that container we define a new computed variable of type `Factory<ServiceType>`. The type must be explicitly defined, and is usually a
/// protocol to which the returned dependency conforms.
/// ```swift
/// extension Container {
///     var service: Factory<ServiceType> {
///         Factory(self) { MyService() }
///     }
/// }
/// ```
/// Inside the computed variable we define our Factory, passing it a reference to the enclosing container. We also provide it with
/// a closure that creates an instance of our dependency when required. That Factory is then returned to the caller, usually to be evaluated
/// (see `callAsFunction()` below). Every time we resolve this factory we'll get a new, unique instance of our object.
///
/// Factory also provides a bit of syntactic sugar that lets us do the same thing in a more convenient form,
/// ```swift
/// extension Container {
///     var service: Factory<ServiceType> {
///         self { MyService() }
///     }
/// }
/// ```
///
/// ## Transient
/// If you're concerned about building Factory's on the fly, don't be. Like SwiftUI Views, Factory structs and modifiers
/// are lightweight and transitory. They're created when needed and then immediately discarded once their purpose has
/// been served.
///
/// Other operations exist for Factory. See ``FactoryModifying``.
public struct Factory<T>: FactoryModifying {

    /// Public initializer creates a Factory capable of managing dependencies of the desired type.
    ///
    /// - Parameters:
    ///   - container: The bound container that manages registrations and scope caching for this Factory. The scope helper functions bind the
    ///   current container as well defining the scope.
    ///   - key: Hidden value used to differentiate different instances of the same type in the same container.
    ///   - factory: A factory closure that produces an object of the desired type when required.
    public init(_ container: ManagedContainer, key: String = #function, _ factory: @escaping () -> T) {
        self.registration = FactoryRegistration<Void,T>(key: key, container: container, factory: factory)
    }

    /// Evaluates the factory and returns an object or service of the desired type. The resolved instance may be brand new or Factory may
    /// return a cached value from the specified scope.
    ///
    /// To resolve the Factory  one simply calls the Factory as a function. Here we use the `shared` container that's provided for each
    /// and every container type.
    /// ```swift
    /// let service = Container.shared.service()
    /// ```
    /// The resolved instance may be brand new or Factory may return a cached value from the specified ``Scope``.
    ///
    /// If you're passing an instance of a container around to your views or view models, just call it directly.
    /// ```swift
    /// let service = container.service()
    /// ```
    /// Finally, you can also use the @Injected property wrapper and specify a keyPaths to the desired dependency.
    /// ```swift
    /// @Injected(\.service) var service: ServiceType
    /// ```
    /// Unless otherwise specified, the @Injected property wrapper looks for dependencies in the standard shared container provided by Factory,
    /// so the above example is functionally identical to the `Container.shared.service()` example shown earlier. Here's one pointing to
    /// your own container.
    /// ```swift
    /// @Injected(\MyCustomContainer.service) var service: ServiceType
    /// ```
    /// - Returns: An object or service of the desired type.
    public func callAsFunction() -> T {
        registration.resolve(with: ())
    }

    /// Unsugared resolution function.
    public func resolve() -> T {
        registration.resolve(with: ())
    }

    /// Registers a new factory closure capable of producing an object or service of the desired type.
    ///
    /// This factory overrides the original factory closure and clears the associated scope so that the next time this factory is resolved
    /// Factory will evaluate the new closure and return an instance of the newly registered object instead.
    ///
    /// Here's an example of registering a new Factory closure.
    /// ```swift
    /// container.service.register {
    ///     SomeService()
    /// }
    /// ```
    /// This is how default functionality is overridden in order to change the nature of the system at runtime, and is the primary mechanism
    /// used to provide mocks and testing doubles.
    ///
    /// Registration "overrides" are stored in the associated container. If the container ever goes our of scope, so
    /// will all of its registrations.
    ///
    /// The original factory closure is preserved, and may be restored by resetting the Factory to its original state.
    ///
    /// - Parameters:
    ///  - factory: A new factory closure that produces an object of the desired type when needed.
    /// Allows updating registered factory and scope.
    @discardableResult
    public func register(factory: @escaping () -> T) -> Self {
        registration.register(factory)
        return self
    }

    /// Internal parameters for this Factory including id, container, the factory closure itself, the scope,
    /// and others.
    public var registration: FactoryRegistration<Void,T>

}

// MARK: - ParameterFactory

/// Factory capable of taking parameters at runtime
///
/// Like it or not, some services require one or more parameters to be passed to them in order to be initialized correctly. In that case use `ParameterFactory`.
///
/// We define a ParameterFactory exactly as we do a normal factory with two exceptions: we need to specify the
/// parameter type, and we need to consume the passed parameter in our factory closure.
/// ```swift
/// extension Container {
///     var parameterService: ParameterFactory<Int, MyServiceType> {
///        self { ParameterService(value: $0) }
///     }
/// }
/// ```
/// Resolving it is straightforward. Just pass the parameter to the Factory.
/// ```Swift
/// let myService = Container.shared.parameterService(n)
/// ```
/// One caveat is that you can't use the `@Injected` property wrapper with `ParameterFactory` as there's no way to get
/// the needed parameters to the property wrapper before the wrapper is initialized. That being the case, you'll
/// probably need to reference the container directly and do something similar to the following.
///  ```swift
///  class MyClass {
///      var myService: MyServiceType
///      init(_ n: Int) {
///          myService = Container.shared.parameterService(n)
///      }
///  }
/// ```
/// If you need to pass more than one parameter just use a tuple, dictionary, or struct.
/// ```swift
/// var tupleService: ParameterFactory<(Int, Int), MultipleParameterService> {
///     self { (a, b) in
///         MultipleParameterService(a: a, b: b)
///     }
/// }
/// ```
/// Finally, if you define a scope keep in mind that the first argument passed will be used to create the dependency
/// and *that* dependency will be cached. Since the cached object will be returned from now on any arguments passed in
/// later requests will be ignored until the factory or scope is reset.
public struct ParameterFactory<P,T>: FactoryModifying {

    /// Public initializer creates a factory capable of taking parameters at runtime.
    /// ```swift
    /// var parameterService: ParameterFactory<Int, ParameterService> {
    ///     self { ParameterService(value: $0) }
    /// }
    /// ```
    /// - Parameters:
    ///   - container: The bound container that manages registrations and scope caching for this Factory. The scope helper functions bind the
    ///   current container as well defining the scope.
    ///   - key: Hidden value used to differentiate different instances of the same type in the same container.
    ///   - factory: A factory closure that produces an object of the desired type when required.
    public init(_ container: ManagedContainer, key: String = #function, _ factory: @escaping (P) -> T) {
        self.registration = FactoryRegistration<P,T>(key: key, container: container, factory: factory)
    }

    /// Resolves a factory capable of taking parameters at runtime.
    /// ```swift
    /// let service = container.parameterService(16)
    /// ```
    public func callAsFunction(_ parameters: P) -> T {
        registration.resolve(with: parameters)
    }

    /// Unsugared resolution function.
    public func resolve(_ parameters: P) -> T {
        registration.resolve(with: parameters)
    }

    /// Registers a new factory capable of taking parameters at runtime.
    /// ```swift
    /// container.parameterService.register { n in
    ///     ParameterService(value: n)
    /// }
    /// ```
    /// - Parameters:
    ///  - factory: A new factory closure that produces an object of the desired type when needed.
    @discardableResult
    public func register(factory: @escaping (P) -> T) -> Self {
        registration.register(factory)
        return self
    }

    /// Required registration
    public var registration: FactoryRegistration<P,T>

}
