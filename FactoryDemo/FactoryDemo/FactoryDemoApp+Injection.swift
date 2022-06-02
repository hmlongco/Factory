//
//  FactoryDemoApp+Injection.swift
//  FactoryDemo
//
//  Created by Michael Long on 6/2/22.
//

import Foundation
import Factory

extension Factory {
    static let simpleService = Factory { SimpleService() }
}

extension SharedFactory {
    static let myServiceType = Factory<MyServiceType> { MyService() }
    static let sharedService = Factory<MyServiceType>(scope: .shared) { MyService() }
}

class OrderFactory: SharedFactory {
    static let optionalService = Factory<SimpleService?> { nil }
    static let constructedService = Factory { MyConstructedService(service: myServiceType()) }
    static let additionalService = Factory(scope: .session) { SimpleService() }
}

extension OrderFactory {
    static func argumentService(count: Int) -> Factory<ArgumentService> {
        Factory { ArgumentService(count: count) }
    }
}

extension SharedFactory.Scope {
    static var session = Cached()
}

extension SharedFactory {
    static func setupMocks() {
        myServiceType.register { MockServiceN(4) }

        OrderFactory.optionalService.register { SimpleService() }

#if DEBUG
        Decorator.decorate = {
            print("DI: \(type(of: $0)) (\(Int(bitPattern: ObjectIdentifier($0 as AnyObject))))")
        }
#endif
    }
}
