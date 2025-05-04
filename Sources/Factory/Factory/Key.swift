//
//  Key.swift
//  
//
//  Created by Michael Long on 8/17/23.
//

import Foundation

internal struct FactoryKey: Hashable {

    let type: ObjectIdentifier
    let key: StaticString

    internal init(type: Any.Type, key: StaticString) {
        self.type = globalIdentifier(for: type)
        self.key = key
    }

    #if DEBUG
    internal var typeName: String {
        globalVariableLock.withLock {
            globalIdentifierToNameTable[self.type]! // must exist
        }
    }
    #endif

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

// Quickly returns a unique type identifier for a given type name ("MyApp.MyType").
//
// This code normalizes the same name to the same ObjectIdentifier, basically translating every name seen to the first object
// identifier seen for that name.
//
// The previous solution used an id based solely on ObjectIdentifier(type), which could have a different type id for the same type name across
// separately compiled modules.
//
// Obtaining and using the class name string directly on every call results in code that's 2-3x slower.
private func globalIdentifier(for type: Any.Type) -> ObjectIdentifier {
    defer { globalVariableLock.unlock() }
    globalVariableLock.lock()
    let requestedTypeID = ObjectIdentifier(type)
    // if known return it
    if let knownID = globalKnownIdentifierTable[requestedTypeID] {
        return knownID
    }
    // this is what we're bypassing. extremely slow runtime function.
    let name = String(reflecting: type)
    // magic happens here, if name is already known then get original key for it
    let id = globalNameToIdentifierTable[name, default: requestedTypeID]
    // and save it so we don't have to do this again
    globalKnownIdentifierTable[requestedTypeID] = id
    #if DEBUG
    globalIdentifierToNameTable[id] = name
    #endif
    return id
}

// quickly denormalizes the requested type identifier to a known type identifier
nonisolated(unsafe) private var globalKnownIdentifierTable: [ObjectIdentifier : ObjectIdentifier] = [:]

// translates a type string name to a ObjectIdentifier
nonisolated(unsafe) private var globalNameToIdentifierTable: [String : ObjectIdentifier] = [:]

// reverse map, gets back string representation from id
nonisolated(unsafe) private var globalIdentifierToNameTable: [ObjectIdentifier : String] = [:]
