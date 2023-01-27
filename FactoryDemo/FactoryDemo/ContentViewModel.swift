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

    @Injected(\.myServiceType) private var service

    @Published var name: String = "Michael"

    init() {
        print("ContentModuleViewModel Initialized")
        testFactory()
    }

    func text() -> String {
        return service.text()
    }

    func testFactory() {
        // test 1
        print("\nMODULES: Testing registration on factory, type == MyCommonType")
        Container.shared.commonType.register {
            MyCommonType()
        }
        let network1 = Container.shared.networkType() // uses CommonType iternally
        network1.test()

        // test 2 - should reset and log Common
        print("\nMODULES: Testing reset to see original type, type == Common")
        Container.shared.manager.reset()
        let network2 = Container.shared.networkType() // uses CommonType iternally
        network2.test()

        // test 3
        print("\nMODULES: Testing registration on shared container, type == MyCommonType")
        Container.shared.commonType.register {
            MyCommonType() as CommonType
        }
        let network3 = Container.shared.networkType() // uses CommonType iternally
        network3.test()

        // test 4
        print("\nMODULES: Testing cross-module registration change on Container, type == CommonNetworkType")
        Container.shared.networkSetup()
        let network4 = Container.shared.networkType()
        network4.test()

        // test 5
        print("\nMODULES: Testing registration on optional promised factory, type == MyCommonType")
        Container.shared.promisedType.register {
            MyCommonType()
        }
        let network5 = Container.shared.promisedType()
        network5?.test()

        // test 6
        //        print("\nMODULES: Testing registration on unsafe factory, type == MyCommonType")
        //        Container.shared.unsafeType.register {
        //            MyCommonType()
        //        }
        //        let network6 = Container.shared.unsafeType()
        //        network6.test()
    }

}

internal class MyCommonType: CommonType {
    public init() {}
    public func test() {
        print("My Common Test")
    }
}

class ContentViewModel1: ObservableObject {
    @Injected(\.myServiceType) private var service
    func text() -> String {
        service.text()
    }
}

class ContentViewModel2: ObservableObject {
    @LazyInjected(\.myServiceType) private var service
    func text() -> String {
        service.text()
    }
}

class ContentViewModel3: ObservableObject {
    private let service = Container.shared.myServiceType()
    func text() -> String {
        service.text()
    }
}

class ContentViewModel4: ObservableObject {
    private lazy var service = OrderContainer.shared.constructedService()
    func text() -> String {
        service.text()
    }
}

class ContentViewModel6: ObservableObject {
    private let service = OrderContainer.shared.argumentService(8)
    func text() -> String {
        service.text()
    }
}

class ContentViewModel7: ObservableObject {
    private let service = Container.shared.simpleService()
    func text() -> String {
        service.text()
    }
}

class ContentViewModel8: ObservableObject {
    private let service: MyServiceType? = Container.shared.sharedService()
    func text() -> String {
        service?.text() ?? "Released"
    }
}

class ContentViewModel9: ObservableObject {
    private let service = OrderContainer.shared.optionalService()
    func text() -> String {
        service?.text() ?? "HELP!"
    }
}
