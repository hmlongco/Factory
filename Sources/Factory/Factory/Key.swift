//
//  Key.swift
//  
//
//  Created by Michael Long on 8/17/23.
//

import Foundation

public struct FactoryKey: Hashable {

    public let type: ObjectIdentifier
    public let key: StaticString

    public init(type: Any.Type, key: StaticString = #function) {
        self.type = ObjectIdentifier(type)
        self.key = key
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        if key.hasPointerRepresentation {
            hasher.combine(bytes: UnsafeRawBufferPointer(start: key.utf8Start, count: key.utf8CodeUnitCount))
        } else {
            hasher.combine(key.unicodeScalar.value)
        }
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        // types don't match unequal
        guard lhs.type == rhs.type else {
            return false
        }
        // check key string
        if lhs.key.hasPointerRepresentation && rhs.key.hasPointerRepresentation {
            // safe to compare key addresses, if they match equal
            if lhs.key.utf8Start == rhs.key.utf8Start {
                return true
            }
            // not the same string, but same value?
            return strcmp(lhs.key.utf8Start, rhs.key.utf8Start) == 0
        } else if lhs.key.hasPointerRepresentation == false && rhs.key.hasPointerRepresentation == false {
            // should never, ever be scalar values but just to be complete...
            return lhs.key.unicodeScalar.value == rhs.key.unicodeScalar.value
        }
        // in this context if one's a scalar and one's a pointer unequal
        return false
    }

}
