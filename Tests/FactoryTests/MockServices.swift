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
    @Injected(Container.recursiveB) var b: RecursiveB?
    init() {}
}

class RecursiveB {
    @Injected(Container.recursiveC) var c: RecursiveC?
    init() {}
}

class RecursiveC {
    @Injected(Container.recursiveA) var a: RecursiveA?
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
    static let myServiceType = Factory<MyServiceType> { MyService() }
    static let myServiceType2 = Factory<MyServiceType> { MyService() }

    static let mockService = Factory { MockService() }

    static let cachedService = Factory(scope: .cached) { MyService() }
    static let cachedOptionalService = Factory<MyServiceType?>(scope: .cached) { MyService() }
    static let cachedEmptyOptionalService = Factory<MyServiceType?>(scope: .cached) { nil }

    static let sharedService = Factory(scope: .shared) { MyService() }
    static let sharedExplicitProtocol = Factory<MyServiceType>(scope: .shared) { MyService() }
    static let sharedInferredProtocol = Factory(scope: .shared) { MyService() as MyServiceType }
    static let sharedOptionalProtocol = Factory<MyServiceType?>(scope: .shared) { MyService() }

    static let optionalService = Factory<MyServiceType?> { MyService() }
    static let optionalValueService = Factory<MyServiceType?> { ValueService() }

    static let singletonService = Factory(scope: .singleton) { MyService() }

    static let nilSService = Factory<MyServiceType?> { nil }
    static let nilCachedService = Factory<MyServiceType?>(scope: .cached) { nil }
    static let nilSharedService = Factory<MyServiceType?>(scope: .shared) { nil }

    static let sessionService = Factory(scope: .session) { MyService() }

    static let valueService = Factory(scope: .cached) { ValueService() }
    static let sharedValueService = Factory(scope: .shared) { ValueService() }
    static let sharedValueProtocol = Factory<MyServiceType>(scope: .shared) { ValueService() }

    static let promisedService = Factory<MyServiceType?> { nil }

}

// For parameter tests
extension Container {
    static var parameterService = ParameterFactory { n in
        ParameterService(value: n) as MyServiceType
    }
    static var scopedParameterService = ParameterFactory(scope: .cached) { n in
        ParameterService(value: n) as MyServiceType
    }
}

extension Container {
    static var tupleService = ParameterFactory<(Int, Int), MyServiceType> { (a, b) in
        ParameterService(value: a + b)
    }
}

// Custom scope

extension Container.Scope {
    static let session = Cached()
}

// Class for recursive scope test

extension Container {
    static var recursiveA = Factory<RecursiveA?> { RecursiveA() }
    static var recursiveB = Factory<RecursiveB?> { RecursiveB() }
    static var recursiveC = Factory<RecursiveC?> { RecursiveC() }
}

// Classes for graph scope tests

class GraphWrapper {
    @Injected(Container.graphService) var service1
    @Injected(Container.graphService) var service2
    init() {}
}

extension Container {
    static let graphWrapper = Factory { GraphWrapper() }
    static let graphService = Factory(scope: .graph) { MyService() }
}

// Classes for implements scope tests

class ProtocolConsumer {
    @Injected(Container.idProvider) var ids
    @Injected(Container.valueProvider) var values
    init() {}
}

extension Container {
    static let consumer = Factory { ProtocolConsumer() }
    static let idProvider = Factory<IDProviding> { commonProvider() }
    static let valueProvider = Factory<ValueProviding> { commonProvider() }
    private static let commonProvider = Factory(scope: .graph) { MyService() }
}
