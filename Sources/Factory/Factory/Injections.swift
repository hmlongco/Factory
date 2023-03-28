//
// Injections.swift
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

#if canImport(SwiftUI)
import SwiftUI
#endif

#if swift(>=5.1)

/// Convenience property wrapper takes a factory and resolves an instance of the desired type.
///
/// Property wrappers implement an annotation pattern to resolving dependencies, similar to using
/// EnvironmentObject in SwiftUI.
/// ```swift
/// class MyViewModel {
///    @Injected(\.myService) var service
///    @Injected(\MyCustomContainer.myService) var service
/// }
/// ```
/// The provided keypath resolves to a Factory definition on the `shared` container required for each Container type.
/// The short version of the keyPath resolves to the default container, while the expanded version
/// allows you to point an instance on your own customer container type.
///
/// > Note: The @Injected property wrapper will be resolved on **initialization**. In the above example
/// the referenced dependencies will be acquired when the parent class is created.
@propertyWrapper public struct Injected<T> {

    private var reference: BoxedFactoryReference
    private var dependency: T

    /// Initializes the property wrapper. The dependency is resolved on initialization.
    /// - Parameter keyPath: KeyPath to a Factory on the default Container.
    public init(_ keyPath: KeyPath<Container, Factory<T>>) {
        self.reference = FactoryReference<Container, T>(keypath: keyPath)
        self.dependency = Container.shared[keyPath: keyPath]()
    }

    /// Initializes the property wrapper. The dependency is resolved on initialization.
    /// - Parameter keyPath: KeyPath to a Factory on the specified Container.
    public init<C:SharedContainer>(_ keyPath: KeyPath<C, Factory<T>>) {
        self.reference = FactoryReference<C, T>(keypath: keyPath)
        self.dependency = C.shared[keyPath: keyPath]()
    }

    /// Manages the wrapped dependency.
    public var wrappedValue: T {
        get { return dependency }
        mutating set { dependency = newValue }
    }

    /// Unwraps the property wrapper granting access to the resolve/reset function.
    public var projectedValue: Injected<T> {
        get { return self }
        mutating set { self = newValue }
    }

    /// Grants access to the internal Factory.
    public var factory: Factory<T> {
        reference.factory()
    }

    /// Allows the user to force a Factory resolution at their discretion.
    public mutating func resolve(reset options: FactoryResetOptions = .none) {
        factory.reset(options)
        dependency = factory.resolve()
    }
}

/// Convenience property wrapper takes a factory and resolves an instance of the desired type the first time the wrapped value is requested.
///
/// Property wrappers implement an annotation pattern to resolving dependencies, similar to using
/// EnvironmentObject in SwiftUI.
/// ```swift
/// class MyViewModel {
///    @LazyInjected(\.myService) var service
///    @LazyInjected(\MyCustomContainer.myService) var service
/// }
/// ```
/// The provided keypath resolves to a Factory definition on the `shared` container required for each Container type.
/// The short version of the keyPath resolves to the default container, while the expanded version
/// allows you to point an instance on your own customer container type.
///
/// > Note: Lazy injection is resolved the first time the dependency is referenced by the code, and **not** on initialization.
@propertyWrapper public struct LazyInjected<T> {

    private var reference: BoxedFactoryReference
    private var dependency: T!
    private var initialize = true

    /// Initializes the property wrapper. The dependency isn't resolved until the wrapped value is accessed for the first time.
    /// - Parameter keyPath: KeyPath to a Factory on the default Container.
    public init(_ keyPath: KeyPath<Container, Factory<T>>) {
        self.reference = FactoryReference<Container, T>(keypath: keyPath)
    }

    /// Initializes the property wrapper. The dependency isn't resolved until the wrapped value is accessed for the first time.
    /// - Parameter keyPath: KeyPath to a Factory on the specified Container.
    public init<C:SharedContainer>(_ keyPath: KeyPath<C, Factory<T>>) {
        self.reference = FactoryReference<C, T>(keypath: keyPath)
    }

    /// Manages the wrapped dependency, which is resolved when this value is accessed for the first time.
    public var wrappedValue: T {
        mutating get {
            defer { globalRecursiveLock.unlock()  }
            globalRecursiveLock.lock()
            if initialize {
                resolve()
            }
            return dependency
        }
        mutating set {
            dependency = newValue
        }
    }

    /// Unwraps the property wrapper granting access to the resolve/reset function.
    public var projectedValue: LazyInjected<T> {
        get { return self }
        mutating set { self = newValue }
    }

    /// Grants access to the internal Factory.
    public var factory: Factory<T> {
        reference.factory()
    }

    /// Allows the user to force a Factory resolution at their discretion.
    public mutating func resolve(reset options: FactoryResetOptions = .none) {
        factory.reset(options)
        dependency = factory()
        initialize = false
    }
}

/// Convenience property wrapper takes a factory and resolves an instance of the desired type the first time the wrapped value is requested.
///
/// This wrapper maintains a weak reference to the object in question, so it must exist elsewhere.t
/// It's useful for delegate patterns and parent/child relationships.
///
/// Property wrappers implement an annotation pattern to resolving dependencies, similar to using
/// EnvironmentObject in SwiftUI.
///
/// ```swift
/// class MyViewModel {
///    @LazyInjected(\.myService) var service
///    @LazyInjected(\MyCustomContainer.myService) var service
/// }
/// ```
/// The provided keypath resolves to a Factory definition on the `shared` container required for each Container type.
/// The short version of the keyPath resolves to the default container, while the expanded version
/// allows you to point an instance on your own customer container type.
///
/// > Note: Lazy injection is resolved the first time the dependency is referenced by the code, **not** on initialization.
@propertyWrapper public struct WeakLazyInjected<T> {

