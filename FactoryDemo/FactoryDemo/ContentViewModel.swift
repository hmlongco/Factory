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
    @Injected(\.networkType) private var network

    private let simpleService = Container.shared.simpleService()

    @Published var name: String = "Michael"

    init() {
        print("ContentModuleViewModel Initialized")
        testFactory()

    }

    func text() -> String {
        return service.text()
    }

    func testFactory() {
        $network.resolve(reset: .all)
        
        let m1 = MultipleDemo()
        print("MultipleDemo - W/O ROOT \(m1.aService.id == m1.bService.id)")
        let m2 = Container.shared.multiple()
        print("MultipleDemo - W/ROOT \(m2.aService.id == m2.bService.id)")
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
    private lazy var service = DemoContainer.shared.constructedService()
    func text() -> String {
        service.text()
    }
}

class ContentViewModel6: ObservableObject {
    private let service = DemoContainer.shared.argumentService(8)
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
    private let service = DemoContainer.shared.optionalService()
    func text() -> String {
        service?.text() ?? "HELP!"
    }
}
