import XCTest

@testable import FactoryKit

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
        let _: NonisolatedMainActorType = Container.shared.nonisolatedMainActor()
    }

    // test resolution of test actor-based type from main actor
    @TestActor
    func testInjectTestActorDependency() async {
        let _: TestActorType = Container.shared.testActor()
    }

}
