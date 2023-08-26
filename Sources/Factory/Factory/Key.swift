//
//  Key.swift
//  
//
//  Created by Michael Long on 8/17/23.
//

import Foundation

// FactoryKey6
public struct FactoryKey: Hashable {

    public let type: ObjectIdentifier
    public let key: StaticString

    public init(type: Any.Type, key: StaticString = #function) {
        self.type = ObjectIdentifier(type)
        self.key = key
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.type)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.type == rhs.type else {
            return false
        }
        if lhs.key.hasPointerRepresentation && rhs.key.hasPointerRepresentation {
            return lhs.key.utf8Start == rhs.key.utf8Start || strcmp(lhs.key.utf8Start, rhs.key.utf8Start) == 0
        } else if lhs.key.hasPointerRepresentation == false && rhs.key.hasPointerRepresentation == false {
            return lhs.key.unicodeScalar.value == rhs.key.unicodeScalar.value
        } else {
            return false
        }
    }

}
