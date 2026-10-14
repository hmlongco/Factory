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

    private final class Storage: @unchecked Sendable {
        let lock = CrossPlatformLock()
        var dependency: T?
        var initialized = false
    }

    private var thunk: () -> Factory<T>
    private let storage: Storage

    /// Initializes the property wrapper. The dependency isn't resolved until the wrapped value is accessed for the first time.
    /// - Parameter keyPath: KeyPath to a Factory on the default Container.
    public init(_ keyPath: KeyPath<Container, Factory<T>>) {
        self.thunk = { Container.shared[keyPath: keyPath] }
        self.storage = Storage()
    }

    /// Initializes the property wrapper. The dependency isn't resolved until the wrapped value is accessed for the first time.
    /// - Parameter keyPath: KeyPath to a Factory on the specified Container.
    public init<C:SharedContainer>(_ keyPath: KeyPath<C, Factory<T>>) {
        self.thunk = { C.shared[keyPath: keyPath] }
        self.storage = Storage()
    }

    /// Manages the wrapped dependency, which is resolved when this value is accessed for the first time.
    public var wrappedValue: T {
        get {
            storage.lock.withLock {
                if !storage.initialized {
                    storage.dependency = thunk().resolve()
                    storage.initialized = true
                }
                return storage.dependency!
            }
        }
        set {
            storage.lock.withLock {
                storage.dependency = newValue
                storage.initialized = true
            }
        }
    }

    /// Unwraps the property wrapper granting access to the resolve/reset function.
    public var projectedValue: LazyInjected<T> {
        get { return self }
        set { self = newValue }
    }

    /// Grants access to the internal Factory.
    public var factory: Factory<T> {
        thunk()
    }

    /// Allows the user to force a Factory resolution at their discretion.
    public func resolve(reset options: FactoryResetOptions = .none) {
        storage.lock.withLock {
            let factory = thunk()
            factory.reset(options)
            storage.dependency = factory()
            storage.initialized = true
        }
    }

    /// Projected function returns resolved instance if it exists.
    ///
    /// This can come in handy when you need to perform some sort of cleanup, but you don't want to resolve
    /// the property wrapper instance if it hasn't already been resolved.
    /// ```swift
    /// deinit {
    ///     $myService.resolvedOrNil()?.cleanup()
    /// }
    /// ```
    public func resolvedOrNil() -> T? {
        storage.lock.withLock { storage.initialized ? storage.dependency : nil }
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
///    @WeakLazyInjected(\.myService) var service1
///    @WeakLazyInjected(\MyCustomContainer.myService) var service2
/// }
/// ```
/// The provided keypath resolves to a Factory definition on the `shared` container required for each Container type.
/// The short version of the keyPath resolves to the default container, while the expanded version
/// allows you to point an instance of your own custom container type.
///
/// > Note: Lazy injection is resolved the first time the dependency is referenced by the code, **not** on initialization.
@propertyWrapper public struct WeakLazyInjected<T> {

    private final class Storage: @unchecked Sendable {
        let lock = CrossPlatformLock()
        weak var dependency: AnyObject?
        var initialized = false
    }

    private var thunk: () -> Factory<T>
    private let storage: Storage

    /// Initializes the property wrapper. The dependency isn't resolved until the wrapped value is accessed for the first time.
    /// - Parameter keyPath: KeyPath to a Factory on the default Container.
    public init(_ keyPath: KeyPath<Container, Factory<T>>) {
        self.thunk = { Container.shared[keyPath: keyPath] }
        self.storage = Storage()
    }

    /// Initializes the property wrapper. The dependency isn't resolved until the wrapped value is accessed for the first time.
    /// - Parameter keyPath: KeyPath to a Factory on the specified Container.
    public init<C:SharedContainer>(_ keyPath: KeyPath<C, Factory<T>>) {
        self.thunk = { C.shared[keyPath: keyPath] }
        self.storage = Storage()
    }

    /// Manages the wrapped dependency, which is resolved when this value is accessed for the first time.
    public var wrappedValue: T? {
        get {
            storage.lock.withLock {
                if !storage.initialized {
                    storage.dependency = thunk().resolve() as AnyObject
                    storage.initialized = true
                }
                return storage.dependency as? T
            }
        }
        set {
            storage.lock.withLock {
                storage.dependency = newValue as AnyObject
                storage.initialized = true
            }
        }
    }

    /// Unwraps the property wrapper granting access to the resolve/reset function.
    public var projectedValue: WeakLazyInjected<T> {
        get { return self }
        set { self = newValue }
    }

    /// Grants access to the internal Factory.
    public var factory: Factory<T> {
        thunk()
    }

    /// Allows the user to force a Factory resolution at their discretion.
    public func resolve(reset options: FactoryResetOptions = .none) {
        storage.lock.withLock {
            let factory = thunk()
            factory.reset(options)
            storage.dependency = factory() as AnyObject
            storage.initialized = true
        }
    }

    /// Projected function returns resolved instance if it exists.
    ///
    /// This can come in handy when you need to perform some sort of cleanup, but you don't want to resolve
    /// the property wrapper instance if it hasn't already been resolved.
    /// ```swift
    /// deinit {
    ///     $myService.resolvedOrNil()?.cleanup()
    /// }
    /// ```
    public func resolvedOrNil() -> T? {
        storage.lock.withLock { storage.dependency as? T }
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
    /// Initializes the property wrapper from the specified container. The dependency is resolved on initialization.
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

/// Convenience property wrapper injects the specified Container. similar to using Environment or
/// EnvironmentObject in SwiftUI.
/// ```swift
/// class MyViewModel {
///    @InjectedContainer var container
///    @InjectedContainer(\MyCustomContainer) var container2
/// }
/// ```
/// > Note: The @InjectedContainer property wrapper will be resolved on **initialization**. In the above example
/// the referenced containers will be acquired when the parent class is created.
@propertyWrapper public struct InjectedContainer<C: SharedContainer> {

    private var container: C

    /// Initializes the property wrapper. The dependency is resolved on initialization.
    public init() where C == Container {
        self.container = Container.shared
    }

    /// Initializes the property wrapper. The dependency is resolved on initialization.
    public init(_ type: C.Type) {
        self.container = C.shared
    }

    /// Manages the wrapped dependency.
    public var wrappedValue: C {
        get { return container }
        mutating set { container = newValue }
    }

    /// Allows the user to force a Factory resolution at their discretion.
    public mutating func reset(options: FactoryResetOptions = .none) {
        container.reset(options: options)
    }
}

#if canImport(SwiftUI)
/// Injection property wrapper for SwiftUI ObservableObjects.
///
/// This wrapper is meant for use in SwiftUI Views and exposes bindable objects similar to that of SwiftUI @StateObject
/// and @EnvironmentObject.
///
/// Like the other Injected property wrappers, InjectedObject obtains the dependency from the Factory keypath
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
/// `InjectedObject` can also look for a registered scene container and use that container instead of Container.shared. This can be
/// beneficial in multitasking environments like SplitView.
///
/// To do so, register and store the container at the scene root, NOT the app root.
/// ```swift
/// @main
/// struct DemoApp: App {
///     var body: some Scene {
///         WindowGroup {
///             PerSceneContentView()
///         }
///     }
/// }
/// // Create a new container for each scene.
/// struct PerSceneContentView: View {
///     @State var sceneContainer = Container()
///     var body: some View {
///         ContentView()
///             .environment(\.container, sceneContainer)
///     }
/// }
/// ```
/// You'll probably also want to pass the container into the view model on initialization so it's accessing the proper dependencies. Using
/// `@Injected` or other Factory property wrappers will revert to accessing `Container.shared`, which is not what we want.
/// ```swift
/// extension Container {
///     @MainActor var contentViewModel: Factory<ContentViewModel> {
///         self { ContentViewModel(container: self) }
///     }
/// }
///
/// @MainActor
/// final class ContentViewModel: ObservableObject {
///     private let service: MyServiceType
///     init(container: Container) {
///         // If you want the service resolved from the "per scene" container do this!
///         self.service = container.myServiceType()
///     }
///     // Not this!
///     @Injected(\.myServiceType) private var badDependency
/// }
/// ```
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
@MainActor @propertyWrapper public struct InjectedObject<T>: DynamicProperty where T: Combine.ObservableObject {
    /// The container registered for this scene, otherwise the global shared container.
    @Environment(\.container) fileprivate var container: Container
    /// The observable dependency managed by this property wrapper. Held in a StateObject so SwiftUI observes its changes.
    @StateObject fileprivate var dependency: ThunkedObject<T>
    /// Initializes the property wrapper. The dependency is resolved on first use.
    /// - Parameter keyPath: KeyPath to a Factory on the default Container.
    public init(_ keyPath: KeyPath<Container, Factory<T>>) {
        self._dependency = StateObject(wrappedValue: ThunkedObject(thunkedValue: { c in c[keyPath: keyPath]() }))
    }
    /// Initializes the property wrapper. The dependency is resolved on first use.
    /// - Parameter keyPath: KeyPath to a Factory on the specified Container. Resolves from `C.shared`, not the scene container.
    public init<C: SharedContainer>(_ keyPath: KeyPath<C, Factory<T>>) {
        self._dependency = StateObject(wrappedValue: ThunkedObject(thunkedValue: { _ in C.shared[keyPath: keyPath]() }))
    }
    /// Provides direct access to the wrapped observable dependency.
    public var wrappedValue: T {
        get { dependency.thunkedValue(container) }
    }
    /// Provides bindings to the properties of the wrapped observable dependency.
    public var projectedValue: ObservedObject<T>.Wrapper {
        ObservedObject(wrappedValue: dependency.thunkedValue(container)).projectedValue
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension InjectedObject {
    /// Simple initializer with passed parameter bypassing injection.
    ///
    /// Still has issue with attempting to pass dependency into existing view when existing InjectedObject has keyPath.
    /// https://forums.swift.org/t/allow-property-wrappers-with-multiple-arguments-to-defer-initialization-when-wrappedvalue-is-not-specified
    public init(_ wrappedValue: T) {
        self._dependency = StateObject(wrappedValue: ThunkedObject(thunkedValue: { _ in wrappedValue }))
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension InjectedObject: @unchecked Sendable where T: Sendable {}

/// A property wrapper that injects an Observable dependency into a SwiftUI view.
///
/// `InjectedObservable` is designed to automatically resolve and inject Observable dependencies
/// from a shared container, allowing for easy management of Observable objects within
/// SwiftUI views. This property wrapper ensures that the dependency is resolved on
/// first use and provides state storage, direct access, and binding capabilities.
///
/// And unlike using State (prior to iOS 27), the injected dependency is only resolved once, on first use.
///
/// To use `InjectedObservable` just add the view model dependency to a Factory container.
/// ```swift
/// // Define the dependency
/// extension Container {
///     @MainActor var sceneDemoViewModel: Factory<SceneDemoViewModel> {
///         self { SceneDemoViewModel() }
///     }
/// }
/// // And use the property wrapper in the View to obtain the view model.
/// struct SceneDemoView: View {
///     @InjectedObservable(\.sceneDemoViewModel) var model
///     var body: some View {
///         Text(model.text)
///     }
/// }
/// ```
///
/// `InjectedObservable` can also look for a registered scene container and use that container instead of Container.shared. This can be
/// beneficial in multitasking environments like SplitView.
///
/// To do so, register and store the container at the scene root, NOT the app root.
/// ```swift
/// @main
/// struct DemoApp: App {
///     var body: some Scene {
///         WindowGroup {
///             PerSceneContentView()
///         }
///     }
/// }
/// // Create a new container for each scene.
/// struct PerSceneContentView: View {
///     @State var sceneContainer = Container()
///     var body: some View {
///         ContentView()
///             .environment(\.container, sceneContainer)
///     }
/// }
/// ```
/// You'll probably also want to pass the container into the view model on initialization so it's accessing the proper dependencies. Using
/// `@Injected` or other Factory property wrappers will revert to accessing `Container.shared`, which is not what we want.
/// ```swift
/// extension Container {
///     @MainActor var sceneDemoViewModel: Factory<SceneDemoViewModel> {
///         self { SceneDemoViewModel(container: self) }
///     }
/// }
///
/// @MainActor
/// @Observable
/// final class SceneDemoViewModel {
///     private let service: MyServiceType
///     init(container: Container) {
///         // If you want the service resolved from the "per scene" container do this!
///         self.service = container.myServiceType()
///     }
///     // Not this!
///     @Injected(\.myServiceType) private var badDependency
/// }
/// ```
/// - Note: This property wrapper is available on iOS 17.0, macOS 14.0, tvOS 17.0, and watchOS 10.0.
/// - Requires: The wrapped type `T` must conform to the `Observable` protocol.
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@MainActor @propertyWrapper public struct InjectedObservable<T>: DynamicProperty where T: Observation.Observable {
    /// The container registered for this scene, otherwise the global shared container.
    @Environment(\.container) fileprivate var container: Container
    /// The observable dependency managed by this property wrapper.
    @State fileprivate var dependency: ThunkedValue<T>
    /// Initializes the `InjectedObservable` property wrapper, resolving the dependency from the default shared container.
    ///
    /// `InjectedObservable` can also look for a registered scene container and use that container instead of Container.shared. This can be
    /// beneficial in multitasking environments like SplitView.
    ///
    /// - Parameter keyPath: A key path to a `Factory` on the default `Container` that resolves the dependency.
    ///
    /// **Example Usage:**
    /// ```swift
    /// @InjectedObservable(\.contentViewModel) var viewModel: ContentViewModel
    /// ```
    public init(_ keyPath: KeyPath<Container, Factory<T>>) {
        self._dependency = .init(wrappedValue: ThunkedValue(thunkedValue: { c in c[keyPath: keyPath]() }))
    }
    /// Initializes the property wrapper. The dependency is resolved on first use.
    /// - Parameter keyPath: KeyPath to a Factory on the specified Container. Resolves from `C.shared`, not the scene container.
    public init<C: SharedContainer>(_ keyPath: KeyPath<C, Factory<T>>) {
        self._dependency = .init(wrappedValue: ThunkedValue(thunkedValue: { _ in C.shared[keyPath: keyPath]() }))
    }
    /// Provides direct access to the wrapped observable dependency.
    public var wrappedValue: T {
        get { dependency.thunkedValue(container) }
    }
    /// Provides a binding to the wrapped observable dependency. Setting the binding's value has no effect.
    public var projectedValue: Binding<T> {
        Binding(get: { dependency.thunkedValue(container) }, set: { _ in })
    }
}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension InjectedObservable {
    /// Simple initializer with passed parameter bypassing injection.
    ///
    /// Still has issue with attempting to pass dependency into existing view when existing InjectedObservable has keyPath.
    /// https://forums.swift.org/t/allow-property-wrappers-with-multiple-arguments-to-defer-initialization-when-wrappedvalue-is-not-specified
    public init(_ wrappedValue: @autoclosure @escaping () -> T) {
        self._dependency = .init(wrappedValue: ThunkedValue(thunkedValue: { _ in wrappedValue() }))
    }
}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension InjectedObservable: @unchecked Sendable where T: Sendable {}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
private final class ThunkedValue<T> {

    private var object: T!
    private var thunk: ((_ c: Container) -> T)?

    init(thunkedValue thunk: @escaping (_ c: Container) -> T) {
        self.thunk = thunk
    }

    func thunkedValue(_ c: Container) -> T {
        if let thunk {
            object = thunk(c)
            self.thunk = nil
        }
        return object
    }

}

/// Like ThunkedValue, but for ObservableObjects. Resolves lazily and forwards the resolved object's `objectWillChange`
/// so that a StateObject holding this box invalidates the view when the dependency publishes changes.
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
@MainActor
private final class ThunkedObject<T: Combine.ObservableObject>: Combine.ObservableObject {

    private var object: T!
    private var thunk: ((_ c: Container) -> T)?
    private var cancellable: AnyCancellable?

    init(thunkedValue thunk: @escaping (_ c: Container) -> T) {
        self.thunk = thunk
    }

    func thunkedValue(_ c: Container) -> T {
        if let thunk {
            let object = thunk(c)
            self.object = object
            self.thunk = nil
            cancellable = object.objectWillChange.sink { [weak self] _ in
                self?.objectWillChange.send()
            }
        }
        return object
    }

}


#endif

