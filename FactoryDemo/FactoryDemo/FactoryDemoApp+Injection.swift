//
//  FactoryDemoApp+Injection.swift
//  FactoryDemo
//
//  Created by Michael Long on 6/2/22.
//

import Foundation
import FactoryMacros
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
        self { SimpleService() }
    }

    var simpleService4: Factory<SimpleService> {
        self { SimpleService() }.singleton
    }

}

extension Container {
    var contentViewModel: Factory<ContentViewModel> { self { ContentViewModel() } }
}

extension Container {
    var previewService: Factory<MyServiceType> {
        self { MyService() }
            .onPreview { MockServiceN(55) }
            .singleton
    }
}

extension SharedContainer {
    var myServiceType: Factory<MyServiceType> { self { MyService() } }
    var sharedService: Factory<MyServiceType> { self { MyService() }.shared }
}

final class DemoContainer: ObservableObject, SharedContainer {
    static let shared = DemoContainer()

    var optionalService: Factory<SimpleService?> { self { nil } }

    var constructedService: Factory<MyConstructedService> {
        self {
            MyConstructedService(service: self.myServiceType())
        }
    }

    var additionalService: Factory<SimpleService> {
        self { SimpleService() }
            .scope(.session)
    }

    let manager = ContainerManager()
}

extension DemoContainer {
    var argumentService: ParameterFactory<Int, ParameterService> {
        self { count in ParameterService(count: count) }
    }
}

extension DemoContainer {
    var selfService: Factory<MyServiceType> {
        self { MyService() }
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
    static let session = Cached()
}

extension Container {
    func setupMocks() {
        DemoContainer.shared.optionalService.register { SimpleService() }
        let _ = Container.shared.modelData()
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
        self { CycleDemo() }
    }
    var aService: Factory<AServiceType> {
        self { self.implementsAB() }
    }
    var bService: Factory<BServiceType> {
        self { self.implementsAB() }
    }
    var networkService: Factory<NetworkService> {
        self { NetworkService() }
    }
    var preferences: Factory<Preferences> {
        self { Preferences() }
    }
    private var implementsAB: Factory<AServiceType&BServiceType> {
        self { ImplementsAB() }
            .scope(.graph)
    }
}

extension Container {
    var promisedService: Factory<MyServiceType?> {
        promised()
    }
}


extension Container {
    @DefineFactory({ MyService() }, scope: .unique)
    var myMacroService: MyServiceType
}
