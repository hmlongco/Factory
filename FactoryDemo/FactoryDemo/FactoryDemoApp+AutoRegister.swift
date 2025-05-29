//
//  FactoryDemoApp+AutoRegister.swift
//  FactoryDemo
//
//  Created by Michael Long on 11/26/22.
//

import Foundation
import FactoryMacros
import Common
import Networking

extension Container: @retroactive AutoRegistering {

    var autoRegisteredService: Factory<MyServiceType?> {
        self { nil }
    }

    public func autoRegister() {

        print("AUTOREGISTRATION!!!")

        // Enable tracing if needed
        // manager.trace.toggle()

        // Demonstrate registering optional type at runtime
        autoRegisteredService.register { MyService() }

        // Demonstrate providing type external to module
        promisedType.register { PromisedCommonType() }

        // Demonstrate letting external module initialize
        networkSetup()

        // Registering a CommonType from a class in Networking
        fatalType.register { FatalCommonType() }

        // Demonstrate registration overrides for uitest application passed arguments
        myServiceType.onArg("mock1") {
            MockServiceN(1)
        }
        myServiceType.onArg("mock2") {
            MockServiceN(2)
        }

        // Demonstrates resolving a type
        register { SimpleService() }

        #if DEBUG
        // Demonstrate preview registration override
//        myServiceType.onPreview {
//            MockServiceN(66)
//        }
        // Demonstrate debug registration override
//        myServiceType.onDebug {
//            MockServiceN(77)
//        }
        #endif
    }

}

extension Container: @retroactive Resolving {}

private class PromisedCommonType: CommonType {
    public init() {}
    public func test() {
        print("PromisedCommonType Test")
    }
}
