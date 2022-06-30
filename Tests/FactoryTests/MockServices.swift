//
//  File.swift
//  
//
//  Created by Michael Long on 5/1/22.
//

import Foundation
@testable import Factory

protocol MyServiceType {
    var id: UUID { get }
    func text() -> String
}

class MyService: MyServiceType {
    let id = UUID()
    func text() -> String {
        "MyService"
    }
}

class MockService: MyServiceType {
    let id = UUID()
    func text() -> String {
        "MockService"
    }
}

class MockServiceN: MyServiceType {
    let id = UUID()
    let n: Int
    init(_ n: Int) {
        self.n = n
    }
    func text() -> String {
        "MockService\(n)"
    }
}

struct ValueService: MyServiceType {
    let id = UUID()
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
    init() {}
}

extension Container {
    static let myServiceType = Factory<MyServiceType> { MyService() }
    static let myServiceType2 = Factory<MyServiceType> { MyService() }
    static let mockService = Factory { MockService() }
    static let cachedService = Factory(scope: .cached) { MyService() }
    static let sharedService = Factory(scope: .shared) { MyService() }
    static let singletonService = Factory(scope: .singleton) { MyService() }
    static let optionalService = Factory<MyServiceType?> { MyService() }
    static let nilSService = Factory<MyServiceType?> { nil }
    static let nilScopedService = Factory<MyServiceType?>(scope: .cached) { nil }
    static let sessionService = Factory(scope: .session) { MyService() }
    static let valueService = Factory(scope: .cached) { ValueService() }
    static let sharedValueService = Factory(scope: .shared) { ValueService() }
    static let promisedService = Factory<MyServiceType?> { nil }
}

extension Container {
    static var recursiveA = Factory<RecursiveA?> { RecursiveA() }
    static var recursiveB = Factory<RecursiveB?> { RecursiveB() }
    static var recursiveC = Factory<RecursiveC?> { RecursiveC() }
}

extension Container.Scope {
    static let session = Cached()
}
