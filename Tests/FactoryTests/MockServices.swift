//
//  MockService.swift
//  
//
//  Created by Michael Long on 5/1/22.
//

import Foundation
import Testing
@testable import Factory

// Swift 6
extension Container: AutoRegistering {
    public func autoRegister() {
        // print("Container.autoRegister")
    }
}

protocol IDProviding {
    var id: UUID { get }
}

protocol ValueProviding: IDProviding {
    var value: Int { get }
}

protocol MyServiceType {
    var id: UUID { get }
    var value: Int { get }
    func text() -> String
}

class MyService: MyServiceType {
    let id = UUID()
    let value: Int = 0
    func text() -> String {
        "MyService"
    }
}

extension MyService: ValueProviding {}

class MockService: MyServiceType {
    let id = UUID()
    let value: Int = 0
    func text() -> String {
        "MockService"
    }
}

class MockServiceN: MyServiceType {
    let id = UUID()
    let n: Int
    var value: Int { n }
    init(_ n: Int) {
        self.n = n
    }
    func text() -> String {
        "MockService\(n)"
    }
}

struct ValueService: MyServiceType {
    let id = UUID()
    let value: Int = -1
    func text() -> String {
        "ValueService"
    }
}

// classes for recursive resolution test
class RecursiveA {
    @Injected(\.recursiveB) var b: RecursiveB?
    init() {}
}

class RecursiveB {
    @Injected(\.recursiveC) var c: RecursiveC?
    init() {}
}

class RecursiveC {
    @Injected(\.recursiveA) var a: RecursiveA?
    init() {}
}

class ParameterService: MyServiceType {
    let id = UUID()
    let value: Int
    init(value: Int) {
        self.value = value
    }
    func text() -> String {
        "ParameterService\(value)"
    }
}

extension Container {
    var myServiceType: Factory<MyServiceType> { self { MyService() } }
    var myServiceType2: Factory<MyServiceType> { self { MyService() } }

    var mockService: Factory<MockService> { self { MockService() } }

    var cachedService: Factory<MyService> { self { MyService() }.cached }
    var cachedOptionalService: Factory<MyServiceType?> { self { MyService() }.cached }
    var cachedEmptyOptionalService: Factory<MyServiceType?> { self { nil }.cached }

    var sharedService: Factory<MyServiceType> { self { MyService() }.shared }
    var sharedExplicitProtocol: Factory<MyServiceType> { self { MyService() }.shared }
    var sharedInferredProtocol: Factory<MyServiceType> { self { MyService() }.shared }
    var sharedOptionalProtocol: Factory<MyServiceType?> { self { MyService() }.shared }

    var optionalService: Factory<MyServiceType?> { self { MyService() } }
    var optionalValueService: Factory<MyServiceType?> { self { ValueService() } }

    var singletonService: Factory<MyServiceType> { self { MyService() }.singleton }

    var nilSService: Factory<MyServiceType?> { self { nil } }
    var nilCachedService: Factory<MyServiceType?> { self { nil }.cached }
    var nilSharedService: Factory<MyServiceType?> { self { nil }.shared }

    var sessionService: Factory<MyService> { self { MyService() }.scope(.session) }

    var valueService: Factory<ValueService> { self { ValueService() }.cached }
    var sharedValueService: Factory<ValueService> { self { ValueService() }.shared }
    var sharedValueProtocol: Factory<ValueService> { self { ValueService() }.shared }

    var uniqueServiceType: Factory<MyServiceType> { self { MyService() } }

    var promisedService: Factory<MyServiceType?> { self { nil } }
    var strictPromisedService: Factory<MyServiceType?> { promised() }

    var promisedParameterService: ParameterFactory<Int, ParameterService?> { self { _ in nil } }
    var strictPromisedParameterService: ParameterFactory<Int, ParameterService?> { promised() }

}

// For parameter tests
extension Container {
    var parameterService: ParameterFactory<Int, ParameterService> {
        self { ParameterService(value: $0) }
    }
    var scopedParameterService: ParameterFactory<Int, ParameterService> {
        self { ParameterService(value: $0) }.cached
    }
}

// Custom scope

extension Scope {
    static let session = Cached()
}

// Class for recursive scope test

extension Container {
    var recursiveA: Factory<RecursiveA?> { self { RecursiveA() } }
    var recursiveB: Factory<RecursiveB?> { self { RecursiveB() } }
    var recursiveC: Factory<RecursiveC?> { self { RecursiveC() } }
}

// Classes for graph scope tests

class GraphWrapper {
    @Injected(\.graphService) var service1
    @Injected(\.graphService) var service2
    init() {}
}

extension Container {
    var graphWrapper: Factory<GraphWrapper> { self { GraphWrapper() } }
    var graphService: Factory<MyService> { self { MyService() }.graph }
}

// Classes for implements scope tests

class ProtocolConsumer {
    @Injected(\.idProvider) var ids
    @Injected(\.valueProvider) var values
    init() {}
}

extension Container {
    var consumer: Factory<ProtocolConsumer> { self { ProtocolConsumer() } }
    var idProvider: Factory<IDProviding> { self { self.commonProvider() } }
    var valueProvider: Factory<ValueProviding> { self { self.commonProvider() } }
    private var commonProvider: Factory<MyService> { self { MyService() }.graph }
}

// Custom Container

final class CustomContainer: SharedContainer, AutoRegistering {
    @TaskLocal static var shared = CustomContainer()
    nonisolated(unsafe) static var count = 0
    nonisolated(unsafe) var count = 0
    var test: Factory<MyServiceType> {
        self {
            MockServiceN(32)
        }
        .shared
    }
    var decorated: Factory<MyService> {
        self {
            MyService()
        }
        .decorator { _ in
            self.count += 1
        }
    }
    var once: Factory<MyServiceType> {
        self {
            MyService()
        }
        .scope(.singleton)
        .decorator { _ in
            self.count += 1
        }
        .once()
    }
    var onceOnTest: Factory<MyServiceType> {
        self {
            MyService()
        }
        .onTest {
            MockServiceN(1)
        }
        .once()
    }
    func autoRegister() {
        print("CustomContainer AUTOREGISTERING")
        Self.count = 1
        self.count = 1
        self.decorator { _ in
            Self.count += 1
        }
        #if DEBUG
        decorator {
            print("FACTORY: \(type(of: $0)) (\(Int(bitPattern: ObjectIdentifier($0 as AnyObject))))")
        }
        #endif
    }
    let manager = ContainerManager()
}

#if swift(>=6.1)
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
    @MainActor
    var isolatedToMainActor: Factory<ObservableFooBarBaz> {
        self { ObservableFooBarBaz() }
    }
    @MainActor
    var isolatedToMainActorCached: Factory<ObservableFooBarBaz> {
        self { ObservableFooBarBaz() }.cached
    }
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

@MainActor
final class IsolatedTaskLocalUseCase {
    @Injected(\.fooBarBaz) var fooBarBaz: FooBarBazProtocol
    @Injected(\.fooBarBazCached) var fooBarBazCached: FooBarBazProtocol
    @Injected(\.fooBarBazSingleton) var fooBarBazSingleton: FooBarBazProtocol

    @InjectedObservable(\.isolatedToMainActor) var isolatedToMainActor: ObservableFooBarBaz
    @InjectedObservable(\.isolatedToMainActorCached) var isolatedToMainActorCached: ObservableFooBarBaz
    @InjectedObservable(\.isolatedToMainActorSingleton) var isolatedToMainActorSingleton: ObservableFooBarBaz

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
