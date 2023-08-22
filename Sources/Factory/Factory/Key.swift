//
//  Key.swift
//  
//
//  Created by Michael Long on 8/17/23.
//

import Foundation

public struct FactoryKey: Hashable {

    public let type: Int
    public let key: StaticString
    public let hash: Int

    public init(type: Any.Type, key: StaticString) {
        // save type address and key
        self.type = Int(bitPattern: ObjectIdentifier(type))
        self.key = key
        // build and remember hash value
        var hasher = Hasher()
        hasher.combine(self.type)
        if key.hasPointerRepresentation {
            hasher.combine(bytes: UnsafeRawBufferPointer(start: key.utf8Start, count: key.utf8CodeUnitCount))
        } else {
            hasher.combine(key.unicodeScalar.value)
        }
        self.hash = hasher.finalize()
    }

    /// Fast hash based on stored value
    public func hash(into hasher: inout Hasher) {
        hasher.combine(hash)
    }

    /// Fast equate based on stored hash and key
    public static func == (lhs: Self, rhs: Self) -> Bool {
        // if hashes or types don't match unequal
        guard lhs.hash == rhs.hash && lhs.type == rhs.type else {
            return false
        }
        // check key string
        if lhs.key.hasPointerRepresentation && rhs.key.hasPointerRepresentation {
            // safe to compare key addresses, if they match equal
            if lhs.key.utf8Start == rhs.key.utf8Start {
                return true
            }
            // we're confused, punt and compare
            return strcmp(lhs.key.utf8Start, rhs.key.utf8Start) == 0
        } else if lhs.key.hasPointerRepresentation == false && rhs.key.hasPointerRepresentation == false {
            return lhs.key.unicodeScalar.value == rhs.key.unicodeScalar.value
        }
        // if one's a scalar and one's a pointer unequal
        return false
    }

}
