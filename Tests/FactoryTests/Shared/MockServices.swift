//
//  MockService.swift
//  
//
//  Created by Michael Long on 5/1/22.
//

import Foundation
import Testing

@testable import FactoryKit
import FactoryTesting

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

public protocol MyServiceType {
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
    var myServiceType: Factory<MyServiceType> {
        self { MyService() }
    }
}

protocol MyServiceTypeProviding {
    // the ideal
    var myServiceType1: MyServiceType { get }
    // what's exposed
    var myServiceType2: Factory<MyServiceType> { get }
}

extension Container {
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
    var scopedOnParameterService: ParameterFactory<Int, ParameterService> {
        self { ParameterService(value: $0) }.scopeOnParameters.cached
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
    var consumer: Factory<ProtocolConsumer> { self { ProtocolConsumer() }.cached }
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
    var decoratedNew: Factory<MyService> {
        self {
            MyService()
        }
        .decorator { (_, newInstance) in
            if newInstance {
                self.count += 1
            }
        }
        .cached
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
