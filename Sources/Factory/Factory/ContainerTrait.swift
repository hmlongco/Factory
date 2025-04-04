//
//  ContainerTrait.swift
//  Factory
//
//  Created by Grabecz, Akos on 2025. 04. 04..
//

import Testing

//TODO: docs
/// Needs documentation
struct ContainerTrait: TestTrait, SuiteTrait, TestScoping {
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
