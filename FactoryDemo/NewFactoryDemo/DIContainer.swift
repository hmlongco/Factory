//
//  DIContainer.swift
//  NewFactoryDemo
//
//  Created by Michael Long on 1/24/23.
//

import Foundation

protocol ContainerResolving: AnyObject {
    func resolve<T>(_ keyPath: KeyPath<Self, T>) -> T
    func register<T>(_ keyPath: KeyPath<Self, T>, _ factory: @escaping () -> T)
    var registrations: [String:Any] { get set }
}

extension ContainerResolving {
    func register<T>(_ keyPath: KeyPath<Self, T>, _ factory: @escaping () -> T) {
        registrations[String(describing: T.self)] = factory
        print("DIContainer.register \(T.self) \(keyPath)")
    }
    func resolve<T>(_ keyPath: KeyPath<Self, T>) -> T {
        if let factory = registrations[String(describing: T.self)] as? () -> T {
            return factory()
        }
        return self[keyPath: keyPath]
    }
    func factory<T>(_ key: String = #function, _ factory: () -> T) -> T {
        print("DIContainer.factory \(T.self) \(key)")
        return factory()
    }
}

final class DIContainer: ContainerResolving {
    static let shared = DIContainer()
    var registrations = [String:Any]()
}

extension DIContainer {
    var service: MyServiceType {
        factory { MyService() }
    }
    var service2: MyServiceType {
        factory { MyService() }
    }
}

class DITest {
    let service = DIContainer.shared.resolve(\.service)
    let service2: MyServiceType
    init() {
        DIContainer.shared.register(\.service2) {
            MockServiceN(3)
        }
        service2 = DIContainer.shared.service2
        print(service2.text())
    }
}

