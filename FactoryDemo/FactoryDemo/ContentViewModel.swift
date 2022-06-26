//
//  ContentViewModel.swift
//  FactoryDemo
//
//  Created by Michael Long on 6/2/22.
//

import Foundation
import Factory
import Common
import Networking

class ContentModuleViewModel: ObservableObject {

    @Injected(Container.myServiceType) private var service

    func text() -> String {
        testFactory()
        return service.text()
    }

    func testFactory() {
        // method 1 - register on Factory
        Container.commonType.register {
            MyCommonType()
        }
        // method 2 - register type on shared container
        Container.shared.register {
            MyCommonType() as CommonType
        }
        // test 1
        let network1 = Container.networkType()
        network1.test()
        // test 2
        Container.Registrations.reset()
        let network2 = Container.networkType()
        network2.test()
    }

}

internal class MyCommonType: CommonType {
    public init() {
        print("MyCommonType")
    }
    public func test() {
        print("My Common Test")
    }
}

class ContentViewModel1: ObservableObject {
    @Injected(Container.myServiceType) private var service
    func text() -> String {
        service.text()
    }
}

class ContentViewModel2: ObservableObject {
    @LazyInjected(Container.myServiceType) private var service
    func text() -> String {
        service.text()
    }
}

class ContentViewModel3: ObservableObject {
    private let service = Container.myServiceType()
    func text() -> String {
        service.text()
    }
}

class ContentViewModel4: ObservableObject {
    private lazy var service = OrderContainer.constructedService()
    func text() -> String {
        service.text()
    }
}

class ContentViewModel6: ObservableObject {
    private let service = OrderContainer.argumentService(count: 8)()
    func text() -> String {
        service.text()
    }
}

class ContentViewModel7: ObservableObject {
    private let service = Container.simpleService()
    func text() -> String {
        service.text()
    }
}

class ContentViewModel8: ObservableObject {
    private let service: MyServiceType? = Container.sharedService()
    func text() -> String {
        service?.text() ?? "Released"
    }
}

class ContentViewModel9: ObservableObject {
    private let service = OrderContainer.optionalService()
    func text() -> String {
        service?.text() ?? "HELP!"
    }
}
