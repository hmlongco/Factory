//
//  IsolationTests.swift
//  Factory
//
//  Created by Michael Long on 6/21/25.
//

import Testing
import Testing
import FactoryTesting

@testable import FactoryKit

@Suite(.container)
@MainActor
struct MainActorTest {

    @Test
    func mainActorProtocolResolution() async throws {
        let service = Container.shared.myMainActorType()
        let result = await service.load()
        #expect(result.contains("MainActor"))
    }

    @Test
    func mainActorInjection() async throws {
        let sut = DummyWithInjected()
        let result = await sut.myMainActorType.load()
        #expect(result.contains("MainActor"))
    }

    // test resolution of sendable type
    @Test
    func testSendableDependency() {
        let _: SomeSendableType = Container.shared.sendable()
    }

    // test resolution of main actor-based type
    @Test
    func testMainActorClassDependency() async {
        let _: SomeMainActorClass = Container.shared.mainActor()
    }

    // test resolution of main actor-based with nonisolated initializer
    @Test
    func testNonisolatedMainActorDependency() async {
        let _: NonisolatedMainActorType = Container.shared.nonisolatedMainActor()
    }

    // test resolution of test actor-based type from test actor
    @TestActor
    @Test
    func testActorDependencyFromTestActor() async {
        let _: TestActorType = Container.shared.testActor()
    }

    // test resolution of test actor-based type from main actor
    @Test
    func testActorDependencyFromMainActor() async {
        let _: TestActorType = await Container.shared.testActor()
    }

}

@MainActor
struct DummyWithInjected {
    @Injected(\.myMainActorType) var myMainActorType: MyMainActorType
}
