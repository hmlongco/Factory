//
//  FactoryDemoApp+Injection.swift
//  FactoryDemo
//
//  Created by Michael Long on 6/2/22.
//

import Foundation
import Factory
import Common

extension Container {
    static let simpleService = Factory { SimpleService() }
}

extension SharedContainer {
    static let myServiceType = Factory<MyServiceType> { MyService() }
    static let sharedService = Factory<MyServiceType>(scope: .shared) { MyService() }
}

class OrderContainer: SharedContainer {
    static let optionalService = Factory<SimpleService?> { nil }
    static let constructedService = Factory { MyConstructedService(service: myServiceType()) }
    static let additionalService = Factory(scope: .session) { SimpleService() }
}

extension OrderContainer {
    static func argumentService(count: Int) -> Factory<ParameterService> {
        Factory { ParameterService(count: count) }
    }
}

extension SharedContainer.Scope {
    static var session = Cached()
}

extension SharedContainer {
    static func setupMocks() {
        myServiceType.register { MockServiceN(4) }

        OrderContainer.optionalService.register { SimpleService() }

#if DEBUG
        Decorator.decorate = {
            print("FACTORY: \(type(of: $0)) (\(Int(bitPattern: ObjectIdentifier($0 as AnyObject))))")
        }
#endif
    }
}

// implements

public protocol AServiceType {
    func text() -> String
}

public protocol BServiceType {
    func text() -> String
}

class Multiple: AServiceType, BServiceType {
    func text() -> String {
        return "Multiple"
    }
}

extension Container {
    private static var multiple = Factory<AServiceType&BServiceType> { Multiple() }
    static var aService = Factory<AServiceType> { multiple() }
    static var bService = Factory<BServiceType> { multiple() }
}

class MultipleDemo {
    var aService: AServiceType = Container.aService()
    var bService: BServiceType = Container.bService()
}
