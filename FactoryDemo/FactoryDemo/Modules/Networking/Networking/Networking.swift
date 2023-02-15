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
    public var networkType: Factory<NetworkType> { self { Network() } }
}

extension Container {
    public func networkSetup() {
        Container.shared.networkType.register {
            CommonNetworkType()
        }
    }
}

private class CommonNetworkType: NetworkType {
    public init() {}
    public func test() {
        print("Common Network Test")
    }
}

private class Network: NetworkType {
    @Injected(\.commonType) private var commonType
    public init() {}
    public func test() {
        commonType.test()
        print("Network Test")
    }
}
