//
//  FooBarBazProtocol.swift
//  Factory
//
//  Created by Michael Long on 4/30/25.
//

import Foundation
import Testing

#if canImport(SwiftUI)
import Combine
import Observation
import SwiftUI
#endif

@testable import Factory
import FactoryTesting

#if swift(>=5.5)
/// Extension provides test trait for CustomContainer
extension Trait where Self == ContainerTrait<CustomContainer> {
    static var customContainer: ContainerTrait<CustomContainer> {
        .init(shared: CustomContainer.$shared, container: .init())
    }
}
#endif

// Classes for @TaskLocal and TestTrait tests

protocol FooBarBazProtocol {
    var id: UUID { get }
    var value: String { get set }
}

final class Foo: FooBarBazProtocol {
    let id: UUID = UUID()
    var value = "foo"
}

final class Bar: FooBarBazProtocol {
    let id: UUID = UUID()
    var value = "bar"
}

final class Baz: FooBarBazProtocol {
    let id: UUID = UUID()
    var value = "baz"
}

protocol IsolatedProtocol: Sendable {
    var id: UUID { get }
    var value: String { get set }
}

struct IsolatedFoo: IsolatedProtocol {
    let id: UUID = UUID()
    var value = "foo"
}

struct IsolatedBar: IsolatedProtocol {
    let id: UUID = UUID()
    var value = "bar"
}

struct IsolatedBaz: IsolatedProtocol {
    let id: UUID = UUID()
    var value = "baz"
}

@available(iOS 17.0, *)
@Observable
final class ObservableFooBarBaz: Sendable {
    let id: UUID = UUID()
    let value: String

    init(value: String = "foo") {
        self.value = value
    }
}

@globalActor
actor MyActor {
    static let shared = MyActor()
}

extension Container {
    nonisolated var fooBarBaz: Factory<FooBarBazProtocol> {
        self { Foo() }
    }
    nonisolated var fooBarBazCached: Factory<FooBarBazProtocol> {
        self { Foo() }.cached
    }
    nonisolated var fooBarBazSingleton: Factory<FooBarBazProtocol> {
        self { Foo() }.singleton
    }

    @available(iOS 17.0, *)
    @MainActor
    var isolatedToMainActor: Factory<ObservableFooBarBaz> {
        self { ObservableFooBarBaz() }
    }

    @available(iOS 17.0, *)
    @MainActor
    var isolatedToMainActorCached: Factory<ObservableFooBarBaz> {
        self { ObservableFooBarBaz() }.cached
    }

    @available(iOS 17.0, *)
    @MainActor
    var isolatedToMainActorSingleton: Factory<ObservableFooBarBaz> {
        self { ObservableFooBarBaz() }.singleton
    }

    @MyActor
    var isolatedToCustomGlobalActor: Factory<IsolatedProtocol> {
        self { IsolatedFoo() }
    }
    @MyActor
    var isolatedToCustomGlobalActorCached: Factory<IsolatedProtocol> {
        self { IsolatedFoo() }.cached
    }
    @MyActor
    var isolatedToCustomGlobalActorSingleton: Factory<IsolatedProtocol> {
        self { IsolatedFoo() }.singleton
    }
}

final class TaskLocalUseCase {
    @Injected(\.fooBarBaz) var fooBarBaz: FooBarBazProtocol
    @Injected(\.fooBarBazCached) var fooBarBazCached: FooBarBazProtocol
    @Injected(\.fooBarBazSingleton) var fooBarBazSingleton: FooBarBazProtocol
}

@available(iOS 17.0, *)
@MainActor
final class IsolatedTaskLocalUseCase {
    @Injected(\.fooBarBaz) var fooBarBaz: FooBarBazProtocol
    @Injected(\.fooBarBazCached) var fooBarBazCached: FooBarBazProtocol
    @Injected(\.fooBarBazSingleton) var fooBarBazSingleton: FooBarBazProtocol

    @Injected(\.isolatedToMainActor) var isolatedToMainActor: ObservableFooBarBaz
    @Injected(\.isolatedToMainActorCached) var isolatedToMainActorCached: ObservableFooBarBaz
    @Injected(\.isolatedToMainActorSingleton) var isolatedToMainActorSingleton: ObservableFooBarBaz

    var isolatedToCustomGlobalActor: IsolatedProtocol
    var isolatedToCustomGlobalActorCached: IsolatedProtocol
    var isolatedToCustomGlobalActorSingleton: IsolatedProtocol

    // Swift doesn't allow default values for properties that are isolated to a different global actor than self.
    // See: https://github.com/swiftlang/swift-evolution/blob/main/proposals/0411-isolated-default-values.md
    init() async {
        self.isolatedToCustomGlobalActor = await Container.shared.isolatedToCustomGlobalActor.resolve()
        self.isolatedToCustomGlobalActorCached = await Container.shared.isolatedToCustomGlobalActorCached.resolve()
        self.isolatedToCustomGlobalActorSingleton = await Container.shared.isolatedToCustomGlobalActorSingleton.resolve()
    }
}
