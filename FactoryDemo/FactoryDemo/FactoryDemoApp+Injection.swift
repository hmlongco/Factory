//
//  FactoryDemoApp+Injection.swift
//  FactoryDemo
//
//  Created by Michael Long on 6/2/22.
//

import Foundation
import Factory
import Common
import SwiftUI

extension Container {
    var simpleService: Factory<SimpleService> {
        Factory(self) { SimpleService() }
    }
}

extension Container {
    var contentViewModel: Factory<ContentModuleViewModel> { self { ContentModuleViewModel() } }
}

extension SharedContainer {
    var myServiceType: Factory<MyServiceType> { self { MyService() } }
    var sharedService: Factory<MyServiceType> { self { MyService() }.shared }
}

final class OrderContainer: SharedContainer {
    static var shared = OrderContainer()

    var optionalService: Factory<SimpleService?> { self { nil } }

    var constructedService: Factory<MyConstructedService> {
        self { MyConstructedService(service: self.myServiceType()) }
    }

    var additionalService: Factory<SimpleService> {
        self { SimpleService() }
            .custom(scope: .session)
    }
    var manager = ContainerManager()
}

extension OrderContainer {
    var argumentService: ParameterFactory<Int, ParameterService> {
        ParameterFactory(self) { count in ParameterService(count: count) }
    }

}

extension OrderContainer {
    var selfService: Factory<MyServiceType> {
        self { MyService() }
    }
}

extension Scope {
    static var session = Cached()
}

extension Container {
    func setupMocks() {
        myServiceType.register { MockServiceN(4) }

        OrderContainer.shared.optionalService.register { SimpleService() }

#if DEBUG
        decorator {
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
    private var multiple: Factory<AServiceType&BServiceType> {
        self { Multiple() }
    }
    var aService: Factory<AServiceType> { self { self.multiple() } }
    var bService: Factory<BServiceType> { self { self.multiple() } }
}

class MultipleDemo {
    var aService: AServiceType = Container.shared.aService()
    var bService: BServiceType = Container.shared.bService()
}
