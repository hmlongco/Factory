//
//  EnvironmentViewModel.swift
//  FactoryDemo
//
//  Created by Michael Long on 6/2/22.
//

import Foundation
import Factory
import Common
import Networking

protocol MyCustomContainer: SharedContainer {
    var constructedService: Factory<MyConstructedService> { get }
    var additionalService: Factory<SimpleService> { get }
}

class ContainerDemoViewModel: ObservableObject {

    @Injected(\.customContainer) var container

    lazy var constructedService = container.constructedService()
    lazy var additionalService = container.additionalService()

    private let service: MyServiceType

    init(_ container: DemoContainer = .shared) {
        service = container.myServiceType()
    }

    func text() -> String {
        return "Demo \(service.text())"
    }

}



extension DemoContainer: MyCustomContainer {}

extension Container {
    var demoContainer: Factory<DemoContainer> { self { DemoContainer.shared }}
    var customContainer: Factory<MyCustomContainer> { self { DemoContainer.shared }}
}
