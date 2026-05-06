@_exported import FactoryKit
@_exported import Observation

/// Controls the storage and resolution behavior of a `@Dependency`-injected property.
public enum DependencyMode {
    /// Resolve immediately and store as a plain `let`. Works on classes, structs, and actors.
    /// Used automatically when `mode:` is omitted off a SwiftUI `View`; pass `.immediate` explicitly
    /// inside a `View` to opt out of `@State` storage.
    case immediate
    /// Resolve on first access, then cache. Classes and actors only (lazy var` is unsupported on structs).
    case lazy
    /// Resolve fresh from the container on every access. The macro generates a `@DynamicDependency`-
    /// backed property whose getter always calls through to the factory, so late registrations and
    /// scope resets are immediately visible without recreating the containing object.
    case dynamic
    /// Wrap the resolved value in `Optional`, yielding a `T?` property.
    case optional
    /// Hold a weak reference to the resolved value, yielding a `T?` property.
    /// The declared type must be a class — protocol types require an `AnyObject` constraint.
    case weak
    /// Stores resolved object in a `@State` property. Default when the enclosing type is a SwiftUI `View`;
    /// errors elsewhere; `@State` requires SwiftUI-owned storage.
    case observable
    /// Store resolved object in a `@StateObject` property. Use on a SwiftUI `View` when the injected dependency
    /// conforms to `ObservableObject`; errors elsewhere.
    case observableObject
}

/// Injects a Factory dependency as an internally-accessible stored property on the annotated type.
/// The property name and type are both derived from the key path — no annotation needed.
///
/// When `mode:` is omitted, the storage shape depends on context: a SwiftUI `View` gets `@State`
/// (equivalent to `.observable`); any other enclosing type gets a plain `let` (equivalent to
/// `.immediate`).
///
/// Apply once per dependency on the type declaration itself:
/// ```swift
/// // Immediate (default off a View)
/// @Dependency(\.movieRepository)
/// final class HomeService { }
/// // generates: internal let movieRepository = Container.shared.movieRepository()
///
/// // Lazy (classes/actors only):
/// @Dependency(\.movieRepository, .lazy)
/// final class HomeService { }
/// // generates: internal lazy var movieRepository = Container.shared.movieRepository()
///
/// // Optional — property type becomes T?:
/// @Dependency(\.movieRepository, .optional)
/// final class HomeService { }
/// // generates: internal var movieRepository = _wrapOptional(Container.shared.movieRepository())
///
/// // Weak — property type becomes T? with weak storage:
/// @Dependency(\.someService, .weak)
/// final class HomeService { }
/// // generates: internal weak var someService = Container.shared.someService()
///
/// // Dynamic:
/// @Dependency(\.movieRepository, .dynamic)
/// final class HomeService { }
/// // generates: @DynamicDependency internal var movieRepository = Container.shared.movieRepository()
///
/// // Renaming services
/// @Observable @MainActor
/// @Dependency(\.movieRepository, name: "repo")
/// final class HomeViewModel { }
/// // generates: @ObservationIgnored internal let repo = Container.shared.movieRepository()
/// ```
///
/// Stack multiple attributes for multiple dependencies:
/// ```swift
/// @Dependency(\.movieRepository)
/// @Dependency(\.authenticationService)
/// final class SomeViewModel { }
/// ```
///
/// `@ObservationIgnored` is emitted automatically when the macro detects `@Observable` on the type.
/// Non-`@Observable` types (plain classes, structs, actors) receive no `@ObservationIgnored`.
///
/// ```swift
/// @Dependency(\.movieRepository)
/// @MainActor @Observable final class HomeViewModel { }
/// // generates: @ObservationIgnored internal let movieRepository = Container.shared.movieRepository()
/// ```
///
/// On a SwiftUI `View`, the macro defaults to `.observable` and generates a `@State` property
/// so SwiftUI owns the storage across body re-evaluations:
///
/// ```swift
/// @Dependency(\.viewModel)
/// struct HomeView: View {
///     // generates: @State internal var viewModel = Container.shared.viewModel()
///     var body: some View { ... }
/// }
/// ```
///
/// For a view-model that conforms to `ObservableObject`, pass `mode: .observableObject` so the
/// macro emits a `@StateObject` property instead — SwiftUI then owns the subscription:
///
/// ```swift
/// @Dependency(\.legacyViewModel, .observableObject)
/// struct HomeView: View {
///     // generates: @StateObject internal var legacyViewModel = Container.shared.legacyViewModel()
///     var body: some View { ... }
/// }
/// ```
///
/// To opt out of `@State` inside a `View`, pass `mode: .immediate` explicitly:
///
/// ```swift
/// @Dependency(\.cache, .immediate)
/// struct CacheView: View {
///     // generates: internal let cache = Container.shared.cache()
///     var body: some View { ... }
/// }
/// ```
@attached(member, names: arbitrary)
public macro Dependency<T>(
    _ keyPath: KeyPath<Container, Factory<T>>,
    _ mode: DependencyMode? = nil,
    name: String? = nil
) = #externalMacro(module: "FactoryMacrosPlugin", type: "DependencyMacro")

/// Injects a Factory dependency from a custom `SharedContainer`.
/// The container type is inferred from the keypath root:
/// ```swift
/// @Dependency(\MyContainer.myService)
/// final class SomeViewModel { }
/// ```
@attached(member, names: arbitrary)
public macro Dependency<C: SharedContainer, T>(
    _ keyPath: KeyPath<C, Factory<T>>,
    _ mode: DependencyMode? = nil,
    name: String? = nil
) = #externalMacro(module: "FactoryMacrosPlugin", type: "DependencyMacro")
