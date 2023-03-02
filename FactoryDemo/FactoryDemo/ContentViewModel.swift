//
//  ContentViewModel.swift
//  FactoryDemo
//
//  Created by Michael Long on 6/2/22.
//

import Foundation
import Factory
import Common
import Networking

class ContentViewModel: ObservableObject {

    @Injected(\.myServiceType) private var service
    @Injected(\.networkType) private var network

    private let simpleService = Container.shared.simpleService()

    @Published var name: String = "Michael"

    init() {
        print("ContentViewModel Initialized")
        testFactory()
    }

    func text() -> String {
        return service.text()
    }

    func testFactory() {
        $network.resolve(reset: .all)
        
        let m1 = CycleDemo()
        print("CycleDemo - W/O ROOT \(m1.aService === m1.bService)")
        let m2 = Container.shared.cycleDemo()
        print("CycleDemo - W/ROOT \(m2.aService === m2.bService)")

        let p1 = Container.shared.promisedType()
        p1?.test()
    }

}

internal class MyCommonType: CommonType {
    public init() {}
    public func test() {
        print("My Common Test")
    }
}
