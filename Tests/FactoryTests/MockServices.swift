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
    static var myServiceType: Factory<MyServiceType> { makes { MyService() } }

    var myServiceType: Factory<MyServiceType> { makes { MyService() } }
    var myServiceType2: Factory<MyServiceType> { makes { MyService() } }

    var mockService: Factory<MockService> { makes { MockService() } }

    var cachedService: Factory<MyService> { makes { MyService() }.cached }
    var cachedOptionalService: Factory<MyServiceType?> { makes { MyService() }.cached }
    var cachedEmptyOptionalService: Factory<MyServiceType?> { makes { nil }.cached }

    var sharedService: Factory<MyServiceType> { makes { MyService() }.shared }
    var sharedExplicitProtocol: Factory<MyServiceType> { makes { MyService() }.shared }
    var sharedInferredProtocol: Factory<MyServiceType> { makes { MyService() }.shared }
    var sharedOptionalProtocol: Factory<MyServiceType?> { makes { MyService() }.shared }

    var optionalService: Factory<MyServiceType?> { makes { MyService() } }
    var optionalValueService: Factory<MyServiceType?> { makes { ValueService() } }

    var singletonService: Factory<MyServiceType> { makes { MyService() }.singleton }

    var nilSService: Factory<MyServiceType?> { makes { nil } }
    var nilCachedService: Factory<MyServiceType?> { makes { nil }.cached }
    var nilSharedService: Factory<MyServiceType?> { makes { nil }.shared }

    var sessionService: Factory<MyService> { makes { MyService() }.custom(scope: .session) }

    var valueService: Factory<ValueService> { makes { ValueService() }.cached }
    var sharedValueService: Factory<ValueService> { makes { ValueService() }.shared }
    var sharedValueProtocol: Factory<ValueService> { makes { ValueService() }.shared }

    var promisedService: Factory<MyServiceType?> { makes { nil } }

}

// For parameter tests
extension Container {
    var parameterService: ParameterFactory<Int, ParameterService> {
        makes { ParameterService(value: $0) }
    }
    var scopedParameterService: ParameterFactory<Int, ParameterService> {
        makes { ParameterService(value: $0) }.cached
    }
}

// Custom scope

extension Scope {
    static var session = Cached()
}

// Class for recursive scope test

extension Container {
    var recursiveA: Factory<RecursiveA?> { makes { RecursiveA() } }
    var recursiveB: Factory<RecursiveB?> { makes { RecursiveB() } }
    var recursiveC: Factory<RecursiveC?> { makes { RecursiveC() } }
}

// Classes for graph scope tests

class GraphWrapper {
    @Injected(\.graphService) var service1
    @Injected(\.graphService) var service2
    init() {}
}

extension Container {
    var graphWrapper: Factory<GraphWrapper> { makes { GraphWrapper() } }
    var graphService: Factory<MyService> { makes { MyService() }.graph }
}

// Classes for implements scope tests

class ProtocolConsumer {
    @Injected(\.idProvider) var ids
    @Injected(\.valueProvider) var values
    init() {}
}

extension Container {
    var consumer: Factory<ProtocolConsumer> { makes { ProtocolConsumer() } }
    var idProvider: Factory<IDProviding> { makes { self.commonProvider() } }
    var valueProvider: Factory<ValueProviding> { makes { self.commonProvider() } }
    private var commonProvider: Factory<MyService> { makes { MyService() }.graph }
}

// Custom Conatiner

final class CustomContainer: SharedContainer, AutoRegistering {
    static var shared = CustomContainer()
    static var count = 0
    var count = 0
    var test: Factory<MyServiceType> {
        makes {
            MockServiceN(32)
        }
        .shared
    }
    var decorated: Factory<MyService> {
        makes {
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
    }
    var manager = ContainerManager()
}
