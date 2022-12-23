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
    @Injected(Container.circularB) var circularB
}

class CircularB {
    @Injected(Container.circularC) var circularC
}

class CircularC {
    @Injected(Container.circularA) var circularA
}

extension Container {

    static var circularA = Factory<CircularA> { CircularA() }
    static var circularB = Factory<CircularB> { CircularB() }
    static var circularC = Factory<CircularC> { CircularC() }

    static var optionalA = Factory<CircularA?> { CircularA() }

    func testCircularDependencies() {
        let a = Container.circularA()
        print(a)
    }
}

