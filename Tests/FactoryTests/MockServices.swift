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
    static var myServiceType: Factory<MyServiceType> { shared.make { MyService() } }

    var myServiceType: Factory<MyServiceType> { make { MyService() } }
    var myServiceType2: Factory<MyServiceType> { make { MyService() } }

    var mockService: Factory<MockService> { make { MockService() } }

    var cachedService: Factory<MyService> { make { MyService() }.cached }
    var cachedOptionalService: Factory<MyServiceType?> { make { MyService() }.cached }
    var cachedEmptyOptionalService: Factory<MyServiceType?> { make { nil }.cached }

    var sharedService: Factory<MyServiceType> { make { MyService() }.shared }
    var sharedExplicitProtocol: Factory<MyServiceType> { make { MyService() }.shared }
    var sharedInferredProtocol: Factory<MyServiceType> { make { MyService() }.shared }
    var sharedOptionalProtocol: Factory<MyServiceType?> { make { MyService() }.shared }

    var optionalService: Factory<MyServiceType?> { make { MyService() } }
    var optionalValueService: Factory<MyServiceType?> { make { ValueService() } }

    var singletonService: Factory<MyServiceType> { make { MyService() }.singleton }

    var nilSService: Factory<MyServiceType?> { make { nil } }
    var nilCachedService: Factory<MyServiceType?> { make { nil }.cached }
    var nilSharedService: Factory<MyServiceType?> { make { nil }.shared }

    var sessionService: Factory<MyService> { make { MyService() }.custom(scope: .session) }

    var valueService: Factory<ValueService> { make { ValueService() }.cached }
    var sharedValueService: Factory<ValueService> { make { ValueService() }.shared }
    var sharedValueProtocol: Factory<ValueService> { make { ValueService() }.shared }

    var promisedService: Factory<MyServiceType?> { make { nil } }

}

// For parameter tests
extension Container {
    var parameterService: ParameterFactory<Int, ParameterService> {
        make { ParameterService(value: $0) }
    }
    var scopedParameterService: ParameterFactory<Int, ParameterService> {
        make { ParameterService(value: $0) }.cached
    }
}

// Custom scope

extension Scope {
    static var session = Cached()
}

// Class for recursive scope test

extension Container {
    var recursiveA: Factory<RecursiveA?> { make { RecursiveA() } }
    var recursiveB: Factory<RecursiveB?> { make { RecursiveB() } }
    var recursiveC: Factory<RecursiveC?> { make { RecursiveC() } }
}

// Classes for graph scope tests

class GraphWrapper {
    @Injected(\.graphService) var service1
    @Injected(\.graphService) var service2
    init() {}
}

extension Container {
    var graphWrapper: Factory<GraphWrapper> { make { GraphWrapper() } }
    var graphService: Factory<MyService> { make { MyService() }.graph }
}

// Classes for implements scope tests

class ProtocolConsumer {
    @Injected(\.idProvider) var ids
    @Injected(\.valueProvider) var values
    init() {}
}

extension Container {
    var consumer: Factory<ProtocolConsumer> { make { ProtocolConsumer() } }
    var idProvider: Factory<IDProviding> { make { self.commonProvider() } }
    var valueProvider: Factory<ValueProviding> { make { self.commonProvider() } }
    private var commonProvider: Factory<MyService> { make { MyService() }.graph }
}

// Custom Conatiner

final class CustomContainer: SharedContainer, AutoRegistering {
    static var shared = CustomContainer()
    static var count = 0
    var count = 0
    var test: Factory<MyServiceType> {
        make {
            MockServiceN(32)
        }
        .shared
    }
    var decorated: Factory<MyService> {
        make {
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
