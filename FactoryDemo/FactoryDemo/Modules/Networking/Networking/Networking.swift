//
//  _Injections.swift
//  Common
//
//  Created by Michael Long on 6/25/22.
//

import Foundation
import Common
import Factory

public protocol NetworkType {
    func test()
}

extension Container {
    public static var networkType = Factory<NetworkType> { Network() }
}

public class Network: NetworkType {
    @Injected(Container.commonType) private var commonType
    public init() {}
    public func test() {
        commonType.test()
        print("Network Test")
    }
}
