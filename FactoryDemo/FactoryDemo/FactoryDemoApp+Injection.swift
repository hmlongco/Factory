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
    var contentViewModel: Factory<ContentModuleViewModel> { make { ContentModuleViewModel() } }
}

extension SharedContainer {
    var myServiceType: Factory<MyServiceType> { make { MyService() } }
    var sharedService: Factory<MyServiceType> { make { MyService() }.shared }
}

final class OrderContainer: SharedContainer {
    static var shared = OrderContainer()

    var optionalService: Factory<SimpleService?> { make { nil } }

    var constructedService: Factory<MyConstructedService> {
        make { MyConstructedService(service: self.myServiceType()) }
    }

    var additionalService: Factory<SimpleService> {
        make { SimpleService() }
            .custom(scope: .session)
    }
    var manager = ContainerManager()
}

extension OrderContainer {
    var argumentService: ParameterFactory<Int, ParameterService> {
        make { count in ParameterService(count: count) }
    }

}

extension OrderContainer {
    var selfService: Factory<MyServiceType> {
        make { MyService() }
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
        make { Multiple() }
    }
    var aService: Factory<AServiceType> { make { self.multiple() } }
    var bService: Factory<BServiceType> { make { self.multiple() } }
}

class MultipleDemo {
    var aService: AServiceType = Container.shared.aService()
    var bService: BServiceType = Container.shared.bService()
}

extension SharedContainer {
    @inlinable public func scope<T>(_ scope: Scope?, key: String = #function, _ factory: @escaping () -> T) -> Factory<T> {
        Factory(self, key: key, factory).custom(scope: scope)
    }

    var someOtherService: Factory<MyServiceType> { scope(.shared) { MyService() } }
}
