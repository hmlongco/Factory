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
    static var myServiceType: Factory<MyServiceType> { factory { MyService() } }

    var myServiceType: Factory<MyServiceType> { factory { MyService() } }
    var myServiceType2: Factory<MyServiceType> { factory { MyService() } }

    var mockService: Factory<MockService> { factory { MockService() } }

    var cachedService: Factory<MyService> { factory { MyService() }.cached }
    var cachedOptionalService: Factory<MyServiceType?> { factory { MyService() }.cached }
    var cachedEmptyOptionalService: Factory<MyServiceType?> { factory { nil }.cached }

    var sharedService: Factory<MyServiceType> { factory { MyService() }.shared }
    var sharedExplicitProtocol: Factory<MyServiceType> { factory { MyService() }.shared }
    var sharedInferredProtocol: Factory<MyServiceType> { factory { MyService() as MyServiceType }.shared }
    var sharedOptionalProtocol: Factory<MyServiceType?> { factory { MyService() }.shared }

    var optionalService: Factory<MyServiceType?> { factory { MyService() } }
    var optionalValueService: Factory<MyServiceType?> { factory { ValueService() } }

    var singletonService: Factory<MyServiceType> { factory { MyService() }.singleton }

    var nilSService: Factory<MyServiceType?> { factory { nil } }
    var nilCachedService: Factory<MyServiceType?> { factory { nil }.cached }
    var nilSharedService: Factory<MyServiceType?> { factory { nil }.shared }

    var sessionService: Factory<MyService> { factory { MyService() }.custom(scope: .session) }

    var valueService: Factory<ValueService> { factory { ValueService() }.cached }
    var sharedValueService: Factory<ValueService> { factory { ValueService() }.shared }
    var sharedValueProtocol: Factory<ValueService> { factory { ValueService() }.shared }

    var promisedService: Factory<MyServiceType?> { factory { nil } }

}

// For parameter tests
extension Container {
    var parameterService: ParameterFactory<Int, ParameterService> {
        ParameterFactory(self) { ParameterService(value: $0) }
    }
    var scopedParameterService: ParameterFactory<Int, ParameterService> {
        ParameterFactory(self) { ParameterService(value: $0) }.cached
    }
}

// Custom scope

extension Scope {
    static var session = Cached()
}

// Class for recursive scope test

extension Container {
    var recursiveA: Factory<RecursiveA?> { factory { RecursiveA() } }
    var recursiveB: Factory<RecursiveB?> { factory { RecursiveB() } }
    var recursiveC: Factory<RecursiveC?> { factory { RecursiveC() } }
}

// Classes for graph scope tests

class GraphWrapper {
    @Injected(\.graphService) var service1
    @Injected(\.graphService) var service2
    init() {}
}

extension Container {
    var graphWrapper: Factory<GraphWrapper> { factory { GraphWrapper() } }
    var graphService: Factory<MyService> { factory { MyService() }.graph }
}

// Classes for implements scope tests

class ProtocolConsumer {
    @Injected(\.idProvider) var ids
    @Injected(\.valueProvider) var values
    init() {}
}

extension Container {
    var consumer: Factory<ProtocolConsumer> { factory { ProtocolConsumer() } }
    var idProvider: Factory<IDProviding> { factory { self.commonProvider() } }
    var valueProvider: Factory<ValueProviding> { factory { self.commonProvider() } }
    private var commonProvider: Factory<MyService> { factory { MyService() }.graph }
}

// Custom Conatiner

final class CustomContainer: SharedContainer, AutoRegistering {
    static var shared = CustomContainer()
    static var count = 0
    var count = 0
    var test: Factory<MyServiceType> {
        factory {
            MockServiceN(32)
        }
        .shared
    }
    var decorated: Factory<MyService> {
        factory {
            MyService()
        }
        .decorator { _ in
            self.count += 1
        }
    }
    func autoRegister() {
        Self.count = 1
        self.count = 1
        self.decorator { _ in
            Self.count += 1
        }
    }
    var manager = ContainerManager()
}
