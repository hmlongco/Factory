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

extension Container {
    static let myServiceType = Factory<MyServiceType> { MyService() }
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
//    static let unsafeService = Factory(unsafe: MyServiceType.self)
}

extension Container.Scope {
    static let session = Cached()
}
