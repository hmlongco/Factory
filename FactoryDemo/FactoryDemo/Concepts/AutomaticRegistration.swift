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
        unique { nil }
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
//        decorator {
//            print("FACTORY: \(type(of: $0)) (\(Int(bitPattern: ObjectIdentifier($0 as AnyObject))))")
//        }
        // manager.trace.toggle()
        #endif
    }

}
