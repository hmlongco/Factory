//
//  FactoryDemoTestsServices.swift
//  FactoryDemoTests
//
//  Created by Michael Long on 4/6/23.
//

import Foundation
import Factory

@testable import FactoryDemo

struct ContextService {
    var name: String
}

extension Container {
    var contextService: Factory<ContextService> {
        self { ContextService(name: "ORIGINAL") }
    }
}
