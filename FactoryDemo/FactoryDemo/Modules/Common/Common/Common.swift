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
    public static var commonType = Factory<CommonType> { Common() }
}

private class Common: CommonType {
    public init() {
        print("Common")
    }
    public func test() {
        print("Common Test")
    }
}
