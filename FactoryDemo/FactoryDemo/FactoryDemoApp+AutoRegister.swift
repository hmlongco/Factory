//
//  FactoryDemoApp+AutoRegister.swift
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

        // Demonstrate registration overrides for uitest application passed arguments
        myServiceType.arg("mock1") {
            MockServiceN(1)
        }
        myServiceType.arg("mock2") {
            MockServiceN(2)
        }

        #if DEBUG
        // Demonstrate preview registration override
        myServiceType.preview {
            MockServiceN(66)
        }
        // Demonstrate debug registration override
        myServiceType.debug {
            MockServiceN(77)
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
