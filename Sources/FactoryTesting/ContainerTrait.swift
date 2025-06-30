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

#if DEBUG
#if swift(>=6.1)

#if canImport(FactoryKit)
import FactoryKit
#elseif canImport(Factory)
import Factory
#endif

import Testing

/// ``ContainerTrait`` is a generic test trait that provides a scoped container for dependency injection in tests.
///
/// It allows you to isolate a `SharedContainer` to a test case allowing you to run Swift Testing tests in parallel.
///
/// If you use a custom container, you have to create your own trait and container variable extensions.
///
/// That said, it's also possible to leverage this behavior in XCTesting by inheriting `XCContainerTestCase` instead of `XCTestCase`.
///
/// See the `Testing` documentation and examples in the `ParallelTests` and `ParallelXCTests` files.
public struct ContainerTrait<C: SharedContainer>: TestTrait, SuiteTrait, TestScoping {

    public typealias Transform = @Sendable (C) async -> Void

    private let shared: TaskLocal<C>
    private let container: @Sendable () -> C

    private var transform: Transform? = nil

    /// If SuiteTrait then provideScope is called to provide a new container for each individual test and child suite in the suite.
    public let isRecursive: Bool = true

    public init(shared: TaskLocal<C>, container: @autoclosure @escaping @Sendable () -> C) {
        self.shared = shared
        self.container = container
    }

    public func provideScope(for test: Test, testCase: Test.Case?, performing function: () async throws -> Void) async throws {
        try await withContainer(
            shared: self.shared,
            container: self.container(),
            operation: function,
            transform: transform
        )
    }

    public func callAsFunction(transform: @escaping Transform) -> Self {
        var copy = self
        copy.transform = transform
        return copy
    }
}

/// Provides test trait for default container
extension Trait where Self == ContainerTrait<Container> {
    public static var container: ContainerTrait<Container> {
        .init(shared: Container.$shared, container: .init())
    }
}

#endif
#endif
