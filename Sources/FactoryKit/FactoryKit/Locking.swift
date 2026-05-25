//
// Locking.swift
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

#if SynchronizationLock
import Synchronization
#elseif AllocatedLock
import os
#endif

// MARK: - Locking

/// Master recursive lock
nonisolated(unsafe) internal var globalRecursiveLock = RecursiveLock()

/// Custom recursive lock
internal final class RecursiveLock: NSLocking {

    init() {
        let mutexAttr = UnsafeMutablePointer<pthread_mutexattr_t>.allocate(capacity: 1)
        pthread_mutexattr_init(mutexAttr)
        pthread_mutexattr_settype(mutexAttr, Int32(PTHREAD_MUTEX_RECURSIVE))
        mutex = UnsafeMutablePointer<pthread_mutex_t>.allocate(capacity: 1)
        pthread_mutex_init(mutex, mutexAttr)
        pthread_mutexattr_destroy(mutexAttr)
        mutexAttr.deallocate()
    }

    deinit {
        pthread_mutex_destroy(mutex)
        mutex.deallocate()
    }

    @inlinable @inline(__always) func lock() {
        pthread_mutex_lock(mutex)
    }

    @inlinable @inline(__always) func unlock() {
        pthread_mutex_unlock(mutex)
    }

    @inlinable @inline(__always) func withLock<R>(_ body: () throws -> R) rethrows -> R {
        pthread_mutex_lock(mutex)
        defer { pthread_mutex_unlock(mutex) }
        return try body()
    }

    private let mutex: UnsafeMutablePointer<pthread_mutex_t>

}

/// Sleeping mutex for long-lived critical sections such as factory creation.
#if SynchronizationLock

internal final class MutexLock: @unchecked Sendable {

    private let mutex = Mutex(())

    @inlinable @inline(__always) func withLock<R>(_ body: () throws -> R) rethrows -> R {
        try mutex.withLock { _ in try body() }
    }

}

#elseif AllocatedLock

internal final class MutexLock: @unchecked Sendable {

    private let unfairLock = OSAllocatedUnfairLock()

    @inlinable @inline(__always) func withLock<R>(_ body: () throws -> R) rethrows -> R {
        unfairLock.lock()
        defer { unfairLock.unlock() }
        return try body()
    }

}

#else

internal final class MutexLock {

    init() {
        mutex = UnsafeMutablePointer<pthread_mutex_t>.allocate(capacity: 1)
        let attributes = UnsafeMutablePointer<pthread_mutexattr_t>.allocate(capacity: 1)
        pthread_mutexattr_init(attributes)
        pthread_mutexattr_settype(attributes, Int32(PTHREAD_MUTEX_NORMAL))
        pthread_mutex_init(mutex, attributes)
        pthread_mutexattr_destroy(attributes)
        attributes.deallocate()
    }

    deinit {
        pthread_mutex_destroy(mutex)
        mutex.deallocate()
    }

    @inlinable @inline(__always) func withLock<R>(_ body: () throws -> R) rethrows -> R {
        pthread_mutex_lock(mutex)
        defer { pthread_mutex_unlock(mutex) }
        return try body()
    }

    private let mutex: UnsafeMutablePointer<pthread_mutex_t>

}

#endif

/// Master variable spin lock
internal let globalVariableLock = CrossPlatformLock()

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)

#if SynchronizationLock

/// Lock using Swift 6 Mutex. Zero-cost inline lock, no separate heap allocation.
/// Requires iOS 18+ / macOS 15+ — enabled via the "SynchronizationLock" package trait.
internal final class CrossPlatformLock: @unchecked Sendable {

    private let mutex = Mutex(())

    @inlinable @inline(__always) func withLock<R>(_ body: () throws -> R) rethrows -> R {
        try mutex.withLock { _ in try body() }
    }

}

#elseif AllocatedLock

/// Lock using OSAllocatedUnfairLock. Single allocation, no UnsafeMutablePointer.
/// Requires iOS 16+ / macOS 13+ — enabled via the "AllocatedLock" package trait.
@available(iOS 16.0, *)
internal final class CrossPlatformLock: NSLocking, @unchecked Sendable {

    private let unfairLock = OSAllocatedUnfairLock()

    @inlinable @inline(__always) func lock() { unfairLock.lock() }
    @inlinable @inline(__always) func unlock() { unfairLock.unlock() }

    /// Inlinable withLock avoids Foundation's non-inlinable NSLocking.withLock
    @inlinable @inline(__always) func withLock<R>(_ body: () throws -> R) rethrows -> R {
        unfairLock.lock()
        defer { unfairLock.unlock() }
        return try body()
    }

}

#else

/// Custom lock using os_unfair_lock on Apple platforms.
internal final class CrossPlatformLock: NSLocking, @unchecked Sendable {

    init() {
        oslock = UnsafeMutablePointer<os_unfair_lock>.allocate(capacity: 1)
        oslock.initialize(to: .init())
    }

    deinit {
        oslock.deinitialize(count: 1)
        oslock.deallocate()
    }

    @inlinable @inline(__always) func lock() {
        os_unfair_lock_lock(oslock)
    }

    @inlinable @inline(__always) func unlock() {
        os_unfair_lock_unlock(oslock)
    }

    /// Inlinable withLock avoids Foundation's non-inlinable NSLocking.withLock
    @inlinable @inline(__always) func withLock<R>(_ body: () throws -> R) rethrows -> R {
        os_unfair_lock_lock(oslock)
        defer { os_unfair_lock_unlock(oslock) }
        return try body()
    }

    private let oslock: UnsafeMutablePointer<os_unfair_lock>

}

#endif

#else
/// Custom lock compatible with Linux using pthread_mutex.
internal final class CrossPlatformLock: NSLocking, @unchecked Sendable {

    init() {
        mutex = UnsafeMutablePointer<pthread_mutex_t>.allocate(capacity: 1)
        let attributes = UnsafeMutablePointer<pthread_mutexattr_t>.allocate(capacity: 1)
        pthread_mutexattr_init(attributes)
        pthread_mutexattr_settype(attributes, Int32(PTHREAD_MUTEX_NORMAL))
        pthread_mutex_init(mutex, attributes)
        pthread_mutexattr_destroy(attributes)
        attributes.deallocate()
    }

    deinit {
        pthread_mutex_destroy(mutex)
        mutex.deallocate()
    }

    @inlinable @inline(__always) func lock() {
        pthread_mutex_lock(mutex)
    }

    @inlinable @inline(__always) func unlock() {
        pthread_mutex_unlock(mutex)
    }

    /// Inlinable withLock for Linux
    @inlinable @inline(__always) func withLock<R>(_ body: () throws -> R) rethrows -> R {
        pthread_mutex_lock(mutex)
        defer { pthread_mutex_unlock(mutex) }
        return try body()
    }

    private let mutex: UnsafeMutablePointer<pthread_mutex_t>
}
#endif
