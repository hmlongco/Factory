//
// Globals.swift
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

internal final class RecursiveLock {
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
    @inlinable func lock() {
        pthread_mutex_lock(mutex)
    }
    @inlinable func unlock() {
        pthread_mutex_unlock(mutex)
    }
    private var mutex: UnsafeMutablePointer<pthread_mutex_t>
}

// MARK: - Internal Variables

/// Master graph resolution depth counter
internal var globalGraphResolutionDepth = 0

#if DEBUG
/// Internal variables used for debugging
internal var globalDependencyChain: [String] = []
internal var globalDependencyChainMessages: [String] = []
internal var globalTraceFlag: Bool = false
internal var globalTraceResolutions: [String] = []
internal var globalLogger: (String) -> Void = { print($0) }

/// Triggers fatalError after resetting enough stuff so unit tests can continue
internal func resetAndTriggerFatalError(_ message: String, _ file: String, _ line: Int) -> Never {
    globalDependencyChain = []
    globalDependencyChainMessages = []
    globalGraphResolutionDepth = 0
    globalRecursiveLock = RecursiveLock()
    globalTraceResolutions = []
    triggerFatalError(message, #file, #line) // GOES BOOM
}

/// Allow unit test interception of any fatal errors that may occur running the circular dependency check
/// Variation of solution: https://stackoverflow.com/questions/32873212/unit-test-fatalerror-in-swift#
internal var triggerFatalError = Swift.fatalError
#endif
