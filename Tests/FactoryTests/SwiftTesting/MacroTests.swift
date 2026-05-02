import Testing
import SwiftUI
import FactoryMacros
import FactoryTesting

// MARK: - Container factories

extension Container {
    var macroMyService: Factory<MyServiceType> {
        self { MyService() }
    }
    var macroCachedService: Factory<MyServiceType> {
        self { MyService() }.cached
    }
    var macroOptionalService: Factory<MyServiceType?> {
        self { MyService() }
    }
    // cached so the container holds a strong ref during weak-mode tests
    var macroWeakService: Factory<MyService> {
        self { MyService() }.cached
    }
    @MainActor var macroMainActorService: Factory<MyMainActorType> {
        self { MyMainActorService() }
    }
    @TestActor var macroTestActorService: Factory<MyTestActorType> {
        self { MyTestActorService() }
    }
}

// MARK: - Observable view-model types (iOS 17 / macOS 14)

@available(macOS 14.0, iOS 17.0, *)
@Observable @MainActor
final class ViewModel {
    var value: Int
    init(value: Int = 1) {
        self.value = value
    }
}

@available(macOS 14.0, iOS 17.0, *)
extension Container {
    @MainActor var macroViewModel: Factory<ViewModel> {
        self { ViewModel() }
    }
}

// MARK: - Consumer types

@Dependency(\.macroMyService)
final class ImmediateConsumer {}

@Dependency(\.macroMyService, mode: .lazy)
final class LazyConsumer {}

@Dependency(\.macroCachedService)
final class CachedConsumer {}

// factory returns MyServiceType? — _wrapOptional pass-through gives MyServiceType?
@Dependency(\.macroOptionalService, mode: .optional)
final class OptionalModeConsumer {}

@Dependency(\.macroWeakService, mode: .weak)
final class WeakConsumer {}

@Dependency(\.macroMyService, mode: .dynamic)
final class DynamicConsumer {}

@Dependency(\.macroMyService)
@Dependency(\.macroCachedService)
final class MultiDependencyConsumer {}

@available(macOS 14.0, iOS 17.0, *)
@MainActor
@Observable
@Dependency(\.macroMyService)
final class ObservableConsumer {}

@available(macOS 14.0, iOS 17.0, *)
@MainActor
@Observable
@Dependency(\.macroMainActorService)
final class MainActorConsumer {}

@TestActor
@Dependency(\.macroTestActorService)
final class TestActorConsumer {}

// name only — property is "service", factory key is "macroMyService"
@Dependency(\.macroMyService, name: "service")
final class NamedConsumer {}

// name + mode combined
@Dependency(\.macroCachedService, name: "cachedService", mode: .lazy)
final class NamedLazyConsumer {}

@available(macOS 14.0, iOS 17.0, *)
@Dependency(\.macroViewModel)
struct ViewModelConsumerView: View {
    var body: some View { EmptyView() }
}

// MARK: - Tests

@Suite(.container)
struct MacroTests {

    // MARK: Immediate mode

    @Test func immediateResolvesDefaultFactory() {
        let sut = ImmediateConsumer()
        #expect(sut.macroMyService is MyService)
    }

    @Test func immediateUsesRegistrationOverride() {
        Container.shared.macroMyService.register { MockService() }
        let sut = ImmediateConsumer()
        #expect(sut.macroMyService is MockService)
    }

    @Test func immediateIsolatedBetweenTests() {
        // No registration — should always get the default
        let sut = ImmediateConsumer()
        #expect(sut.macroMyService is MyService)
    }

    // MARK: Lazy mode

    @Test func lazyResolvesOnFirstAccess() {
        let sut = LazyConsumer()
        #expect(sut.macroMyService is MyService)
    }

    @Test func lazyUsesRegistrationOverrideAtAccessTime() {
        Container.shared.macroMyService.register { MockService() }
        let sut = LazyConsumer()
        #expect(sut.macroMyService is MockService)
    }

    // MARK: Dynamic mode

    @Test func dynamicResolvesDefault() {
        let sut = DynamicConsumer()
        #expect(sut.macroMyService is MyService)
    }

    @Test func dynamicReflectsRegistrationMadeAfterInit() {
        let sut = DynamicConsumer()
        #expect(sut.macroMyService is MyService)
        Container.shared.macroMyService.register { MockService() }
        // Unlike immediate mode, the re-registration is visible on the next access.
        #expect(sut.macroMyService is MockService)
    }

