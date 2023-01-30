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
    var simpleService2: Factory<SimpleService> {
        .init(self) { SimpleService() }
    }
}

extension Container {
    var simpleService3: Factory<SimpleService> {
        makes { SimpleService() }
    }
}

extension Container {
    var contentViewModel: Factory<ContentModuleViewModel> { Factory(self) { ContentModuleViewModel() } }
}

extension SharedContainer {
    var myServiceType: Factory<MyServiceType> { Factory(self) { MyService() } }
}

final class OrderContainer: SharedContainer {
    static var shared = OrderContainer()

    var optionalService: Factory<SimpleService?> { Factory(self) { nil } }

    var constructedService: Factory<MyConstructedService> {
        makes {
            MyConstructedService(service: self.myServiceType())
        }
    }

    var additionalService: Factory<SimpleService> {
        makes { SimpleService() }
            .custom(scope: .session)
    }
    var manager = ContainerManager()
}

extension OrderContainer {
    var argumentService: ParameterFactory<Int, ParameterService> {
        makes { count in ParameterService(count: count) }
    }

}

extension OrderContainer {
    var selfService: Factory<MyServiceType> {
        makes { MyService() }
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
        Factory(self) { Multiple() }
    }
    var aService: Factory<AServiceType> { makes { self.multiple() } }
    var bService: Factory<BServiceType> { makes { self.multiple() } }
}

class MultipleDemo {
    var aService: AServiceType = Container.shared.aService()
    var bService: BServiceType = Container.shared.bService()
}

extension SharedContainer {
//    @inlinable public func scope<T>(_ scope: Scope?, key: String = #function, _ factory: @escaping () -> T) -> Factory<T> {
//        Factory(self, key: key, factory).custom(scope: scope)
//    }
//
//    var someOtherService: Factory<MyServiceType> { scope(.shared) { MyService() } }
}
