//
// ContainerTrait.swift
//
// GitHub Repo and Documentation: https://github.com/hmlongco/Factory
//
// Copyright © 2025 Michael Long. All rights reserved.
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

#if swift(>=6.1)

import Testing

/// The ``TaskLocalSharedContainer`` protocol allows us to see ``SharedContainer`` to a test case, thus allowing you to run Swift
/// Testing tests in parallel.
public protocol TaskLocalContainer: SharedContainer {
    static var taskLocal: TaskLocal<Self> { get }
}

public typealias ContainerTraitSetup<C: SharedContainer> = @Sendable (C) -> Void

/// ``ContainerTrait`` is a test trait that provides a scoped container for dependency injection in tests.
/// It allows you to isolate a ``SharedContainer`` to a test case, thus allowing you to run Swift Testing tests in parallel.
///
/// If you use a custom container, you have to create your own trait variable that conforms to the `TestTrait` protocol.
///
/// That said, it's also possible to leverage this behavior in `XCTestCase`, by using the `@TaskLocal` provided `withValue` method.
/// See examples in the ``ParallelXCTests`` file.
public struct ContainerTrait<C: TaskLocalContainer>: TestTrait, TestScoping {
    let container: C
    public func provideScope(for test: Test, testCase: Test.Case?, performing function: () async throws -> Void) async throws {
        try await Scope.$singleton.withValue(Scope.singleton.clone()) {
            try await C.taskLocal.withValue(container) {
                try await function()
            }
        }
    }
}

/// Defaults for known container
extension Container: TaskLocalContainer {
    public static var taskLocal: TaskLocal<Container> { $shared }
}

/// Test defaults for known container
public extension Trait where Self == ContainerTrait<Container> {
    static var container: Self { ContainerTrait(container: Container()) }
}

#endif
