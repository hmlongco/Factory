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
internal var globalRecursiveLock = RecursiveLock()

/// Custom recursive lock
internal struct RecursiveLock {

    init() {
        let mutexAttr = UnsafeMutablePointer<pthread_mutexattr_t>.allocate(capacity: 1)
        pthread_mutexattr_init(mutexAttr)
        pthread_mutexattr_settype(mutexAttr, Int32(PTHREAD_MUTEX_RECURSIVE))
        mutex = UnsafeMutablePointer<pthread_mutex_t>.allocate(capacity: 1)
        pthread_mutex_init(mutex, mutexAttr)
        pthread_mutexattr_destroy(mutexAttr)
        mutexAttr.deallocate()
    }

//    deinit {
//        pthread_mutex_destroy(mutex)
//        mutex.deallocate()
//    }

    @inline(__always) func lock() {
        pthread_mutex_lock(mutex)
    }

    @inline(__always) func unlock() {
        pthread_mutex_unlock(mutex)
    }

    @usableFromInline let mutex: UnsafeMutablePointer<pthread_mutex_t>

}

/// Master spin lock
internal let globalDebugLock = SpinLock()

#if os(macOS) || os(iOS) || os(watchOS)
/// Custom spin lock
internal struct SpinLock {

    init() {
        oslock = UnsafeMutablePointer<os_unfair_lock>.allocate(capacity: 1)
        oslock.initialize(to: .init())
    }

    @inline(__always) func lock() {
        os_unfair_lock_lock(oslock)
    }

    @inline(__always) func unlock() {
        os_unfair_lock_unlock(oslock)
    }

    @usableFromInline let oslock: UnsafeMutablePointer<os_unfair_lock>

}
#else
/// Custom spin lock compatible with Linux
internal struct SpinLock {

    init() {
        mutex = UnsafeMutablePointer<pthread_mutex_t>.allocate(capacity: 1)
        let attributes = UnsafeMutablePointer<pthread_mutexattr_t>.allocate(capacity: 1)
        pthread_mutexattr_init(attributes)
        pthread_mutexattr_settype(attributes, Int32(PTHREAD_MUTEX_NORMAL))
        pthread_mutex_init(mutex, attributes)
        pthread_mutexattr_destroy(attributes)
        attributes.deallocate()
    }

    @inline(__always) func lock() {
        pthread_mutex_lock(mutex)
    }

    @inline(__always) func unlock() {
        pthread_mutex_unlock(mutex)
    }

    @usableFromInline let mutex: UnsafeMutablePointer<pthread_mutex_t>
}
#endif
