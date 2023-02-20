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
    static var shared = ServiceContainer()
    var manager = ContainerManager()

    // DON'T DO THIS
    lazy var service1: Factory<MyServiceType> = unique {
        MyService()
    }
    // DO THIS INSTEAD
    var service2: Factory<MyServiceType> {
        unique { MyService() }
    }
}

extension ServiceContainer {
    var extendedService: Factory<MyServiceType> {
        unique { MyService() }
    }
}

extension ServiceContainer {
    static var staticService1: Factory<MyServiceType> {
        Factory(shared) { MyService() }
    }
    static var staticService2: Factory<MyServiceType> {
        ServiceContainer.shared.unique { MyService() }
    }
}

extension ServiceContainer {
    static func test() {
        Self.shared.manager.trace.toggle()
        let _ = Self.staticService1()
        let _ = Self.staticService2()
        let _ = Self.shared.service1()
        let _ = Self.shared.extendedService()
        let _ = Self.shared.service2()
        Self.shared.manager.trace.toggle()
    }
}
