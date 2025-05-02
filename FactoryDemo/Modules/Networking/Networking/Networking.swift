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
        networkType.register {
            CommonNetworkType()
        }
        fatalType.register {
            FatalCommonType()
        }
    }
}

private class CommonNetworkType: NetworkType {
    @Injected(\.fatalType) private var fatalType
    public init() {}
    public func test() {
        print("Common Network Test")
        fatalType.test()
    }
}

private class FatalCommonType: CommonType {
    public init() {}
    public func test() {
        print("FatalCommonType Test")
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
