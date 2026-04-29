//
//  TestNonExtendableContainer.swift
//  FactoryDemo
//
//  Created by Michael Long on 2/20/23.
//

import Foundation
import FactoryKit

final class ServiceContainer: @preconcurrency SharedContainer {
    // CONFORMANCE
    static let shared = ServiceContainer()
    let manager = ContainerManager()

    // DON'T DO THIS
//    @MainActor var service1: Factory<InjectedService> = self {
//        InjectedService()
//    }
    // DO THIS INSTEAD
    @MainActor var service2: Factory<InjectedService> {
        self { InjectedService() }
    }
}

extension ServiceContainer {
    @MainActor var extendedService: Factory<InjectedService> {
        self { InjectedService() }.cached
    }
}

extension ServiceContainer {
    @MainActor static func test() {
        #if DEBUG
        Self.shared.manager.trace.toggle()
        let _ = Self.shared.service2()
        let _ = Self.shared.extendedService()
        let _ = Self.shared.extendedService()
        Self.shared.manager.trace.toggle()
        #endif
    }
}
