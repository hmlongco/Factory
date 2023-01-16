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
    let service2: MyConstructedService

    // Lazy initialized from passed container
    private let container: Container
    private lazy var service3: MyConstructedService = container.constructedService()
    private lazy var service4: MyServiceType = container.cachedService()

    // Injected property from default shared container
    @Injected(\.constructedService) var constructed

    // Injected property from shared custom container
    @Injected(\MyContainer.anotherService) var anotherService

    // Constructor
    init(container: Container) {
        // construct from container
        service2 = container.constructedService()

        // save container reference for lazy resolution
        self.container = container

        print(constructed.text())
        print(service.text())
        print(service2.text())
        print(service4.text())
    }

}
