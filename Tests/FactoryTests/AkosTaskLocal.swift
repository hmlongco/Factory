//
//  AkosTaskLocal.swift
//  Factory
//
//  Created by Grabecz, Akos on 2025. 04. 04..
//

@testable import Factory
import Testing

@Suite
struct PlayingWithTaskLocal {
    @Test(.container(Container()))
    func foo() {
        let sut = SomeUseCase()

//        let containerCopy = Container()

        Container.shared.example.register {
            Example1()
        }

        Container.$shared.withValue(Container.shared) {
            let result = sut.execute()
            #expect(result == "foo")
        }
    }

    @Test(.container(Container()))
    func bar() {
        let sut = SomeUseCase()

//        let containerCopy = Container()

        Container.shared.example.register {
            Example2()
        }

        Container.$shared.withValue(Container.shared) {
            let result = sut.execute()
            #expect(result == "bar")
        }
    }
}

struct DependencyTrait: TestTrait, TestScoping {
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

extension Trait where Self == DependencyTrait {
    static func container(_ container: Container) -> Self {
        Self(value: container)
    }
}
