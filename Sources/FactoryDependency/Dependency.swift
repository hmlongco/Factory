@_exported import FactoryKit
@_exported import Observation

/// Controls the storage and resolution behavior of a `@Dependency`-injected property.
public enum DependencyMode {
    /// Resolve immediately when the type is initialized. Works on classes, structs, and actors. This is the default.
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
}

/// Injects a Factory dependency as a private stored property into the annotated type.
/// The property name and type are both derived from the key path — no annotation needed.
///
/// Apply once per dependency on the type declaration itself:
/// ```swift
/// // Immediate (default) mode
/// @Dependency(\.movieRepository)
/// final class HomeService { }
/// // generates: private var movieRepository = Container.shared.movieRepository()
///
/// // Lazy (classes/actors only):
/// @Dependency(\.movieRepository, mode: .lazy)
/// final class HomeService { }
/// // generates: private lazy var movieRepository = Container.shared.movieRepository()
///
/// // Optional — property type becomes T?:
/// @Dependency(\.movieRepository, mode: .optional)
/// final class HomeService { }
/// // generates: private var movieRepository = Optional(Container.shared.movieRepository())
///
/// // Weak — property type becomes T? with weak storage:
/// @Dependency(\.someService, mode: .weak)
/// final class HomeService { }
/// // generates: private weak var someService = Container.shared.someService()
///
/// // Dynamic:
/// @Dependency(\.movieRepository, mode: .dynamic)
/// final class HomeService { }
/// // generates: private @DynamicDependency(Container.shared.movieRepository()) var movieRepository
///
/// // Renaming services
/// @Observable @MainActor
/// @Dependency(\.movieRepository, name: "repo")
/// final class HomeViewModel { }
/// // generates: @ObservationIgnored private var repo = Container.shared.movieRepository()
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
/// @MainActor
/// @Observable
/// @Dependency(\.movieRepository)
/// final class HomeViewModel { }
/// // generates: @ObservationIgnored private var movieRepository = Container.shared.movieRepository()
/// ```
///
/// Also generates a `State` variable when the macro detects the enclosing type is a SwiftUI View.
///
/// ```swift
/// @Dependency(\.viewModel)
/// struct HomeView: View {
///     var body: some View { ... }
/// }
/// // generates: @State internal var viewModel = Container.shared.viewModel()
/// ```
@attached(member, names: arbitrary)
public macro Dependency<T>(
    _ keyPath: KeyPath<Container, Factory<T>>,
    name: String? = nil,
    mode: DependencyMode = .immediate
) = #externalMacro(module: "FactoryDependencyMacros", type: "DependencyMacro")

/// Injects a Factory dependency from a custom `SharedContainer`.
/// The container type is inferred from the keypath root:
/// ```swift
/// @Dependency(\MyContainer.myService)
/// final class SomeViewModel { }
/// ```
@attached(member, names: arbitrary)
public macro Dependency<C: SharedContainer, T>(
    _ keyPath: KeyPath<C, Factory<T>>,
    name: String? = nil,
    mode: DependencyMode = .immediate
) = #externalMacro(module: "FactoryDependencyMacros", type: "DependencyMacro")
