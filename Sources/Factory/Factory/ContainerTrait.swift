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

/// ``ContainerTrait`` is a test trait that provides a scoped container for dependency injection in tests.
/// It allows you to isolate the default ``Container`` to a test case, thus allowing you to run Swift Testing tests in parallel.
///
/// If you use a custom container, you have to create your own trait that conforms to the `TestTrait` protocol.
///
/// That said, it's also possible to leverage this behavior in `XCTestCase`, by using the `@TaskLocal` provided `withValue` method.
/// See examples in the ``ParallelXCTests`` file.
public struct ContainerTrait: TestTrait, TestScoping {
    let value: Container
    let resetSingletonScope: Bool
    public func provideScope(for test: Test, testCase: Test.Case?, performing function: () async throws -> Void) async throws {
        try await Container.$shared.withValue(value) {
            if resetSingletonScope {
                let singletonScope = Scope.Singleton()
                // Reset the singleton scope for this test
                singletonScope.reset()
                try await Scope.$singleton.withValue(singletonScope) {
                    try await function()
                }
            } else {
                try await function()
            }
        }
    }
}

public extension Trait where Self == ContainerTrait {
    static func container(resetSingletonScope: Bool = true) -> Self {
        Self(
            value: Container(),
            resetSingletonScope: resetSingletonScope
        )
    }
}
#endif
