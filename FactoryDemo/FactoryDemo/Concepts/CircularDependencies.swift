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

    var circularA: Factory<CircularA> { makes { CircularA() } }
    var circularB: Factory<CircularB> { makes { CircularB() } }
    var circularC: Factory<CircularC> { makes { CircularC() } }

    var optionalA: Factory<CircularA?> { makes { CircularA() } }

    static func testCircularDependencies() {
        let a = Container.shared.circularA()
        print(a)
    }
}

