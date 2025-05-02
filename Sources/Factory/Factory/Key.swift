//
//  Key.swift
//  
//
//  Created by Michael Long on 8/17/23.
//

import Foundation
import os

internal struct FactoryKey: Hashable {

    let type: ObjectIdentifier
    let key: StaticString

    internal init(type: Any.Type, key: StaticString) {
        self.type = globalIdentifier(for: type)
        self.key = key
    }

    internal func hash(into hasher: inout Hasher) {
        hasher.combine(self.type)
        if key.hasPointerRepresentation {
            hasher.combine(bytes: UnsafeRawBufferPointer(start: key.utf8Start, count: key.utf8CodeUnitCount))
        } else {
            hasher.combine(key.unicodeScalar.value)
        }
    }

    internal static func == (lhs: Self, rhs: Self) -> Bool {
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

// Quickly returns a unique type identifier for a given type name ("MyApp.MyType")
//
// This code denormalizes the same name to the same ObjectIdentifier, basically translating every matching name seen to the first object
// identifier seen for a given name.
//
// The previous solution used an id based solely on ObjectIdentifier(type), which could have a different type id for the same type name across
// separately compiled modules.
private func globalIdentifier(for type: Any.Type) -> ObjectIdentifier {
    defer { globalTypeTableLock.unlock() }
    globalTypeTableLock.lock()
    let requestedTypeID = ObjectIdentifier(type)
    if let knownID = globalKnownTypeTable[requestedTypeID] {
        return knownID
    }
    let id = globalTypeTranslationTable[String(reflecting: type), default: requestedTypeID]
    globalKnownTypeTable[requestedTypeID] = id
    return id
}

// quickly denormalizes the requested type identifier to a known type identifier
nonisolated(unsafe) private var globalKnownTypeTable: [ObjectIdentifier : ObjectIdentifier] = [:]
// translates a type string name to a ObjectIdentifier
nonisolated(unsafe) private var globalTypeTranslationTable: [String : ObjectIdentifier] = [:]
// lock for all of the above
nonisolated(unsafe) private let globalTypeTableLock = SpinLock()
