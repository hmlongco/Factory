//
// Injections.swift
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

#if canImport(SwiftUI)
import Combine
import Observation
import SwiftUI
#endif

/// Convenience property wrapper takes a factory and resolves an instance of the desired type.
///
/// Property wrappers implement an annotation pattern to resolving dependencies, similar to using
/// EnvironmentObject in SwiftUI.
/// ```swift
/// class MyViewModel {
///    @Injected(\.myService) var service1
///    @Injected(\MyCustomContainer.myService) var service2
/// }
/// ```
/// The provided keypath resolves to a Factory definition on the `shared` container required for each Container type.
/// The short version of the keyPath resolves to the default container, while the expanded version
/// allows you to point an instance of your own custom container type.
///
/// > Note: The @Injected property wrapper will be resolved on **initialization**. In the above example
/// the referenced dependencies will be acquired when the parent class is created.
@propertyWrapper public struct Injected<T> {

    private var thunk: () -> Factory<T>
    private var dependency: T

    /// Initializes the property wrapper. The dependency is resolved on initialization.
    /// - Parameter keyPath: KeyPath to a Factory on the default Container.
    public init(_ keyPath: KeyPath<Container, Factory<T>>) {
        self.thunk = { Container.shared[keyPath: keyPath] }
        self.dependency = Container.shared[keyPath: keyPath]()
    }

    /// Initializes the property wrapper. The dependency is resolved on initialization.
    /// - Parameter keyPath: KeyPath to a Factory on the specified Container.
    public init<C:SharedContainer>(_ keyPath: KeyPath<C, Factory<T>>) {
        self.thunk = { C.shared[keyPath: keyPath] }
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
        set { self = newValue }
    }

    /// Grants access to the internal Factory.
    public var factory: Factory<T> {
        thunk()
    }

    /// Allows the user to force a Factory resolution at their discretion.
    public mutating func resolve(reset options: FactoryResetOptions = .none) {
        let factory = thunk()
        factory.reset(options)
        dependency = factory.resolve()
    }
}

extension Injected: @unchecked Sendable where T: Sendable {}

/// Convenience property wrapper takes a factory and resolves an instance of the desired type the first time the wrapped value is requested.
///
/// Property wrappers implement an annotation pattern to resolving dependencies, similar to using
/// EnvironmentObject in SwiftUI.
/// ```swift
/// class MyViewModel {
///    @LazyInjected(\.myService) var service1
///    @LazyInjected(\MyCustomContainer.myService) var service2
/// }
/// ```
/// The provided keypath resolves to a Factory definition on the `shared` container required for each Container type.
/// The short version of the keyPath resolves to the default container, while the expanded version
/// allows you to point an instance of your own custom container type.
///
/// > Note: Lazy injection is resolved the first time the dependency is referenced by the code, and **not** on initialization.
@propertyWrapper public struct LazyInjected<T> {

    private var thunk: () -> Factory<T>
    private var dependency: T!
    private var initialize = true
    
    /// Initializes the property wrapper. The dependency isn't resolved until the wrapped value is accessed for the first time.
    /// - Parameter keyPath: KeyPath to a Factory on the default Container.
    public init(_ keyPath: KeyPath<Container, Factory<T>>) {
        self.thunk = { Container.shared[keyPath: keyPath] }
    }
    
    /// Initializes the property wrapper. The dependency isn't resolved until the wrapped value is accessed for the first time.
    /// - Parameter keyPath: KeyPath to a Factory on the specified Container.
    public init<C:SharedContainer>(_ keyPath: KeyPath<C, Factory<T>>) {
        self.thunk = { C.shared[keyPath: keyPath] }
    }
    
    /// Manages the wrapped dependency, which is resolved when this value is accessed for the first time.
    public var wrappedValue: T {
        mutating get {
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
        thunk()
    }
    
    /// Allows the user to force a Factory resolution at their discretion.
    public mutating func resolve(reset options: FactoryResetOptions = .none) {
        let factory = thunk()
        factory.reset(options)
        dependency = factory()
        initialize = false
    }

    /// Projected function returns resolved instance if it exists.
    ///
    /// This can come in handy when you need to perform some sort of cleanup, but you don't want to resolve
    /// the property wrapper instance if it hasn't already been resolved.
    /// ```swift
    /// deinit {
    ///     $myService.resolvedOrNil()?.cleanup()
    /// }
    public func resolvedOrNil() -> T? {
        dependency
    }

}

extension LazyInjected: @unchecked Sendable where T: Sendable {}

/// Convenience property wrapper takes a factory and resolves a weak instance of the desired type the first time the wrapped value is requested.
///
/// This wrapper maintains a weak reference to the object in question, so it must exist elsewhere.
/// It's useful for delegate patterns and parent/child relationships.
///
/// Property wrappers implement an annotation pattern to resolving dependencies, similar to using
/// EnvironmentObject in SwiftUI.
///
/// ```swift
/// class MyViewModel {
///    @LazyInjected(\.myService) var service1
///    @LazyInjected(\MyCustomContainer.myService) var service2
/// }
/// ```
/// The provided keypath resolves to a Factory definition on the `shared` container required for each Container type.
/// The short version of the keyPath resolves to the default container, while the expanded version
/// allows you to point an instance of your own custom container type.
///
/// > Note: Lazy injection is resolved the first time the dependency is referenced by the code, **not** on initialization.
@propertyWrapper public struct WeakLazyInjected<T> {

