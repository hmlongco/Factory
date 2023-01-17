//
//  ContentViewModel.swift
//  FactoryDemo
//
//  Created by Michael Long on 1/15/23.
//

import Foundation

class ContentViewModel: ObservableObject {

    // Old factory static service Locator
    let oldSchool = Container.oldSchool()

    // New shared service Locator
    let service = Container.shared.constructedService()

    // Constructor initialized from container
    let service2: MyServiceType

    // Lazy initialized from passed container
    private let container: Container
    private lazy var service3: MyConstructedService = container.constructedService()
    private lazy var service4: MyServiceType = container.cachedService()
    private lazy var service5: SimpleService = container.singletonService()
    private lazy var service6A: MyServiceType = container.sharedService()
    private lazy var service6B: MyServiceType = container.sharedService()

    // Injected property from default shared container
    @Injected(\.constructedService) var constructed

    // Injected property from shared custom container
    @Injected(\MyContainer.anotherService) var anotherService

    // Injected property from shared custom container
    @Injected(\.graphBase) var graphBase

    // Constructor
    init(container: Container) {
        // construct from container
        service2 = container.service()

        // save container reference for lazy resolution
        self.container = container

        print(constructed.text())
        print(service.text())
        print(service2.text())
        print(service3.text())
        print(service4.text())
        print(service5.text())
    }

    func test() {
        print(container.manager.registrations)
        print(container.manager.cache)
        
        print(Scope.cached.scopeID)
        container.manager.reset(scope: .cached)
        print(container.manager.registrations)
        print(container.manager.cache)

        container.manager.reset()
        print(container.manager.registrations)
        print(container.manager.cache)

        print("SHARED = \(service6A.id == service6B.id)")
        print("GRAPH = \(graphBase.dependency1.id == graphBase.dependency2.id)")

        print(container.manager.registrations)
        print(container.manager.cache)

        print(container.string1())
        print(container.string2())
        container.string1.register { "New String 1" }
        print(container.string1())
        print(container.string2())

        // container.testCircularDependencies()
    }

}
