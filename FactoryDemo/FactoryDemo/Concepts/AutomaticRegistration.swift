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

        autoRegisteredService.register { MyService() }

        // Letting external module initialize
        networkSetup()

        // Providing type external to module
        promisedType.register { self.scopedCommonType() }

        #if DEBUG
        if ProcessInfo().arguments.contains("-mock1") {
            myServiceType.register { MockServiceN(1) }
        }
        // manager.trace.toggle()
        #endif
    }

    private var scopedCommonType: Factory<CommonType> {
        self { PromisedCommonType() }.singleton
    }

}


private class PromisedCommonType: CommonType {
    public init() {}
    public func test() {
        print("PromisedCommonType Test")
    }
}
