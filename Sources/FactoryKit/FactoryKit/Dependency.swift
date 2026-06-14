//
// Resolutions.swift
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

/// Global function to resolve a keyPath on Container.shared into the requested type
///
/// ```swift
/// @State var model: ContentViewModel = resolve(\.contentViewModel)
/// ```
///
/// ```swift
/// nonisolated final class NetworkService {
///     let preferences: Preferences = dependency(\.preferences)
///     func load() {}
/// }
/// ```
public func dependency<T>(_ keyPath: KeyPath<Container, Factory<T>>) -> T {
    Container.shared[keyPath: keyPath]()
}

/// Global function to resolve a keyPath on the specified shared container into the requested type
///
/// ```swift
/// @State var model: ContentViewModel = dependency(\MyContainer.contentViewModel)
/// ```
public func dependency<C:SharedContainer, T>(_ keyPath: KeyPath<C, Factory<T>>) -> T {
    C.shared[keyPath: keyPath]()
}

/// Global dependency resolution function with passed parameter, operating on Container.shared.
///
/// ```swift
/// nonisolated final class NetworkService {
///     let preferences: Preferences = dependency(\.preferences, parameter: Mode.secret)
///     func load() {}
/// }
/// ```
/// Useful when you want to hide Factory and Factory Shared Containers from the rest of your code base.
public func dependency<T, P>(_ keyPath: KeyPath<Container, ParameterFactory<P, T>>, parameter: P) -> T {
    Container.shared[keyPath: keyPath](parameter)
}

/// Global dependency resolution function with passed parameter, operating on specified shared container.
///
/// ```swift
/// nonisolated final class NetworkService {
///     let preferences: Preferences = dependency(\Custom.preferences, parameter: Mode.secret)
///     func load() {}
/// }
/// ```
/// Useful when you want to hide Factory and Factory Shared Containers from the rest of your code base.
public func dependency<C: SharedContainer, P, T>(_ keyPath: KeyPath<C, ParameterFactory<P, T>>, parameter: P) -> T {
    C.shared[keyPath: keyPath](parameter)
}

#if canImport(SwiftUI)
import SwiftUI

/// Global function to register a new factory closure on a keyPath of Container.shared.
///
/// Returns an `EmptyView` so registrations can be made directly within a SwiftUI `@ViewBuilder` context such as
/// `#Preview`, where every statement must be a `View`.
///
/// ```swift
/// #Preview {
///     register(\.myService) { MockService() }
///     ContentView()
/// }
/// ```
/// Shorthand for `Container.shared.myService.register { MockService() }`.
@MainActor
@discardableResult
public func register<T>(_ keyPath: KeyPath<Container, Factory<T>>, factory: @escaping VoidFactoryType<T>) -> EmptyView {
    Container.shared[keyPath: keyPath].register(factory: factory)
    return EmptyView()
}

/// Global function to register a new factory closure on a keyPath of the specified shared container.
///
/// ```swift
/// register(\MyContainer.myService) { MockService() }
/// ```
@MainActor
@discardableResult
public func register<C: SharedContainer, T>(_ keyPath: KeyPath<C, Factory<T>>, factory: @escaping VoidFactoryType<T>) -> EmptyView {
    C.shared[keyPath: keyPath].register(factory: factory)
    return EmptyView()
}
#else

/// Global function to register a new factory closure on a keyPath of Container.shared.
///
/// ```swift
/// register(\.myService) { MockService() }
/// ```
/// Shorthand for `Container.shared.myService.register { MockService() }`.
public func register<T>(_ keyPath: KeyPath<Container, Factory<T>>, factory: @escaping VoidFactoryType<T>) {
    Container.shared[keyPath: keyPath].register(factory: factory)
}

/// Global function to register a new factory closure on a keyPath of the specified shared container.
///
/// ```swift
/// register(\MyContainer.myService) { MockService() }
/// ```
public func register<C: SharedContainer, T>(_ keyPath: KeyPath<C, Factory<T>>, factory: @escaping VoidFactoryType<T>) {
    C.shared[keyPath: keyPath].register(factory: factory)
}
#endif

// deprecations

@available(*, deprecated, renamed: "dependency", message: "Deprecated. Use `dependency` with a keypath instead.")
public func resolve<T>(_ keyPath: KeyPath<Container, Factory<T>>) -> T {
    Container.shared[keyPath: keyPath]()
}

@available(*, deprecated, renamed: "dependency", message: "Deprecated. Use `dependency` with a keypath instead.")
public func resolve<C:SharedContainer, T>(_ keyPath: KeyPath<C, Factory<T>>) -> T {
    C.shared[keyPath: keyPath]()
}
