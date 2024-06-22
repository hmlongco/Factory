//
//  FactoryDemoApp+Injection.swift
//  FactoryDemo
//
//  Created by Michael Long on 6/2/22.
//

import Foundation
import Factory

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

final class AAViewModel {
    var name: String {
        AAContainer.shared.service().name
    }

}
