//
//  TestNonExtendableContainer.swift
//  FactoryDemo
//
//  Created by Michael Long on 2/20/23.
//

import Foundation
import Factory

final class ServiceContainer: SharedContainer {
    // CONFORMANCE
    static let shared = ServiceContainer()
    let manager = ContainerManager()

    // DON'T DO THIS
//    lazy var service1: Factory<MyServiceType> = self {
//        InjectedService()
//    }
    // DO THIS INSTEAD
    var service2: Factory<MyServiceType> {
        self { InjectedService() }
    }
}

extension ServiceContainer {
    var extendedService: Factory<MyServiceType> {
        self { InjectedService() }.cached
    }
}

extension ServiceContainer {
    static var staticServiceMethod1: Factory<MyServiceType> {
        Factory(shared) { InjectedService() }
    }
    static var staticServiceMethod2: Factory<MyServiceType> {
        ServiceContainer.shared.self { InjectedService() }
    }
}

extension ServiceContainer {
    static func test() {
        #if DEBUG
        Self.shared.manager.trace.toggle()
        let _ = Self.staticServiceMethod1()
        let _ = Self.staticServiceMethod2()
        let _ = Self.shared.service2()
        let _ = Self.shared.extendedService()
        let _ = Self.shared.extendedService()
        Self.shared.manager.trace.toggle()
        #endif
    }
}
