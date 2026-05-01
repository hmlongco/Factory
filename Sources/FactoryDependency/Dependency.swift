@_exported import FactoryKit
@_exported import Observation

/// Controls the storage and resolution behavior of a `@Dependency`-injected property.
public enum DependencyMode {
    /// Resolve immediately when the type is initialized. Works on classes, structs, and actors. This is the default.
    case immediate
    /// Resolve on first access, then cache. Classes and actors only (lazy var` is unsupported on structs).
    case lazy
    /// Resolve fresh from the container on every access. In the current member-macro implementation
    /// this generates the same stored property as `.immediate`; the container's own scope controls
    /// whether a new instance is returned.
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
/// @Observable @MainActor
/// @Dependency(\.movieRepository)
/// final class HomeViewModel { }
/// // generates: @ObservationIgnored private var movieRepository = Container.shared.movieRepository()
///
/// // Lazy (classes/actors only):
/// @Dependency(\.movieRepository, mode: .lazy)
/// final class HomeViewModel { }
/// // generates: @ObservationIgnored private lazy var movieRepository = Container.shared.movieRepository()
///
/// // Optional — property type becomes T?:
/// @Dependency(\.movieRepository, mode: .optional)
/// final class HomeViewModel { }
/// // generates: @ObservationIgnored private var movieRepository = Optional(Container.shared.movieRepository())
///
/// // Weak — property type becomes T? with weak storage:
/// @Dependency(\.someService, mode: .weak)
/// final class HomeViewModel { }
/// // generates: @ObservationIgnored private weak var someService = Container.shared.someService()
/// ```
///
/// `@ObservationIgnored` is emitted automatically when the macro detects `@Observable` on the type.
/// Non-`@Observable` types (plain classes, structs, actors) receive no `@ObservationIgnored`.
///
/// Stack multiple attributes for multiple dependencies:
/// ```swift
/// @Dependency(\.movieRepository)
/// @Dependency(\.authenticationService)
/// final class SomeViewModel { }
/// ```
@attached(member, names: arbitrary)
public macro Dependency<T>(
    _ keyPath: KeyPath<Container, Factory<T>>,
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
    mode: DependencyMode = .immediate
) = #externalMacro(module: "FactoryDependencyMacros", type: "DependencyMacro")
