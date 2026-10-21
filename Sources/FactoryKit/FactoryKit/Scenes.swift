//
// Scenes.swift
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

/// Holds the per-scene containers published in the environment, keyed by container type.
///
/// Reading a container type that hasn't been installed returns that type's `shared` container.
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
struct SceneContainers: Equatable, Sendable {

    private var containers: [ObjectIdentifier: any SharedContainer] = [:]

    subscript<C: SharedContainer>(_ type: C.Type) -> C {
        get { (containers[ObjectIdentifier(type)] as? C) ?? C.shared }
        set { containers[ObjectIdentifier(type)] = newValue }
    }

    static func == (lhs: SceneContainers, rhs: SceneContainers) -> Bool {
        lhs.containers.count == rhs.containers.count
            && lhs.containers.allSatisfy { rhs.containers[$0.key] === $0.value }
    }

}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension EnvironmentValues {
    /// Per scene containers, by container type. Used by `@InjectedObject` and `@InjectedObservable`.
    @Entry var sceneContainers: SceneContainers = SceneContainers()

    /// Entry for per scene containers, used by `@InjectedObject` and `@InjectedObservable`.
    ///
    /// Defaults to `Container.shared`. Custom container types are installed with `withContainer(_:)`.
    public var container: Container {
        get { sceneContainers[Container.self] }
        set { sceneContainers[Container.self] = newValue }
    }
}

extension View {
    /// Configures the ambient scene container if one is already set (e.g. by a parent view), otherwise we default to the
    /// global shared container.
    ///
    /// Publishes the result via `\.container` so `@InjectedObject` and `@InjectedObservable` resolve against it instead of `Container.shared`.
    ///
    /// Use it to apply any number of registrations to the container, for example in a preview or at the root of a scene.
    /// ```swift
    /// #Preview {
    ///     ContentView()
    ///         .withContainer {
    ///             $0.myServiceType.register { MockService() }
    ///             $0.analytics.register { MockAnalytics() }
    ///         }
    /// }
    /// ```
    /// > Important: The modifier changes the container it finds in the environment, so it must be applied *inside* the view that
    /// sets `\.container`. Applied outside, it finds and changes `Container.shared` instead.
    /// ```swift
    /// ContentView()
    ///     .withContainer { $0.myServiceType.register { MockService() } }
    ///     // Registers on sceneContainer.
    ///     .environment(\.container, sceneContainer)
    /// ```
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public func withContainer(_ modify: @escaping (Container) -> Void) -> some View {
        modifier(SceneContainerModifier<Container>(modify: modify))
    }

    /// Registers the factory on the ambient scene container if one is already set (e.g. by a parent view), otherwise we default to the
    /// global shared container.
    ///
    /// Publishes the result via `\.container` so `@InjectedObject` and `@InjectedObservable` resolve against it instead of `Container.shared`.
    ///
    /// Shorthand for registering a single factory.
    /// ```swift
    /// #Preview {
    ///     ContentView()
    ///         .withContainer(\.myServiceType) { MockService() }
    /// }
    /// ```
    /// The same placement rule applies. Apply it inside the view that sets `\.container`, or it registers on `Container.shared`.
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public func withContainer<T>(_ keyPath: KeyPath<Container, Factory<T>>, _ registration: @escaping () -> T) -> some View {
        modifier(SceneContainerModifier<Container>(modify: { $0[keyPath: keyPath].register(factory: registration) }))
    }

    /// Configures the ambient scene container of the given custom container type if one is already set (e.g. by a parent view),
    /// otherwise we default to that type's `shared` container.
    ///
    /// Publishes the result so `@InjectedObject` and `@InjectedObservable` resolve `\MyContainer` key paths against it instead of `MyContainer.shared`.
    /// ```swift
    /// #Preview {
    ///     ContentView()
    ///         .withContainer(MyContainer.self) {
    ///             $0.myServiceType.register { MockService() }
    ///         }
    /// }
    /// ```
    /// The same placement rule applies. Apply it inside the view that installs the container, or it registers on `MyContainer.shared`.
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public func withContainer<C: SharedContainer>(_ type: C.Type, _ modify: @escaping (C) -> Void) -> some View {
        modifier(SceneContainerModifier<C>(modify: modify))
    }

    /// Registers the factory on the ambient scene container of the custom container type if one is already set (e.g. by a parent view),
    /// otherwise we default to that type's `shared` container.
    ///
    /// Shorthand for registering a single factory on a custom container.
    /// ```swift
    /// #Preview {
    ///     ContentView()
    ///         .withContainer(\MyContainer.myServiceType) { MockService() }
    /// }
    /// ```
    /// The same placement rule applies. Apply it inside the view that installs the container, or it registers on `MyContainer.shared`.
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public func withContainer<C: SharedContainer, T>(_ keyPath: KeyPath<C, Factory<T>>, _ registration: @escaping () -> T) -> some View {
        modifier(SceneContainerModifier<C>(modify: { $0[keyPath: keyPath].register(factory: registration) }))
    }

    /// Installs a container for this scene, for any container type, so `@InjectedObject` and `@InjectedObservable` resolve against it
    /// instead of that type's `shared` container.
    ///
    /// This is the custom container counterpart of `.environment(\.container, sceneContainer)`.
    /// ```swift
    /// struct SceneRoot: View {
    ///     @State private var sceneContainer = MyContainer()
    ///     var body: some View {
    ///         ContentView()
    ///             .withContainer(sceneContainer)
    ///     }
    /// }
    /// ```
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public func withContainer<C: SharedContainer>(_ container: C) -> some View {
        transformEnvironment(\.sceneContainers) { $0[C.self] = container }
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
private struct SceneContainerModifier<C: SharedContainer>: ViewModifier {

    @Environment(\.sceneContainers) private var environmentContainers: SceneContainers

    let modify: (C) -> Void

    func body(content: Content) -> some View {
        content.environment(\.sceneContainers, modifiedContainers())
    }

    func modifiedContainers() -> SceneContainers {
        var containers = environmentContainers
        let container = containers[C.self]
        modify(container)
        containers[C.self] = container
        return containers
    }
}

#endif
