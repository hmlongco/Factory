//
// Globals.swift
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

// MARK: - Cross-Platform Timestamp

@inline(__always)
internal func currentTimestamp() -> Double {
    var ts = timespec()
    clock_gettime(CLOCK_MONOTONIC, &ts)
    return Double(ts.tv_sec) + Double(ts.tv_nsec) / 1_000_000_000
}

// MARK: - Cross-Platform pthread Key

internal func makePthreadKey(destructor: @convention(c) (UnsafeMutableRawPointer) -> Void) -> pthread_key_t {
    var key: pthread_key_t = 0
    #if canImport(Darwin)
    pthread_key_create(&key, destructor)
    #else
    pthread_key_create(&key) { raw in
        guard let raw else { return }
        destructor(raw)
    }
    #endif
    return key
}

// MARK: - Internal Variables

/// Internal key used for Resolver mode
internal let globalResolverKey: StaticString = "*"

#if DEBUG
/// Internal variables used for debugging
nonisolated(unsafe) internal var globalCircularDependencyTesting = true
nonisolated(unsafe) internal var globalLogger: (String) -> Void = { print($0) }
nonisolated(unsafe) internal var globalTraceFlag: Bool = false

// MARK: - Thread-Local Debug State

/// Per-thread circular dependency tracking and trace resolutions.
/// These must be thread-local because factory closures now execute outside the global lock,
/// meaning multiple threads can be mid-resolution simultaneously.
/// Both values share a single TLS key to minimize pthread_getspecific calls.
internal enum ThreadLocalDebugState {
    /// Combined storage for all per-thread debug state.
    private final class Storage {
        var circularDependencyKeys: Set<FactoryKey> = []
        var traceResolutions: [String] = []
    }

    private static let storageKey: pthread_key_t = makePthreadKey { raw in
        Unmanaged<Storage>.fromOpaque(raw).release()
    }

    @inline(__always)
    private static func getStorage() -> Storage? {
        guard let raw = pthread_getspecific(storageKey) else { return nil }
        return Unmanaged<Storage>.fromOpaque(raw).takeUnretainedValue()
    }

    @inline(__always)
    private static func getOrCreateStorage() -> Storage {
        if let storage = getStorage() { return storage }
        let storage = Storage()
        pthread_setspecific(storageKey, Unmanaged.passRetained(storage).toOpaque())
        return storage
    }

    internal static var circularDependencyKeys: Set<FactoryKey> {
        get { getStorage()?.circularDependencyKeys ?? [] }
        set { getOrCreateStorage().circularDependencyKeys = newValue }
    }

    internal static var traceResolutions: [String] {
        get { getStorage()?.traceResolutions ?? [] }
        set { getOrCreateStorage().traceResolutions = newValue }
    }

    internal static func reset() {
        guard let storage = getStorage() else { return }
        storage.circularDependencyKeys = []
        storage.traceResolutions = []
    }
}

/// Convenience accessors maintaining the old global naming convention
internal var globalCircularDependencyKeys: Set<FactoryKey> {
    get { ThreadLocalDebugState.circularDependencyKeys }
    set { ThreadLocalDebugState.circularDependencyKeys = newValue }
}

internal var globalTraceResolutions: [String] {
    get { ThreadLocalDebugState.traceResolutions }
    set { ThreadLocalDebugState.traceResolutions = newValue }
}

/// Triggers fatalError after resetting enough stuff so unit tests can continue
internal func resetAndTriggerFatalError(_ message: String, _ file: StaticString, _ line: UInt) -> Never {
    ThreadLocalDebugState.reset()
    globalRecursiveLock = RecursiveLock()
    Scope.graph.reset()
    triggerFatalError(message, file, line) // GOES BOOM
}

/// Allow unit test interception of any fatal errors that may occur running the circular dependency check
/// Variation of solution: https://stackoverflow.com/questions/32873212/unit-test-fatalerror-in-swift#
nonisolated(unsafe) internal var triggerFatalError = Swift.fatalError
#endif
