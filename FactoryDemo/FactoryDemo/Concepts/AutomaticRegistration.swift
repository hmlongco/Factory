//
//  AutomaticRegistration.swift
//  FactoryDemo
//
//  Created by Michael Long on 11/26/22.
//

import Foundation
import Factory

extension Container: AutoRegistering {

    var autoRegisteredService: Factory<MyServiceType?> {
        makes { nil }
    }

    public func autoRegister() {

        print("AUTOREGISTRATION!!!")

        autoRegisteredService.register {
            MyService()
        }

        #if DEBUG
        if ProcessInfo().arguments.contains("-mock1") {
            myServiceType.register { MockServiceN(1) }
        }
        #endif
    }

}
