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

// MARK: - Internal Variables

/// Master graph resolution depth counter
internal var globalGraphResolutionDepth = 0

/// Internal key used for Resolver mode
internal var globalResolverKey: StaticString = "*"

#if DEBUG
/// Internal variables used for debugging
internal var globalDependencyChain: [String] = []
internal var globalDependencyChainMessages: [String] = []
internal var globalTraceFlag: Bool = false
internal var globalTraceResolutions: [String] = []
internal var globalLogger: (String) -> Void = { print($0) }
internal var globalDebugInformationMap: [FactoryKey:FactoryDebugInformation] = [:]

/// Triggers fatalError after resetting enough stuff so unit tests can continue
internal func resetAndTriggerFatalError(_ message: String, _ file: StaticString, _ line: UInt) -> Never {
    globalDependencyChain = []
    globalDependencyChainMessages = []
    globalGraphResolutionDepth = 0
    globalRecursiveLock = RecursiveLock()
    globalTraceResolutions = []
    triggerFatalError(message, file, line) // GOES BOOM
}

/// Allow unit test interception of any fatal errors that may occur running the circular dependency check
/// Variation of solution: https://stackoverflow.com/questions/32873212/unit-test-fatalerror-in-swift#
internal var triggerFatalError = Swift.fatalError
#endif