    private var thunk: () -> Factory<T>
    private weak var dependency: AnyObject?
    private var initialize = true
    
    /// Initializes the property wrapper. The dependency isn't resolved until the wrapped value is accessed for the first time.
    /// - Parameter keyPath: KeyPath to a Factory on the default Container.
    public init(_ keyPath: KeyPath<Container, Factory<T>>) {
        self.thunk = { Container.shared[keyPath: keyPath] }
    }
    
    /// Initializes the property wrapper. The dependency isn't resolved until the wrapped value is accessed for the first time.
    /// - Parameter keyPath: KeyPath to a Factory on the specified Container.
    public init<C:SharedContainer>(_ keyPath: KeyPath<C, Factory<T>>) {
        self.thunk = { C.shared[keyPath: keyPath] }
    }
    
    /// Manages the wrapped dependency, which is resolved when this value is accessed for the first time.
    public var wrappedValue: T? {
        mutating get {
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
        thunk()
    }
    
    /// Allows the user to force a Factory resolution at their discretion.
    public mutating func resolve(reset options: FactoryResetOptions = .none) {
        let factory = thunk()
        factory.reset(options)
        dependency = factory() as AnyObject
        initialize = false
    }

    /// Projected function returns resolved instance if it exists.
    ///
    /// This can come in handy when you need to perform some sort of cleanup, but you don't want to resolve
    /// the property wrapper instance if it hasn't already been resolved.
    /// ```swift
    /// deinit {
    ///     $myService.resolvedOrNil()?.cleanup()
    /// }
    public func resolvedOrNil() -> T? {
        dependency as? T
    }

}

extension WeakLazyInjected: @unchecked Sendable where T: Sendable {}

/// Convenience property wrapper takes a factory and resolves an instance of the desired type.
///
/// Property wrappers implement an annotation pattern to resolving dependencies, similar to using
/// EnvironmentObject in SwiftUI.
/// ```swift
/// class MyViewModel {
///    @DynamicInjected(\.myService) var service1
///    @DynamicInjected(\MyCustomContainer.myService) var service2
/// }
/// ```
/// The provided keypath resolves to a Factory definition on the `shared` container required for each Container type.
/// The short version of the keyPath resolves to the default container, while the expanded version
/// allows you to point an instance of your own custom container type.
///
/// - Important: The @DynamicInjected property wrapper's Factory will be resolved on each and every **access**.
///
/// In the above example the referenced dependencies will be resolved and acquired each and every time one of the
/// properties are accessed.
///
/// If the dependency is stateless this shouldn't be an issue. If the dependency needs to maintain state, however,
/// then it probably needs to be cached using one of Factory's caching mechanisms.
///
/// ```swift
/// extension Container {
///     var myService: Factory<MyServiceType> {
///         self { MyService() }.cached
///     }
/// }
/// ```
@propertyWrapper public struct DynamicInjected<T> {

    private let thunk: () -> Factory<T>

    /// Initializes the property wrapper. The dependency is resolved on access.
    /// - Parameter keyPath: KeyPath to a Factory on the default Container.
    public init(_ keyPath: KeyPath<Container, Factory<T>>) {
        self.thunk = { Container.shared[keyPath: keyPath] }
    }

    /// Initializes the property wrapper. The dependency is resolved on access.
    /// - Parameter keyPath: KeyPath to a Factory on the specified Container.
    public init<C: SharedContainer>(_ keyPath: KeyPath<C, Factory<T>>) {
        self.thunk = { C.shared[keyPath: keyPath] }
    }

    /// Manages the wrapped dependency.
    public var wrappedValue: T {
        get { return thunk().resolve() }
    }

