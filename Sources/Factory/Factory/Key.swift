//
//  Key.swift
//  
//
//  Created by Michael Long on 8/17/23.
//

import Foundation

public struct FactoryKey: Hashable {

    @usableFromInline let type: ObjectIdentifier
    @usableFromInline let key: StaticString

    @inline(__always) init(type: Any.Type, key: StaticString = #function) {
        self.type = ObjectIdentifier(type)
        self.key = key
    }

    @inline(__always) public func hash(into hasher: inout Hasher) {
        hasher.combine(self.type)
    }

    @inlinable public static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.type == rhs.type && lhs.key.hasPointerRepresentation == rhs.key.hasPointerRepresentation else {
            return false
        }
        if lhs.key.hasPointerRepresentation {
            return lhs.key.utf8Start == rhs.key.utf8Start || strcmp(lhs.key.utf8Start, rhs.key.utf8Start) == 0
        } else {
            return lhs.key.unicodeScalar.value == rhs.key.unicodeScalar.value
        }
    }

}
