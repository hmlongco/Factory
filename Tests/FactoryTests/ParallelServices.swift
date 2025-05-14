//
//  FooBarBazProtocol.swift
//  Factory
//
//  Created by Michael Long on 4/30/25.
//

import Foundation
import Testing

@testable import FactoryKit
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

@MainActor
final class MainActorFooBarBaz: Sendable {
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

    @MainActor
    var isolatedToMainActor: Factory<MainActorFooBarBaz> {
        self { @MainActor in MainActorFooBarBaz() }
    }
    @MainActor
    var isolatedToMainActorCached: Factory<MainActorFooBarBaz> {
        self { @MainActor in MainActorFooBarBaz() }.cached
    }
    @MainActor
    var isolatedToMainActorSingleton: Factory<MainActorFooBarBaz> {
        self { @MainActor in MainActorFooBarBaz() }.singleton
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

extension CustomContainer {
    var myServiceType: Factory<MyServiceType> {
        self { MyService() }
    }
}

final class TaskLocalUseCase {
    @Injected(\.fooBarBaz) var fooBarBaz: FooBarBazProtocol
    @Injected(\.fooBarBazCached) var fooBarBazCached: FooBarBazProtocol
    @Injected(\.fooBarBazSingleton) var fooBarBazSingleton: FooBarBazProtocol
}

@MainActor
final class IsolatedTaskLocalUseCase {
    @Injected(\.fooBarBaz) var fooBarBaz: FooBarBazProtocol
    @Injected(\.fooBarBazCached) var fooBarBazCached: FooBarBazProtocol
    @Injected(\.fooBarBazSingleton) var fooBarBazSingleton: FooBarBazProtocol

    @Injected(\.isolatedToMainActor) var isolatedToMainActor: MainActorFooBarBaz
    @Injected(\.isolatedToMainActorCached) var isolatedToMainActorCached: MainActorFooBarBaz
    @Injected(\.isolatedToMainActorSingleton) var isolatedToMainActorSingleton: MainActorFooBarBaz

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