    private var reference: BoxedFactoryReference
    private weak var dependency: AnyObject?
    private var initialize = true

    /// Initializes the property wrapper. The dependency isn't resolved until the wrapped value is accessed for the first time.
    /// - Parameter keyPath: KeyPath to a Factory on the default Container.
    public init(_ keyPath: KeyPath<Container, Factory<T>>) {
        self.reference = FactoryReference<Container, T>(keypath: keyPath)
    }

    /// Initializes the property wrapper. The dependency isn't resolved until the wrapped value is accessed for the first time.
    /// - Parameter keyPath: KeyPath to a Factory on the specified Container.
    public init<C:SharedContainer>(_ keyPath: KeyPath<C, Factory<T>>) {
        self.reference = FactoryReference<C, T>(keypath: keyPath)
    }

    /// Manages the wrapped dependency, which is resolved when this value is accessed for the first time.
    public var wrappedValue: T? {
        mutating get {
            defer { globalRecursiveLock.unlock()  }
            globalRecursiveLock.lock()
            if initialize {
                resolve()
            }
            return dependency as? T
        }
        mutating set {
            dependency = newValue as AnyObject
        }
    }

    /// Unwraps the property wrapper granting access to the resolve/reset function.
    public var projectedValue: WeakLazyInjected<T> {
        get { return self }
        mutating set { self = newValue }
    }

    /// Grants access to the internal Factory.
    public var factory: Factory<T> {
        reference.factory()
    }

    /// Allows the user to force a Factory resolution at their discretion.
    public mutating func resolve(reset options: FactoryResetOptions = .none) {
        factory.reset(options)
        dependency = factory() as AnyObject
        initialize = false
    }
}

#if os(iOS) || os(macOS) || os(tvOS) || os(watchOS)
/// Immediate injection property wrapper for SwiftUI ObservableObjects.
///
/// This wrapper is meant for use in SwiftUI Views and exposes bindable objects similar to that of SwiftUI @StateObject
/// and @EnvironmentObject.
///
/// Like the other Injected property wrappers, InjectedObject wraps obtains the dependency from the Factory keypath
/// and provides it to a wrapped instance of StateObject. Updating object state will trigger view update.
/// ```swift
/// struct ContentView: View {
///     @InjectedObject(\.contentViewModel) var model
///     var body: some View {
///         ...
///     }
/// }
/// ```
/// ContentViewModel must, of course, be of type ObservableObject and is registered like any other service
/// or dependency.
/// ```swift
/// extension Container {
///     var contentViewModel: Factory<ContentViewModel> {
///         self { ContentViewModel() }
///     }
/// }
/// ```
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
@frozen @propertyWrapper public struct InjectedObject<T>: DynamicProperty where T: ObservableObject {
    @StateObject fileprivate var dependency: T
    /// Initializes the property wrapper. The dependency is resolved on initialization.
    /// - Parameter keyPath: KeyPath to a Factory on the default Container.
    public init(_ keyPath: KeyPath<Container, Factory<T>>) {
        self._dependency = StateObject(wrappedValue: Container.shared[keyPath: keyPath]())
    }
    /// Initializes the property wrapper. The dependency is resolved on initialization.
    /// - Parameter keyPath: KeyPath to a Factory on the specified Container.
    public init<C:SharedContainer>(_ keyPath: KeyPath<C, Factory<T>>) {
        self._dependency = StateObject(wrappedValue: C.shared[keyPath: keyPath]())
    }
    /// Manages the wrapped dependency.
    @MainActor public var wrappedValue: T {
        get { dependency }
    }
    /// Manages the wrapped dependency.
    @MainActor public var projectedValue: ObservedObject<T>.Wrapper {
        return $dependency
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension InjectedObject {
    /// Simple initializer with passed parameter bypassing injection.
    ///
    /// Still has issue with attempting to pass dependency into existing view when existing InjectedObject has keyPath.
    /// https://forums.swift.org/t/allow-property-wrappers-with-multiple-arguments-to-defer-initialization-when-wrappedvalue-is-not-specified
    public init(_ wrappedValue: T) {
        self._dependency = StateObject(wrappedValue: wrappedValue)
    }
}
#endif

/// Boxed wrapper to provide a Factory when asked
internal protocol BoxedFactoryReference {
    func factory<T>() -> Factory<T>
}

/// Helps resolve a reference to an injected factory's shared container without actually storing a Factory along
/// with its hard, reference-counted pointer to that container.
internal struct FactoryReference<C: SharedContainer, T>: BoxedFactoryReference {
    /// The stored factory keypath on the container
    let keypath: KeyPath<C, Factory<T>>
    /// Resolves the current shared container on the given type and returns the Factory referenced by the keyPath.
    /// Note that types matched going in, so it's safe to explicitly cast it coming back out.
    func factory<T>() -> Factory<T> {
        C.shared[keyPath: keypath] as! Factory<T>
    }
}

#endif
