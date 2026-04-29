//
//  FactoryDemoApp+AutoRegister.swift
//  FactoryDemo
//
//  Created by Michael Long on 11/26/22.
//

import Foundation
import FactoryKit
import Common
import Networking
import Synchronization

@globalActor
public actor FactoryActor {
    public static let shared: FactoryActor = .init()
}

extension Container: @retroactive AutoRegistering {

    var autoRegisteredService: Factory<MyServiceType?> {
        self { nil }
    }

    @MainActor public func mainActorAutoRegister() {
        autoRegisteredService.register {
            MyService()
        }
        myServiceType.register {
            MockServiceN(0)
        }
        myServiceType.onArg("mock1") {
            MockServiceN(1)
        }
        myServiceType.onArg("mock2") {
            MockServiceN(2)
        }
        myActor.register {
            SomeActor()
        }
    }

    @discardableResult
    func checkMainActorAutoRegistration() -> Bool {
        if Thread.isMainThread {
            MainActor.assumeIsolated {
                mainActorAutoRegister()
            }
            return true
        }
        return false
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

        myActor.register {
            SomeActor()
        }

        checkMainActorAutoRegistration()

        // Demonstrate registration overrides for uitest application passed arguments
//        myServiceType.register {
//            MockServiceN(0)
//        }
//        myServiceType.onArg("mock1") {
//            MockServiceN(1)
//        }
//        myServiceType.onArg("mock2") {
//            MockServiceN(2)
//        }

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

private nonisolated class PromisedCommonType: CommonType {
    public init() {}
    public func test() {
        print("PromisedCommonType Test")
    }
}
