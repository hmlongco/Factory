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

// MARK: - ObservableObject (Combine) view-model

@MainActor
final class LegacyViewModel: ObservableObject {
    @Published var value: Int
    init(value: Int = 1) {
        self.value = value
    }
}

extension Container {
    @MainActor var macroLegacyViewModel: Factory<LegacyViewModel> {
        self { LegacyViewModel() }
    }
}

// MARK: - Consumer types

@Dependency(\.macroMyService)
final class ImmediateConsumer {
    func load() {
        let _ = macroMyService.text()
    }
}

@Dependency(\.macroMyService, .lazy)
final class LazyConsumer {}

@Dependency(\.macroCachedService)
final class CachedConsumer {}

// factory returns MyServiceType? — _wrapOptional pass-through gives MyServiceType?
@Dependency(\.macroOptionalService, .optional)
final class OptionalModeConsumer {}

@Dependency(\.macroWeakService, .weak)
final class WeakConsumer {}

@Dependency(\.macroMyService, .dynamic)
final class DynamicConsumer {}

// .optional applied to a non-optional Factory<T> — proves _wrapOptional is emitted
// (existing OptionalModeConsumer uses an already-optional factory so it can't tell
// .optional apart from .immediate).
@Dependency(\.macroMyService, .optional)
final class OptionalLiftConsumer {}

@Dependency(\.macroMyService)
@Dependency(\.macroCachedService)
final class MultiDependencyConsumer {}

@available(macOS 14.0, iOS 17.0, *)
@Dependency(\.macroMyService)
@MainActor @Observable final class ObservableConsumer {}

@available(macOS 14.0, iOS 17.0, *)
@Dependency(\.macroMainActorService)
@MainActor @Observable final class MainActorConsumer {}

@Dependency(\.macroTestActorService)
@TestActor final class TestActorConsumer {}

// name only — property is "service", factory key is "macroMyService"
@Dependency(\.macroMyService, name: "service")
final class NamedConsumer {}

// name + mode combined
@Dependency(\.macroCachedService, .lazy, name: "cachedService",)
final class NamedLazyConsumer {}

@available(macOS 14.0, iOS 17.0, *)
@Dependency(\.macroViewModel)
struct ViewModelConsumerView: View {
    var body: some View { EmptyView() }
}

// Explicit .observableObject — emits @StateObject for an ObservableObject view-model
@available(macOS 14.0, iOS 17.0, *)
@Dependency(\.macroLegacyViewModel, .observableObject)
struct LegacyViewModelConsumerView: View {
    var body: some View { EmptyView() }
}

// Explicit .observable — exercises the explicit @State path (matches the View default)
@available(macOS 14.0, iOS 17.0, *)
@Dependency(\.macroViewModel, .observable)
struct ExplicitObservableConsumerView: View {
    var body: some View { EmptyView() }
}

// Explicit .immediate inside a View — emits a plain `let`, opting out of @State storage
@Dependency(\.macroMyService, .immediate)
struct ImmediateInsideViewConsumer: View {
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

    // Distinguishing test: immediate would resolve the factory at init.
    @Test func lazyDoesNotResolveAtInit() {
        final class Counter: @unchecked Sendable { var count = 0 }
        let counter = Counter()
        Container.shared.macroMyService.register {
            counter.count += 1
            return MyService()
        }
        let sut = LazyConsumer()
        #expect(counter.count == 0)
        _ = sut.macroMyService
        #expect(counter.count == 1)
        _ = sut.macroMyService
        #expect(counter.count == 1)   // cached after first access
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

    // Distinguishing test: applies .optional to a non-optional Factory<T>; the
    // generated property must have type T?, not T. Without _wrapOptional the
    // property would be MyServiceType (immediate fallback) and Mirror's display
    // style would not be .optional.
    @Test func optionalLiftsNonOptionalFactoryToOptional() {
        let sut = OptionalLiftConsumer()
        #expect(Mirror(reflecting: sut.macroMyService as Any).displayStyle == .optional)
        #expect(sut.macroMyService is MyService)
    }

    // MARK: Weak mode

    @Test func weakRetainsWhileContainerCacheIsAlive() {
        let sut = WeakConsumer()
        #expect(sut.macroWeakService != nil)
    }

    // Distinguishing test: with .weak the property holds only a weak reference,
    // so dropping the container's cached strong ref must let the value deallocate.
    // Immediate (strong let) would keep it alive forever.
    @Test func weakReleasesWhenContainerCacheReleases() {
        let sut = WeakConsumer()
        #expect(sut.macroWeakService != nil)
        Container.shared.macroWeakService.reset(.scope)
        #expect(sut.macroWeakService == nil)
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

    // MARK: SwiftUI View with ObservableObject (StateObject) view-model

    @available(macOS 14.0, iOS 17.0, *)
    @MainActor @Test func swiftUIViewResolvesObservableObjectViewModel() {
        let sut = LegacyViewModelConsumerView()
        #expect(sut.macroLegacyViewModel.value == 1)
    }

    @available(macOS 14.0, iOS 17.0, *)
    @MainActor @Test func swiftUIViewUsesRegistrationOverrideForObservableObjectViewModel() {
        Container.shared.macroLegacyViewModel.register { LegacyViewModel(value: 99) }
        let sut = LegacyViewModelConsumerView()
        #expect(sut.macroLegacyViewModel.value == 99)
    }

    // MARK: SwiftUI View — explicit modes

    @available(macOS 14.0, iOS 17.0, *)
    @MainActor @Test func swiftUIViewExplicitObservableModeResolves() {
        let sut = ExplicitObservableConsumerView()
        #expect(sut.macroViewModel.value == 1)
    }

    @MainActor @Test func swiftUIViewImmediateModeResolves() {
        let sut = ImmediateInsideViewConsumer()
        #expect(sut.macroMyService is MyService)
    }

}
