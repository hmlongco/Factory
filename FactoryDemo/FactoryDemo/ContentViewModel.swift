//
//  ContentViewModel.swift
//  FactoryDemo
//
//  Created by Michael Long on 6/2/22.
//

import Foundation
import Factory

class ContentViewModel1: ObservableObject {
    @Injected(Factory.myServiceType) private var service
    func text() -> String {
        service.text()
    }
}

class ContentViewModel2: ObservableObject {
    @LazyInjected(Factory.myServiceType) private var service
    func text() -> String {
        service.text()
    }
}

class ContentViewModel3: ObservableObject {
    private let service = Factory.myServiceType()
    func text() -> String {
        service.text()
    }
}

class ContentViewModel4: ObservableObject {
    private lazy var service = OrderFactory.constructedService()
    func text() -> String {
        service.text()
    }
}

class ContentViewModel6: ObservableObject {
    private let service = OrderFactory.argumentService(count: 8)()
    func text() -> String {
        service.text()
    }
}

class ContentViewModel7: ObservableObject {
    private let service = Factory.simpleService()
    func text() -> String {
        service.text()
    }
}

class ContentViewModel8: ObservableObject {
    var service: MyServiceType? = Factory.sharedService()
    func text() -> String {
        service?.text() ?? "Released"
    }
}

class ContentViewModel9: ObservableObject {
    private var service = OrderFactory.optionalService()
    func text() -> String {
        service?.text() ?? "HELP!"
    }
}
