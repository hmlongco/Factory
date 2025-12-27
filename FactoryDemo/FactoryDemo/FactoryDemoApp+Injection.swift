//
//  FactoryDemoApp+Injection.swift
//  FactoryDemo
//
//  Created by Michael Long on 6/2/22.
//

import Foundation
import FactoryKit
import Common
import SwiftUI

extension Container {

    @MainActor var simpleService: Factory<SimpleService> {
        Factory(self) { SimpleService() }
    }

    @MainActor var simpleService2: Factory<SimpleService> {
        .init(self) { SimpleService() }
    }

    @MainActor var simpleService3: Factory<SimpleService> {
        self { SimpleService() }
    }

    @MainActor var simpleService4: Factory<SimpleService> {
        self { SimpleService() }.singleton
    }

}

extension Container {
    @MainActor var contentViewModel: Factory<ContentViewModel> {
        self { ContentViewModel() }
    }
}

extension Container {
    @MainActor var previewService: Factory<MyServiceType> {
        self { MyService() }
            .onPreview { MockServiceN(55) }
            .singleton
    }
}

extension SharedContainer {
    @MainActor var myServiceType: Factory<MyServiceType> { self { MyService() } }
    @MainActor var sharedService: Factory<MyServiceType> { self { MyService() }.shared }
}

final class DemoContainer: ObservableObject, SharedContainer {
    static let shared = DemoContainer()

    var optionalService: Factory<SimpleService?> { self { nil } }

    @MainActor var constructedService: Factory<MyConstructedService> {
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
    @MainActor var argumentService: ParameterFactory<Int, ParameterService> {
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
    @MainActor static var mock1: DemoContainer {
        shared.myServiceType.register { ParameterService(count: 3) }
        return shared
    }
}
#endif

extension Scope {
    nonisolated static let session = Cached()
}

extension Container {
    func setupMocks() {
        DemoContainer.shared.optionalService.register { SimpleService() }
        let _ = Container.shared.modelData()
    }
}

// implements

final class CycleDemo: @unchecked Sendable {
    @Injected(\.aService) var aService: AServiceType
    @Injected(\.bService) var bService: BServiceType
}

public protocol AServiceType: AnyObject {
    var id: UUID { get }
}

public protocol BServiceType: AnyObject {
    func text() -> String
}

final class ImplementsAB: AServiceType, BServiceType, @unchecked Sendable {
    @Injected(\.networkService) var networkService
    let id: UUID = UUID()
    func text() -> String {
        "Multiple"
    }
}

final class NetworkService {
    @Injected(\.preferences) var preferences
    func load() {}
}

final class Preferences: Sendable {
    func load() {}
}

extension Container {
    @MainActor var cycleDemo: Factory<CycleDemo> {
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


//extension Container {
//    @DefineFactory({ MyService() }, scope: .unique)
//    var myMacroService: MyServiceType
//}
