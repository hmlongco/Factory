//
//  ConcurrencyServices.swift
//  Factory
//
//  Created by Michael Long on 5/29/25.
//

@testable import FactoryKit

struct SomeSendableType: Sendable {}

// Factory with Sendable type
extension Container {
    var sendable: Factory<SomeSendableType> {
        self { SomeSendableType() }
    }
}

// Factory with MainActor-based class and initializer
@MainActor
final class SomeMainActorType {
    init() {}
}

extension Container {
    @MainActor
    var mainActor: Factory<SomeMainActorType> {
        self { @MainActor in SomeMainActorType() }
    }
}

// Factory with MainActor-based class and nonisolated initializer
@MainActor
final class NonisolatedMainActorType {
    nonisolated init() {}
    func test() {}
}

extension Container {
    var nonisolatedMainActor: Factory<NonisolatedMainActorType> {
        self { NonisolatedMainActorType() }
    }
}

@globalActor
public actor TestActor {
    public static let shared = TestActor()
}

@TestActor final class TestActorType {
    init() {}
}

extension Container {
    @TestActor
    var testActor: Factory<TestActorType> {
        self { @TestActor in TestActorType() }
    }
}
