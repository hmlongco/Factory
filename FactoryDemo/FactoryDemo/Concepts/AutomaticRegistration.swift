//
//  AutomaticRegistration.swift
//  FactoryDemo
//
//  Created by Michael Long on 11/26/22.
//

import Foundation
import Factory
import Common

extension Container: AutoRegistering {

    var autoRegisteredService: Factory<MyServiceType?> {
        self { nil }
    }

    public func autoRegister() {

        print("AUTOREGISTRATION!!!")

        // Enable tracing if needed
        // manager.trace.toggle()

        // Demonstrate registring optional type at runtime
        autoRegisteredService.register { MyService() }

        // Demonstrate providing type external to module
        promisedType.register { PromisedCommonType() }

        // Demonstrate letting external module initialize
        networkSetup()

        #if DEBUG
        // Demonstrate custom registration overrides for UI tests
        if ProcessInfo().arguments.contains("-mock1") {
            myServiceType.register { MockServiceN(1) }
        }
        #endif

    }

}


private class PromisedCommonType: CommonType {
    public init() {}
    public func test() {
        print("PromisedCommonType Test")
    }
}
