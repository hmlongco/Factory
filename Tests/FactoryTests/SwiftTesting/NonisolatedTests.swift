import Testing
import FactoryKit
import FactoryTesting
import FactoryDependency

// MARK: - Service types

protocol NonisolatedServiceType: AnyObject {
    var name: String { get }
}

// Plain nonisolated service — no actor annotation, accessible from any context.
final class NonisolatedService: NonisolatedServiceType {
    let name = "NonisolatedService"
}

final class MockNonisolatedService: NonisolatedServiceType {
    let name = "MockNonisolatedService"
}

nonisolated
final class ExplicitlyNonisolatedService: NonisolatedServiceType {
    init() {}
    var name: String { "ExplicitlyNonisolatedService" }
}

nonisolated
final class MockExplicitlyNonisolatedService: NonisolatedServiceType {
    init() {}
    var name: String { "MockExplicitlyNonisolatedService" }
}

// MARK: - Container factories

extension Container {
    var nonisolatedService: Factory<NonisolatedServiceType> {
        self { NonisolatedService() }
    }
    var explicitlyNonisolatedService: Factory<NonisolatedServiceType> {
        self { ExplicitlyNonisolatedService() }
    }
}

// MARK: - Nonisolated demo services

@MainActor final class MainActorPropertyWrapperTestService {
    @Injected(\.nonisolatedService) var nonisolatedService
    @Injected(\.explicitlyNonisolatedService) var explicitlyNonisolatedService
}

nonisolated final class NonisolatedPropertyWrapperTestService {
    // @Injected(\.nonisolatedService) var nonisolatedService // 'nonisolated' is not supported on properties with property wrappers
    // @Injected(\.explicitlyNonisolatedService) var explicitlyNonisolatedService // 'nonisolated' is not supported on properties with property wrappers
}

nonisolated final class WorkAroundTestService {
    var nonisolatedService: NonisolatedServiceType = dependency(\.nonisolatedService)
    var explicitlyNonisolatedService: NonisolatedServiceType = dependency(\.explicitlyNonisolatedService)
}

@Dependency(\.nonisolatedService)
@Dependency(\.explicitlyNonisolatedService)
nonisolated final class NonisolatedDependencyTestService {}

@Dependency(\.nonisolatedService)
@Dependency(\.explicitlyNonisolatedService)
@MainActor final class MainActorDependencyTestService {}

// MARK: - Tests

@Suite(.container)
struct NonisolatedTests {

    // MARK: PropertyWrapperTestService
    // @Injected cannot be used inside a nonisolated class — the compiler rejects both
    // approaches (see commented-out code). No runtime tests are possible; the failure
    // is purely a compile-time error.

    // MARK: WorkAroundTestService — lazy var + dependency()

    @Test func workaroundResolvesDefaults() {
        let sut = WorkAroundTestService()
        #expect(sut.nonisolatedService.name == "NonisolatedService")
        #expect(sut.explicitlyNonisolatedService.name == "ExplicitlyNonisolatedService")
    }

    @Test func workaroundUsesRegistrationOverrides() {
        Container.shared.nonisolatedService.register { MockNonisolatedService() }
        Container.shared.explicitlyNonisolatedService.register { MockExplicitlyNonisolatedService() }
        let sut = WorkAroundTestService()
        #expect(sut.nonisolatedService.name == "MockNonisolatedService")
        #expect(sut.explicitlyNonisolatedService.name == "MockExplicitlyNonisolatedService")
    }

    // MARK: NonisolatedDependencyTestService — @Dependency macro on nonisolated class

    @Test func nonisolatedMacroResolvesDefaults() {
        let sut = NonisolatedDependencyTestService()
        #expect(sut.nonisolatedService.name == "NonisolatedService")
        #expect(sut.explicitlyNonisolatedService.name == "ExplicitlyNonisolatedService")
    }

    @Test func nonisolatedMacroUsesRegistrationOverrides() {
        Container.shared.nonisolatedService.register { MockNonisolatedService() }
        Container.shared.explicitlyNonisolatedService.register { MockExplicitlyNonisolatedService() }
        let sut = NonisolatedDependencyTestService()
        #expect(sut.nonisolatedService.name == "MockNonisolatedService")
        #expect(sut.explicitlyNonisolatedService.name == "MockExplicitlyNonisolatedService")
    }

    // MARK: MainActorDependencyTestService — @Dependency macro on @MainActor class

    @MainActor @Test func mainActorMacroResolvesDefaults() {
        let sut = MainActorDependencyTestService()
        #expect(sut.nonisolatedService.name == "NonisolatedService")
        #expect(sut.explicitlyNonisolatedService.name == "ExplicitlyNonisolatedService")
    }

    @MainActor @Test func mainActorMacroUsesRegistrationOverrides() {
        Container.shared.nonisolatedService.register { MockNonisolatedService() }
        Container.shared.explicitlyNonisolatedService.register { MockExplicitlyNonisolatedService() }
        let sut = MainActorDependencyTestService()
        #expect(sut.nonisolatedService.name == "MockNonisolatedService")
        #expect(sut.explicitlyNonisolatedService.name == "MockExplicitlyNonisolatedService")
    }

}
