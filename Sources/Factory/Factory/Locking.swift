//
// Locking.swift
//  
// GitHub Repo and Documentation: https://github.com/hmlongco/Factory
//
// Copyright © 2022 Michael Long. All rights reserved.
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

    private let mutex: UnsafeMutablePointer<pthread_mutex_t>

}

/// Master spin lock
nonisolated(unsafe) internal let globalDebugLock = SpinLock()

#if os(macOS) || os(iOS) || os(watchOS)
/// Custom spin lock
internal final class SpinLock: NSLocking {

    init() {
        oslock = UnsafeMutablePointer<os_unfair_lock>.allocate(capacity: 1)
        oslock.initialize(to: .init())
    }

    @inlinable @inline(__always) func lock() {
        os_unfair_lock_lock(oslock)
    }

    @inlinable @inline(__always) func unlock() {
        os_unfair_lock_unlock(oslock)
    }

    private let oslock: UnsafeMutablePointer<os_unfair_lock>

}
#else
/// Custom spin lock compatible with Linux
internal final class SpinLock: NSLocking {

    init() {
        mutex = UnsafeMutablePointer<pthread_mutex_t>.allocate(capacity: 1)
        let attributes = UnsafeMutablePointer<pthread_mutexattr_t>.allocate(capacity: 1)
        pthread_mutexattr_init(attributes)
        pthread_mutexattr_settype(attributes, Int32(PTHREAD_MUTEX_NORMAL))
        pthread_mutex_init(mutex, attributes)
        pthread_mutexattr_destroy(attributes)
        attributes.deallocate()
    }

    @inlinable @inline(__always) func lock() {
        pthread_mutex_lock(mutex)
    }

    @inlinable @inline(__always) func unlock() {
        pthread_mutex_unlock(mutex)
    }

    private let mutex: UnsafeMutablePointer<pthread_mutex_t>
}
#endif
