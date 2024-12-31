import XCTest

@testable import Factory

private struct SomeSendableType: Sendable {}

// Factory with Sendable type
extension Container {
    fileprivate var sendable: Factory<SomeSendableType> {
        self { SomeSendableType() }
    }
}

// Factory with MainActor-based class and initializer
@MainActor
private final class SomeMainActorType {
    init() {}
}

extension Container {
    @MainActor
    fileprivate var mainActor: Factory<SomeMainActorType> {
        self { @MainActor in SomeMainActorType() }
    }
}

// Factory with MainActor-based class and nonisolated initializer
@MainActor
private final class NonIsolatedMainActorType {
    nonisolated init() {}
    func test() {}
}

extension Container {
    fileprivate var nonisolatedMainActor: Factory<NonIsolatedMainActorType> {
        self { NonIsolatedMainActorType() }
    }
}

@globalActor
public actor TestActor {
    public static let shared = TestActor()
}

@TestActor private final class TestActorType {
    init() {}
}

extension Container {
    @TestActor
    fileprivate var testActor: Factory<TestActorType> {
        self { @TestActor in TestActorType() }
    }
}

final class FactoryIsolationTests: XCTestCase {

    override func setUp() {
        super.setUp()
        Container.shared.reset()
    }

    // test resolution of sendable type
    @MainActor
    func testInjectSendableDependency() {
        let _: SomeSendableType = Container.shared.sendable()
    }

    // test resolution of main actor-based type
    @MainActor
    func testInjectMainActorDependency() async {
        let _: SomeMainActorType = Container.shared.mainActor()
    }

    // test resolution of main actor-based with nonisolated initializer
    @MainActor
    func testInjectNonisolatedMainActorDependency() async {
        let _: NonIsolatedMainActorType = Container.shared.nonisolatedMainActor()
    }

    // test resolution of test actor-based type from main actor
    @TestActor
    func testInjectTestActorDependency() async {
        let _: TestActorType = Container.shared.testActor()
    }

}
