//
// Key.swift
//
// GitHub Repo and Documentation: https://github.com/hmlongco/Factory
//
// Copyright © 2022-2025 Michael Long. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
import Foundation

internal struct FactoryKey: Hashable {

    let type: ObjectIdentifier
    let key: StaticString

    var parameter: Int

    internal init(type: Any.Type, key: StaticString) {
        self.type = globalIdentifier(for: type)
        self.key = key
        self.parameter = 0
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
        hasher.combine(self.parameter)
    }

    internal static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.type == rhs.type
                && lhs.key.hasPointerRepresentation == rhs.key.hasPointerRepresentation
                && lhs.parameter == rhs.parameter
        else {
            return false
        }
        if lhs.key.hasPointerRepresentation {
            return lhs.key.utf8Start == rhs.key.utf8Start || strcmp(lhs.key.utf8Start, rhs.key.utf8Start) == 0
        } else {
            return lhs.key.unicodeScalar.value == rhs.key.unicodeScalar.value
        }
    }

    internal func parameterized(_ value: Any) -> Self {
        guard let hashable = value as? any Hashable else {
            return self
        }
        var copy = self
        copy.parameter = hashable.hashValue
        return copy
    }

    internal func normalized() -> Self {
        var copy = self
        copy.parameter = 0
        return copy
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
    globalVariableLock.withLock {
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
}

// quickly denormalizes the requested type identifier to a known type identifier
nonisolated(unsafe) private var globalKnownIdentifierTable: [ObjectIdentifier : ObjectIdentifier] = [:]

// translates a type string name to a ObjectIdentifier
nonisolated(unsafe) private var globalNameToIdentifierTable: [String : ObjectIdentifier] = [:]

// reverse map, gets back string representation from id
nonisolated(unsafe) private var globalIdentifierToNameTable: [ObjectIdentifier : String] = [:]
