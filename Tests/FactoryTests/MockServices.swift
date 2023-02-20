//
//  MockService.swift
//  
//
//  Created by Michael Long on 5/1/22.
//

import Foundation
@testable import Factory

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
    var myServiceType: Factory<MyServiceType> { unique { MyService() } }
    var myServiceType2: Factory<MyServiceType> { unique { MyService() } }

    var mockService: Factory<MockService> { unique { MockService() } }

    var cachedService: Factory<MyService> { cached { MyService() } }
    var cachedOptionalService: Factory<MyServiceType?> { cached { MyService() } }
    var cachedEmptyOptionalService: Factory<MyServiceType?> { cached { nil } }

    var sharedService: Factory<MyServiceType> { shared { MyService() } }
    var sharedExplicitProtocol: Factory<MyServiceType> { shared { MyService() } }
    var sharedInferredProtocol: Factory<MyServiceType> { shared { MyService() } }
    var sharedOptionalProtocol: Factory<MyServiceType?> { shared { MyService() } }

    var optionalService: Factory<MyServiceType?> { unique { MyService() } }
    var optionalValueService: Factory<MyServiceType?> { unique { ValueService() } }

    var singletonService: Factory<MyServiceType> { singleton { MyService() } }

    var nilSService: Factory<MyServiceType?> { unique { nil } }
    var nilCachedService: Factory<MyServiceType?> { cached { nil } }
    var nilSharedService: Factory<MyServiceType?> { shared { nil } }

    var sessionService: Factory<MyService> { scope(.session) { MyService() } }

    var valueService: Factory<ValueService> { cached { ValueService() } }
    var sharedValueService: Factory<ValueService> { shared { ValueService() } }
    var sharedValueProtocol: Factory<ValueService> { shared { ValueService() } }

    var uniqueServiceType: Factory<MyServiceType> { unique { MyService() } }

    var promisedService: Factory<MyServiceType?> { unique { nil } }

}

// For parameter tests
extension Container {
    var parameterService: ParameterFactory<Int, ParameterService> {
        unique { ParameterService(value: $0) }
    }
    var scopedParameterService: ParameterFactory<Int, ParameterService> {
        cached { ParameterService(value: $0) }
    }
}

// Custom scope

extension Scope {
    static var session = Cached()
}

// Class for recursive scope test

extension Container {
    var recursiveA: Factory<RecursiveA?> { unique { RecursiveA() } }
    var recursiveB: Factory<RecursiveB?> { unique { RecursiveB() } }
    var recursiveC: Factory<RecursiveC?> { unique { RecursiveC() } }
}

// Classes for graph scope tests

class GraphWrapper {
    @Injected(\.graphService) var service1
    @Injected(\.graphService) var service2
    init() {}
}

extension Container {
    var graphWrapper: Factory<GraphWrapper> { unique { GraphWrapper() } }
    var graphService: Factory<MyService> { graph { MyService() } }
}

// Classes for implements scope tests

class ProtocolConsumer {
    @Injected(\.idProvider) var ids
    @Injected(\.valueProvider) var values
    init() {}
}

extension Container {
    var consumer: Factory<ProtocolConsumer> { unique { ProtocolConsumer() } }
    var idProvider: Factory<IDProviding> { unique { self.commonProvider() } }
    var valueProvider: Factory<ValueProviding> { unique { self.commonProvider() } }
    private var commonProvider: Factory<MyService> { graph { MyService() } }
}

// Custom Conatiner

final class CustomContainer: SharedContainer, AutoRegistering {
    static var shared = CustomContainer()
    static var count = 0
    var count = 0
    var test: Factory<MyServiceType> {
        shared {
            MockServiceN(32)
        }
    }
    var decorated: Factory<MyService> {
        unique {
            MyService()
        }
        .decorator { _ in
            self.count += 1
        }
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
    var manager = ContainerManager()
}
