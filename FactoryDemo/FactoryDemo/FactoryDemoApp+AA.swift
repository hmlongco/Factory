//
//  FactoryDemoApp+Injection.swift
//  FactoryDemo
//
//  Created by Michael Long on 6/2/22.
//

import Foundation
import FactoryMacros

protocol AAService {
    var name: String { get }
}

final class AADefaultService: AAService {
    let name = "DefaultService"
}

final class AAMockService: AAService {
    let name = "MockService"
}

final class AAContainer: SharedContainer {
    static let shared = AAContainer()
    let manager = ContainerManager()

    var service: Factory<AAService> {
        self { AADefaultService() }
            .cached
    }
}

extension AAContainer: AutoRegistering {
    func autoRegister() {
        //
    }
}

final class AAViewModel {
    @Injected(\AAContainer.service) var service
    var name: String {
        service.name
    }
}
