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

    var circularA: Factory<CircularA> { factory { CircularA() } }
    var circularB: Factory<CircularB> { factory { CircularB() } }
    var circularC: Factory<CircularC> { factory { CircularC() } }

    var optionalA: Factory<CircularA?> { factory { CircularA() } }

    static func testCircularDependencies() {
        let a = Container.shared.circularA()
        print(a)
    }
}

