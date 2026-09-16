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
    let parameter: AnyHashable?
    /// Identifies the originating container cache when a scope shares storage across containers.
    let cacheID: ObjectIdentifier?

    internal init(type: Any.Type, key: StaticString) {
        self.type = ObjectIdentifier(type) // globalIdentifier(for: type)
        self.key = key
        self.parameter = nil
        self.cacheID = nil
    }

    @inline(__always)
    private init(type: ObjectIdentifier, key: StaticString, parameter: AnyHashable?, cacheID: ObjectIdentifier? = nil) {
        self.type = type
        self.key = key
        self.parameter = parameter
        self.cacheID = cacheID
    }

    internal func hash(into hasher: inout Hasher) {
        hasher.combine(self.type)
        hasher.combine(self.key)
        hasher.combine(self.parameter)
        hasher.combine(self.cacheID)
    }

    internal static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.key == rhs.key && lhs.type == rhs.type && lhs.parameter == rhs.parameter && lhs.cacheID == rhs.cacheID
    }

    internal func parameterized(_ value: Any) -> Self {
        guard let hashable = value as? any Hashable else {
            return self
        }
        // Preserve equality so distinct parameters with the same hash do not share a cached value.
        return .init(type: type, key: key, parameter: AnyHashable(hashable), cacheID: cacheID)
    }

    internal func normalized() -> Self {
        return .init(type: type, key: key, parameter: nil, cacheID: cacheID)
    }

    internal func scoped(to cache: Scope.Cache) -> Self {
        .init(type: type, key: key, parameter: parameter, cacheID: ObjectIdentifier(cache))
    }

}

extension StaticString: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        if self.hasPointerRepresentation {
            hasher.combine(bytes: UnsafeRawBufferPointer(start: self.utf8Start, count: self.utf8CodeUnitCount))
        } else {
            hasher.combine(self.unicodeScalar)
        }
    }

    public static func == (lhs: StaticString, rhs: StaticString) -> Bool {
        guard lhs.hasPointerRepresentation == rhs.hasPointerRepresentation else {
            return false
        }
        if lhs.hasPointerRepresentation {
            return strcmp(lhs.utf8Start, rhs.utf8Start) == 0
        } else {
            return lhs.unicodeScalar == rhs.unicodeScalar
        }
    }
}

struct RecursiveKey: Hashable, Equatable {
    let container: ObjectIdentifier
    let key: FactoryKey
    init(container: ManagedContainer, key: FactoryKey) {
        self.container = ObjectIdentifier(container)
        self.key = key
    }
}
