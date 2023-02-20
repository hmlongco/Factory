//
//  CircularDependencies.swift
//  FactoryDemo
//
//  Created by Michael Long on 12/23/22.
//

import Foundation
import Factory

// Circular

class CircularA {
    @Injected(\.circularB) var circularB
}

class CircularB {
    @Injected(\.circularC) var circularC
}

class CircularC {
    @Injected(\.circularA) var circularA
}

extension Container {

    var circularA: Factory<CircularA> { unique { CircularA() } }
    var circularB: Factory<CircularB> { unique { CircularB() } }
    var circularC: Factory<CircularC> { unique { CircularC() } }

    var optionalA: Factory<CircularA?> { unique { CircularA() } }

    static func testCircularDependencies() {
        let a = Container.shared.circularA()
        print(a)
    }
}

