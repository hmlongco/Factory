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

    var simpleService2: Factory<SimpleService> {
        .init(self) { SimpleService() }
    }

    var simpleService3: Factory<SimpleService> {
        makes { SimpleService() }
    }

}

extension Container {
    var contentViewModel: Factory<ContentModuleViewModel> { Factory(self) { ContentModuleViewModel() } }
}

extension SharedContainer {
    var myServiceType: Factory<MyServiceType> { Factory(self) { MyService() } }
    var sharedService: Factory<MyServiceType> { Factory(self) { MyService() }.shared }
}

final class DemoContainer: ObservableObject, SharedContainer {
    static var shared = DemoContainer()

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

extension DemoContainer {
    var argumentService: ParameterFactory<Int, ParameterService> {
        makes { count in ParameterService(count: count) }
    }
}

extension DemoContainer {
    var selfService: Factory<MyServiceType> {
        makes { MyService() }
    }
}

#if DEBUG
extension DemoContainer {
    static var mock1: DemoContainer {
        shared.myServiceType.register { ParameterService(count: 3) }
        return shared
    }
}
#endif

extension Scope {
    static var session = Cached()
}

extension Container {
    func setupMocks() {
        myServiceType.register { MockServiceN(4) }

        DemoContainer.shared.optionalService.register { SimpleService() }

#if DEBUG
        decorator {
            print("FACTORY: \(type(of: $0)) (\(Int(bitPattern: ObjectIdentifier($0 as AnyObject))))")
        }
#endif
    }
}

// implements

public protocol AServiceType {
    var id: UUID { get }
    func text() -> String
}

public protocol BServiceType {
    var id: UUID { get }
    func text() -> String
}

class ImplementsAB: AServiceType, BServiceType {
    var id: UUID = UUID()
    func text() -> String {
        return "Multiple"
    }
}

extension Container {
    private var implementsAB: Factory<AServiceType&BServiceType> {
        makes { ImplementsAB() }.graph
    }
    var aService: Factory<AServiceType> { makes { self.implementsAB() } }
    var bService: Factory<BServiceType> { makes { self.implementsAB() } }
    var multiple: Factory<MultipleDemo> { makes { MultipleDemo() } }
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
