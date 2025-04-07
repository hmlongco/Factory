//
//  ContainerTrait.swift
//  Factory
//
//  Created by Grabecz, Akos on 2025. 04. 04..
//

import Testing

/// ``ContainerTrait`` is a test trait that provides a scoped container for dependency injection in tests.
/// It allows you to isolate the default ``Container`` to a test case, thus allowing you to run Swift Testing tests in parallel.
/// If you use a custom container, you have to create your own trait that conforms to the `TestTrait` protocol.
/// It is also possible to leverage this behavior in `XCTestCase`, by using the `@TaskLocal` provided `withValue` method. See examples in the ``ParallelXCTests`` file.
struct ContainerTrait: TestTrait, TestScoping {
    let value: Container

    func provideScope(
        for test: Test,
        testCase: Test.Case?,
        performing function: () async throws -> Void
    ) async throws {
        try await Container.$shared.withValue(value) {
            try await function()
        }
    }
}

extension Trait where Self == ContainerTrait {
    static var container: Self {
        Self(value: Container())
    }
}
