# Dependency Macros

Reduce dependency-injection boilerplate with the `@Dependency` attached macro.

## Overview

`FactoryDependency` is a companion library that ships alongside FactoryKit. It provides
the `@Dependency` macro, which generates injected stored properties automatically from a
key-path expression. 

Where you would previously write an `@Injected` property wrapper or
a `var` initializer by hand for each dependency, a single `@Dependency` attribute
covers the entire declaration.

```swift
import FactoryDependency

// Before
final class HomeViewModel {
    @Injected(\.movieRepository) var movieRepository: MovieRepositoryType
    @Injected(\.authService) var authService: AuthServiceType
}

// After
@Dependency(\.movieRepository)
@Dependency(\.authService)
final class HomeViewModel { }
```

The macro expands at compile time into plain stored properties with the same name as the factory. 

This approach avoids all of the runtime overhead typically attached to property wrappers and property wrapper accessors. It also exposes the object's dependencies and promotes thesm out of the object's internal properties and other clutter, making them crystal clear.

## Generated Code

For the default (immediate) mode, prepending `@Dependency(\.myService)` to a class expands to:

```swift
internal var myService = Container.shared.myService()
```

The property name and resolved type are both derived from the key path, so no annotation
is needed on the declaration itself. Stack multiple attributes to inject multiple
dependencies:

```swift
@Dependency(\.repository)
@Dependency(\.featureFlags)
@Dependency(\.analytics)
final class DashboardViewModel { }
```

## Dependency Modes

The `mode` parameter controls storage and resolution behavior. The options are:

* Immediate (default)
* Dynamic
* Lazy
* Optional
* Weak

### Immediate

Resolved once when the containing type is initialized. This is the default.

```swift
@Dependency(\.myService)
final class SomeService { }
// generates: internal var myService = Container.shared.myService()
```

### Dynamic

Resolved on every property access. Unlike immediate mode, registrations made or reset
after the containing object is created are immediately visible — useful for feature-flag
driven services or when you need to observe container changes without recreating the
consumer.

```swift
@Dependency(\.myService, mode: .dynamic)
final class SomeService { }
// generates: @DynamicDependency(wrappedValue: Container.shared.myService()) internal var myService
```

The `@DynamicDependency` property wrapper captures the factory call as a deferred
closure so the container is queried fresh on every read. `mode: .dynamic` is not
supported on SwiftUI `View` types.

### Lazy

Resolved on the first access, then cached in the stored property. Available on classes
and actors; structs do not support `lazy var`.

```swift
@Dependency(\.myService, mode: .lazy)
final class SomeService { }
// generates: internal lazy var myService = Container.shared.myService()
```

### Optional

Wraps the resolved value in an `Optional`, yielding a `T?` property. 

```swift
@Dependency(\.myService, mode: .optional)
final class SomeService { }
// generates: internal var myService = _wrapOptional(Container.shared.myService())
```

A pass-through overload prevents double-wrapping when the factory itself already returns an optional, but in that case `.optional` isn't really needed.

### Weak

Holds a weak reference to the resolved instance. The property type becomes `T?`.

```swift
@Dependency(\.myService, mode: .weak)
final class SomeService { }
// generates: internal weak var myService = Container.shared.myService()
```

## Renaming the Property

Pass `name:` to override the generated property name while still resolving from the
original factory key path. This is useful when a shorter or context-specific name is
more expressive at the call site.

```swift
@Dependency(\.movieRepository, name: "repo")
final class SomeService { }
// generates: internal var repo = Container.shared.movieRepository()
```

## @Observable Classes

When `@Observable` is present on the enclosing type, the macro automatically prefixes
the generated property with `@ObservationIgnored`. This opts the injected dependency out
of the `@Observable` tracking machinery — the service itself is not an observable value,
so there is nothing for the system to track.

```swift
@MainActor
@Observable
@Dependency(\.movieRepository)
final class HomeViewModel { }
// generates: @ObservationIgnored internal var movieRepository = Container.shared.movieRepository()
```

## SwiftUI Views

When applied to a type that conforms to `View`, the macro generates a `@State` property
instead of a plain `var`. This ensures SwiftUI owns the storage across render passes,
preventing the dependency from being recreated on every view update.

```swift
@Dependency(\.viewModel)
struct HomeView: View {
    var body: some View { ... }
}
// generates: @State internal var viewModel = Container.shared.viewModel()
```

Because `View` conformance carries `@MainActor` isolation, the factory key path may
also be `@MainActor`-isolated without any additional annotation:

