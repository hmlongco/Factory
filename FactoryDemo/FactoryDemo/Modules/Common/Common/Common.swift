//
//  _Injections.swift
//  Common
//
//  Created by Michael Long on 6/25/22.
//

import Foundation
import Factory

public protocol CommonType {
    func test()
}

extension Container {
    public var commonType: Factory<CommonType> { makes { Common() } }
}

extension Container {
    public var promisedType: Factory<CommonType?> { makes { nil } }
}

//extension Container {
//    public static var unsafeType = Factory(unsafe: CommonType.self)
//}

private class Common: CommonType {
    public init() {}
    public func test() {
        print("Common Test")
    }
}