    /// Unwraps the property wrapper granting access to the resolve/reset function.
    public var projectedValue: Factory<T> {
        get { return thunk() }
    }
}

extension DynamicInjected: @unchecked Sendable where T: Sendable {}

/// Basic property wrapper for optional injected types
@propertyWrapper public struct InjectedType<T> {
    private var dependency: T?
    /// Initializes the property wrapper from the default Container. The dependency is resolved on initialization.
    public init() {
        self.dependency = (Container.shared as? Resolving)?.resolve()
    }
    /// Initializes the property wrapper from the default Container. The dependency is resolved on initialization.
    public init(_ container: ManagedContainer) {
        self.dependency = (container as? Resolving)?.resolve()
    }
    /// Manages the wrapped dependency.
    public var wrappedValue: T? {
        get { return dependency }
        mutating set { dependency = newValue }
    }
}

extension InjectedType: @unchecked Sendable where T: Sendable {}

#if canImport(SwiftUI)
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
@MainActor @frozen @propertyWrapper public struct InjectedObject<T>: DynamicProperty where T: Combine.ObservableObject {
    @StateObject fileprivate var dependency: T
    /// Initializes the property wrapper. The dependency is resolved on initialization.
    /// - Parameter keyPath: KeyPath to a Factory on the default Container.
    public init(_ keyPath: KeyPath<Container, Factory<T>>) {
        self._dependency = StateObject<T>(wrappedValue: Container.shared[keyPath: keyPath]())
    }
    /// Initializes the property wrapper. The dependency is resolved on initialization.
    /// - Parameter keyPath: KeyPath to a Factory on the specified Container.
    public init<C:SharedContainer>(_ keyPath: KeyPath<C, Factory<T>>) {
        self._dependency = StateObject<T>(wrappedValue: C.shared[keyPath: keyPath]())
    }
    /// Manages the wrapped dependency.
    public var wrappedValue: T {
        get { dependency }
    }
    /// Manages the wrapped dependency.
    public var projectedValue: ObservedObject<T>.Wrapper {
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
        self._dependency = StateObject<T>(wrappedValue: wrappedValue)
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension InjectedObject: @unchecked Sendable where T: Sendable {}

/// A property wrapper that injects an Observable dependency into a SwiftUI view.
///
/// `InjectedObservable` is designed to automatically resolve and inject Observable dependencies
/// from a shared container, allowing for easy management of Observable objects within
/// SwiftUI views. This property wrapper ensures that the dependency is resolved at
/// initialization and provides both direct access and binding capabilities.
///
/// And unlike using State, the injected dependency is only resolved once, on first use.
///
/// - Note: This property wrapper is available on iOS 17.0, macOS 14.0, tvOS 17.0, and watchOS 10.0.
/// - Requires: The wrapped type `T` must conform to the `Observable` protocol.
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@MainActor @propertyWrapper public struct InjectedObservable<T>: DynamicProperty where T: Observation.Observable {
    /// The observable dependency managed by this property wrapper.
    @State fileprivate var dependency: ThunkedValue<T>
     /// Initializes the `InjectedObservable` property wrapper, resolving the dependency from the default container.
     ///
     /// - Parameter keyPath: A key path to a `Factory` on the default `Container` that resolves the dependency.
     ///
     /// **Example Usage:**
     /// ```swift
     /// @InjectedObservable(\.contentViewModel) var viewModel: ContentViewModel
     /// ```
    public init(_ keyPath: KeyPath<Container, Factory<T>>) {
        self._dependency = .init(wrappedValue: ThunkedValue(thunkedValue: { Container.shared[keyPath: keyPath]() }))
    }
    /// Initializes the property wrapper. The dependency is resolved on initialization.
    /// - Parameter keyPath: KeyPath to a Factory on the specified Container.
    public init<C: SharedContainer>(_ keyPath: KeyPath<C, Factory<T>>) {
        self._dependency = .init(wrappedValue: ThunkedValue(thunkedValue: { C.shared[keyPath: keyPath]() }))
    }
    /// Provides direct access to the wrapped observable dependency.
    public var wrappedValue: T {
        get { dependency.thunkedValue }
    }
    /// Provides a binding to the wrapped observable dependency, allowing for dynamic updates.
    public var projectedValue: Binding<T> {
        Binding(get: { dependency.thunkedValue }, set: { _ in })
    }
}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension InjectedObservable {
    /// Simple initializer with passed parameter bypassing injection.
    ///
    /// Still has issue with attempting to pass dependency into existing view when existing InjectedObject has keyPath.
    /// https://forums.swift.org/t/allow-property-wrappers-with-multiple-arguments-to-defer-initialization-when-wrappedvalue-is-not-specified
    public init(_ wrappedValue: @autoclosure @escaping () -> T) {
        self._dependency = .init(wrappedValue: ThunkedValue(thunkedValue: wrappedValue))
    }
}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension InjectedObservable: @unchecked Sendable where T: Sendable {}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
private final class ThunkedValue<T: Observation.Observable> {

    private var object: T!
    private var thunk: (() -> T)?

    init(thunkedValue thunk: @escaping () -> T) {
        self.thunk = thunk
    }

    var thunkedValue: T {
        if let thunk {
            object = thunk()
            self.thunk = nil
        }
        return object
    }

}
#endif
