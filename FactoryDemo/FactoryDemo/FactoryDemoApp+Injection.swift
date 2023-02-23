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
        unique { SimpleService() }
    }

    var simpleService2: Factory<SimpleService> {
        unique { SimpleService() }
    }

    var simpleService3: Factory<SimpleService> {
        singleton { SimpleService() }
    }

    var simpleService4: Factory<SimpleService> {
        singleton { SimpleService() }
    }

}

extension Container {
    var contentViewModel: Factory<ContentViewModel> { unique { ContentViewModel() } }
}

extension SharedContainer {
    var myServiceType: Factory<MyServiceType> { unique { MyService() } }
    var sharedService: Factory<MyServiceType> { shared { MyService() } }
}

final class DemoContainer: ObservableObject, SharedContainer {
    static var shared = DemoContainer()

    var optionalService: Factory<SimpleService?> { unique { nil } }

    var constructedService: Factory<MyConstructedService> {
        unique {
            MyConstructedService(service: self.myServiceType())
        }
    }

    var additionalService: Factory<SimpleService> {
        scope(.session) { SimpleService() }
    }

    var manager = ContainerManager()
}

extension DemoContainer {
    var argumentService: ParameterFactory<Int, ParameterService> {
        unique { count in ParameterService(count: count) }
    }
}

extension DemoContainer {
    var selfService: Factory<MyServiceType> {
        unique { MyService() }
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

    }
}

// implements

class CycleDemo {
    @Injected(\.aService) var aService: AServiceType
    @Injected(\.bService) var bService: BServiceType
}

public protocol AServiceType: AnyObject {
    var id: UUID { get }
}

public protocol BServiceType: AnyObject {
    func text() -> String
}

class ImplementsAB: AServiceType, BServiceType {
    @Injected(\.networkService) var networkService
    var id: UUID = UUID()
    func text() -> String {
        "Multiple"
    }
}

class NetworkService {
    @LazyInjected(\.preferences) var preferences
    func load() {}
}

class Preferences {
    func load() {}
}

extension Container {
    var cycleDemo: Factory<CycleDemo> {
        unique { CycleDemo() }
    }
    var aService: Factory<AServiceType> {
        unique { self.implementsAB() }
    }
    var bService: Factory<BServiceType> {
        unique { self.implementsAB() }
    }
    var networkService: Factory<NetworkService> {
        unique { NetworkService() }
    }
    var preferences: Factory<Preferences> {
        unique { Preferences() }
    }
    private var implementsAB: Factory<AServiceType&BServiceType> {
        graph { ImplementsAB() }
    }
}

extension SharedContainer {
//    @inlinable public func scope<T>(_ scope: Scope?, key: String = #function, _ factory: @escaping () -> T) -> Factory<T> {
//        Factory(self, key: key, factory).custom(scope: scope)
//    }
//
//    var someOtherService: Factory<MyServiceType> { scope(.shared) { MyService() } }
}