    // MARK: Scope

    @Test func cachedScopeReturnsSameInstance() {
        let a = CachedConsumer()
        let b = CachedConsumer()
        #expect(a.macroCachedService.id == b.macroCachedService.id)
    }

    @Test func cachedScopeResetYieldsNewInstance() {
        let a = CachedConsumer()
        let idBefore = a.macroCachedService.id
        Container.shared.macroCachedService.reset(.scope)
        let b = CachedConsumer()
        #expect(b.macroCachedService.id != idBefore)
    }

    // MARK: Optional mode

    @Test func optionalModeWrapsNonNilValue() {
        let sut = OptionalModeConsumer()
        #expect(sut.macroOptionalService != nil)
        #expect(sut.macroOptionalService is MyService)
    }

    @Test func optionalModeReflectsNilRegistration() {
        Container.shared.macroOptionalService.register { nil }
        let sut = OptionalModeConsumer()
        #expect(sut.macroOptionalService == nil)
    }

    // MARK: Weak mode

    @Test func weakRetainsWhileContainerCacheIsAlive() {
        let sut = WeakConsumer()
        #expect(sut.macroWeakService != nil)
    }

    // MARK: Multiple dependencies

    @Test func multipleDependenciesAllInjected() {
        let sut = MultiDependencyConsumer()
        #expect(sut.macroMyService is MyService)
        #expect(sut.macroCachedService is MyService)
    }

    @Test func multipleDependenciesOverrideIndependently() {
        Container.shared.macroMyService.register { MockService() }
        let sut = MultiDependencyConsumer()
        #expect(sut.macroMyService is MockService)
        #expect(sut.macroCachedService is MyService)
    }

    // MARK: @Observable

    @available(macOS 14.0, iOS 17.0, *)
    @MainActor @Test func observableConsumerResolvesService() {
        let sut = ObservableConsumer()
        #expect(sut.macroMyService is MyService)
    }

    @available(macOS 14.0, iOS 17.0, *)
    @MainActor @Test func observableConsumerUsesRegistrationOverride() {
        Container.shared.macroMyService.register { MockService() }
        let sut = ObservableConsumer()
        #expect(sut.macroMyService is MockService)
    }

    // MARK: @MainActor

    @available(macOS 14.0, iOS 17.0, *)
    @MainActor @Test func mainActorConsumerResolvesService() {
        let sut = MainActorConsumer()
        #expect(sut.macroMainActorService is MyMainActorService)
    }

    @available(macOS 14.0, iOS 17.0, *)
    @MainActor @Test func mainActorConsumerUsesRegistrationOverride() {
        Container.shared.macroMainActorService.register { MockMainActorService() }
        let sut = MainActorConsumer()
        #expect(sut.macroMainActorService is MockMainActorService)
    }

    // MARK: Named override

    @Test func namedPropertyResolvesDefault() {
        let sut = NamedConsumer()
        #expect(sut.service is MyService)
    }

    @Test func namedPropertyUsesRegistrationOverride() {
        Container.shared.macroMyService.register { MockService() }
        let sut = NamedConsumer()
        #expect(sut.service is MockService)
    }

    @Test func namedLazyPropertyResolvesDefault() {
        let sut = NamedLazyConsumer()
        #expect(sut.cachedService is MyService)
    }

    // MARK: Custom global actor (@TestActor)

    @TestActor @Test func testActorConsumerResolvesService() async {
        let sut = TestActorConsumer()
        #expect(sut.macroTestActorService is MyTestActorService)
    }

    @TestActor @Test func testActorConsumerUsesRegistrationOverride() async {
        Container.shared.macroTestActorService.register { MockTestActorService() }
        let sut = TestActorConsumer()
        #expect(sut.macroTestActorService is MockTestActorService)
    }

    // MARK: SwiftUI View with @Observable @MainActor view-model

    @available(macOS 14.0, iOS 17.0, *)
    @MainActor @Test func swiftUIViewResolvesObservableViewModel() {
        let sut = ViewModelConsumerView()
        #expect(sut.macroViewModel.value == 1)
    }

    @available(macOS 14.0, iOS 17.0, *)
    @MainActor @Test func swiftUIViewUsesRegistrationOverrideForObservableViewModel() {
        Container.shared.macroViewModel.register { ViewModel(value: 99) }
        let sut = ViewModelConsumerView()
        #expect(sut.macroViewModel.value == 99)
    }

}