```swift
extension Container {
    @MainActor var viewModel: Factory<ViewModel> { self { ViewModel() } }
}
```

> Note: `mode: .lazy` and `mode: .weak` are not supported on `View` types and produce a
> compile-time error. Use the default mode and let SwiftUI's `@State` manage the lifecycle.

## Actor Isolation

The macro generates code that correctly inherits the enclosing type's actor isolation.

### @MainActor classes

The generated stored property is `@MainActor`-isolated when the enclosing type is.
No extra annotation is needed, and calling a `@MainActor`-isolated factory from a
`@MainActor` class is perfectly valid:

```swift
@MainActor
@Dependency(\.mainActorService)
final class MainActorViewModel { }
```

### Custom global actors

Any `@globalActor` is handled identically. The macro detects the actor annotation and
generates an actor-isolated property that the owning type can access without `await`:

```swift
@TestActor
@Dependency(\.testActorService)
final class TestActorViewModel { }
```

### Nonisolated classes

`nonisolated` classes (a common pattern in Swift 6.2 Approachable Concurrency) are fully
supported. The macro generates a plain nonisolated stored property initialized from the
nonisolated factory:

```swift
@Dependency(\.analyticsService)
nonisolated final class AnalyticsLogger { }
```

## Why Macros Instead of Property Wrappers

FactoryKit's `@Injected` property wrapper is convenient in many situations, but Swift 6
strict concurrency exposes a fundamental limitation: **`nonisolated` is not supported on
properties with property wrappers**.

The problem has two layers:

**Layer 1 — Sendable conflict.** A `@MainActor final class` is implicitly `Sendable`.
All `nonisolated` stored properties on a `Sendable` type must also be `Sendable`.
`@Injected` stores the resolved value in a `nonisolated` backing var, so
`Injected<T>` must be `Sendable` — which requires `T: Sendable`. Services that are
not `Sendable` produce:

```
error: stored property '_service' of 'Sendable'-conforming main actor-isolated
       class 'MyViewModel' is nonisolated but has non-'Sendable' type
       'Injected<any MyServiceType>'
```

**Layer 2 — No escape hatch.** Marking the property `nonisolated` to break the
`Sendable` requirement is outright rejected:

```
error: 'nonisolated' is not supported on properties with property wrappers
```

This limitation is fundamental to how property wrappers are implemented: the hidden
mutable backing variable (`_service`) cannot be made `nonisolated` without undermining
thread-safety guarantees the compiler cannot verify.

`@Dependency` sidesteps both layers entirely. Because the macro generates a plain stored
property — not a property-wrapper-backed one — the property inherits the enclosing
type's actor isolation naturally, with no `Sendable` requirement on the resolved type.

### Comparison

| | `@Injected` | `lazy var dependency()` | `@Dependency` macro |
|---|---|---|---|
| Nonisolated class | ✗ compile error | ✓ | ✓ |
| `@MainActor` class (non-Sendable T) | ✗ compile error | ✓ | ✓ |
| `nonisolated` modifier | ✗ not supported | N/A | N/A |
| Boilerplate per property | medium | high | minimal |
| Modes (lazy / optional / weak) | separate wrappers | manual | single parameter |
| `@ObservationIgnored` / `@State` | manual | manual | automatic |

## SwiftSyntax Prebuilt Modules in Xcode

If you open the package in Xcode and see errors such as:

```
Module 'SwiftSyntax' was created for incompatible target aarch64-apple-macosx10.15
```

the cause is Xcode's prebuilt swift-syntax cache. Xcode downloads pre-compiled
SwiftSyntax binaries to speed up macro builds, but those binaries are compiled against
an older macOS deployment target and will be rejected when your toolchain builds macro
plugins targeting the host OS (e.g. `arm64-apple-macosx26.0` on macOS 26). The
command-line tools (`swift build`, `swift test`) compile SwiftSyntax from source and are
not affected.

The fix is to disable prebuilts so Xcode compiles SwiftSyntax from source alongside the
rest of the package:

```bash
defaults write com.apple.dt.Xcode IDEPackageEnablePrebuilts -bool NO
```

Quit and relaunch Xcode. The first build will be slower while SwiftSyntax compiles, but
subsequent builds use the standard derived-data cache and are fast. To re-enable
prebuilts after a future Xcode release that ships compatible binaries:

```bash
defaults delete com.apple.dt.Xcode IDEPackageEnablePrebuilts
```
