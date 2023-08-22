//
//  Key.swift
//  
//
//  Created by Michael Long on 8/17/23.
//

import Foundation

public struct FactoryKey: Hashable {

    public let type: Int
    public let key: Int

    internal init(type: Any.Type, key: StaticString = #function) {
        self.type = Int(bitPattern: ObjectIdentifier(type))
        self.key = key.hasPointerRepresentation ? Int(bitPattern: key.utf8Start) : Int(key.unicodeScalar.value)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(key)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.type == rhs.type && lhs.key == rhs.key
    }

}

//public struct FactoryKey: Hashable {
//
//#if DEBUG
//    let type: String
//#endif
//
//    let key: String
//
//    internal init(type: Any.Type, key: StaticString = #function) {
//#if DEBUG
//        self.type = String(reflecting: type)
//        self.key = "\(key)<\(self.type)>"
//#else
//        self.key = "\(key)<\(String(reflecting: type))>"
//#endif
//    }
//
//    public func hash(into hasher: inout Hasher) {
//        hasher.combine(key)
//    }
//
//    public static func == (lhs: Self, rhs: Self) -> Bool {
//        lhs.key == rhs.key
//    }
//
//}
