//
//  CircularDependencies.swift
//  FactoryDemo
//
//  Created by Michael Long on 12/23/22.
//

import Foundation
import FactoryKit

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

    var circularA: Factory<CircularA> { self { CircularA() } }
    var circularB: Factory<CircularB> { self { CircularB() } }
    var circularC: Factory<CircularC> { self { CircularC() } }

    var optionalA: Factory<CircularA?> { self { CircularA() } }

    static func testCircularDependencies() {
        Container.shared.manager.trace.toggle()
        let a = Container.shared.circularA()
        print(a)
    }
}

