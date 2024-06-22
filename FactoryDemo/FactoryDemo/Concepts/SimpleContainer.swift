//
//  SimpleContainer.swift
//  FactoryDemo
//
//  Created by Michael Long on 2/19/23.
//

import Foundation

protocol SimpleContaining: AnyObject, Sendable  {
    var registrations: [ObjectIdentifier:() -> Any] { get set }
}

extension SimpleContaining {
    func resolve<T>(_ keyPath: KeyPath<Self, T>) -> T {
        let id = ObjectIdentifier(keyPath)
        if let factory = registrations[id], let instance = factory() as? T {
            return instance
        }
        return self[keyPath: keyPath]
    }
    func register<T>(_ keyPath: KeyPath<Self, T>, _ factory: @escaping () -> T) {
        let id = ObjectIdentifier(keyPath)
        registrations[id] = factory
    }
}

class SimpleContainerTest {
    static func test() {
        let container = SimpleContainer.shared

        let s1 = container.resolve(\.service1)
        print(s1.self)

        let s2 = container.resolve(\.service2)
        print(s2.self)

        container.register(\.service3) {
            MockServiceN(3)
        }
        let s3 = container.resolve(\.service3)
        print(s3.self)
    }
}

final class SimpleContainer: SimpleContaining, @unchecked Sendable  {
    static let shared = SimpleContainer()
    var registrations: [ObjectIdentifier:() -> Any] = [:]
}

extension SimpleContainer {
    var service1: MyServiceType { MyService() }
    var service2: MyServiceType { MyService() }
    var service3: MyServiceType { MyService() }
}
