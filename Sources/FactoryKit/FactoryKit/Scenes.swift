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

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension EnvironmentValues {
    /// Entry for per scene containers, used by `@InjectedObservable`.
    @Entry public var container: Container = Container.shared
}

extension View {
    /// Configures the ambient scene container if one is already set (e.g. by a parent view), otherwise we default to the
    /// global shared container.
    ///
    /// Publishes the result via `\.container` so `@InjectedObservable` resolve against it instead of `Container.shared`.
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public func withContainer(_ modify: @escaping (Container) -> Void) -> some View {
        modifier(SceneContainerModifier(modify: modify))
    }

    /// Registers the factory on the ambient scene container if one is already set (e.g. by a parent view), otherwise we default to the
    /// global shared container.
    ///
    /// Publishes the result via `\.container` so `@InjectedObservable` resolve against it instead of `Container.shared`.
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public func withContainer<T>(_ keyPath: KeyPath<Container, Factory<T>>, _ registration: @escaping () -> T) -> some View {
        modifier(SceneContainerModifier(modify: { $0[keyPath: keyPath].register(factory: registration) }))
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
private struct SceneContainerModifier: ViewModifier {

    @Environment(\.container) private var environmentContainer: Container

    let modify: (Container) -> Void

    func body(content: Content) -> some View {
        content.environment(\.container, modifiedContainer())
    }

    func modifiedContainer() -> Container {
        modify(environmentContainer)
        return environmentContainer
    }
}

#endif
