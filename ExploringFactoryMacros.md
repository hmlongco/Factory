# Exploring Factory Macros

*How `@Dependency` replaces property wrappers, cuts boilerplate, and makes Swift 6 concurrency happy*

---

Dependency injection in Swift has always involved a certain amount of ceremony. You define a protocol, write an implementation, register it with a container, and then wire it into every class that needs it. Factory makes that last step as clean as it can be with property wrappers, but Swift 6's strict concurrency checking has exposed a fundamental limitation that property wrappers simply cannot solve. That's the reason Factory Macros exist.

The `@Dependency` attached macro, shipped in the companion `FactoryMacros` library, takes a different approach. Instead of wrapping a stored property at runtime, it generates a plain stored property at compile time. No wrapper, no backing variable, no runtime overhead, and no fight with the Swift concurrency checker.

This article walks through what the macro does, all the modes it supports, and why it matters for real-world Swift 6 codebases.

---

## Why Property Wrappers Hit a Wall in Swift 6

Before getting into what `@Dependency` can do, it's worth understanding exactly why the old `@Injected` property wrapper runs into trouble.

Swift 6 requires that `@MainActor`-isolated classes are `Sendable`. That's reasonable: if a class is pinned to the main actor, the compiler can guarantee safe access. The problem is what that `Sendable` requirement ripples into. All `nonisolated` stored properties on a `Sendable` type must themselves be `Sendable`. A property wrapper like `@Injected` stores its resolved value in a `nonisolated` backing variable, so `Injected<T>` must be `Sendable`, which forces `T: Sendable`. If your service isn't `Sendable` (and many aren't), you get an error like this:

```
error: stored property '_service' of 'Sendable'-conforming main actor-isolated
       class 'MyViewModel' is nonisolated but has non-'Sendable' type
       'Injected<any MyServiceType>'
```

The obvious escape hatch, marking the property `nonisolated`, doesn't work either:

```
error: 'nonisolated' is not supported on properties with property wrappers
```

This isn't a bug that will be patched; it's a structural limitation of how property wrappers are implemented. The hidden mutable backing variable can't be made nonisolated without undermining the thread-safety guarantees the compiler is trying to enforce.

The `@Dependency` macro sidesteps both problems entirely. It generates a plain stored property, not a property-wrapper-backed one. That property inherits the enclosing type's actor isolation naturally, with no `Sendable` requirement imposed on the resolved type.

---

## Boilerplate Before and After

Beyond the concurrency story, the macro simply requires less typing. Consider a view model that depends on two services:

```swift
// Before: with @Injected
@MainActor @Observable final class HomeViewModel {
    @ObservationIgnored
    @Injected(\.movieRepository) var movieRepository: MovieRepositoryType
    @ObservationIgnored
    @Injected(\.analytics) var analytics: AnalyticServices

    func load() async -> [Movie] {
        analytics.log("loading")
        return await movieRepository.load()
    }
}
```

Each dependency requires two attributes: `@ObservationIgnored` to opt it out of the `@Observable` tracking machinery, and `@Injected(...)` to wire it in. With the macro:

```swift
// After: with @Dependency
@Dependency(\.movieRepository)
@Dependency(\.analytics)
@MainActor @Observable final class HomeViewModel {
    func load() async -> [Movie] {
        analytics.log("loading")
        return await movieRepository.load()
    }
}
```

The dependencies move to the class declaration site, where they're immediately visible rather than buried in the class body. The macro detects `@Observable` automatically and generates the `@ObservationIgnored` annotation for you. The class body contains only business logic.

For a class with five or six dependencies (common in real view models), the reduction is substantial.

---

## What the Macro Actually Generates

The macro is transparent about what it produces. For the default mode, `@Dependency(\.movieRepository)` prepended to a class expands to a single stored property:

```swift
internal var movieRepository = Container.shared.movieRepository()
```

That's it. No wrapper type, no getter/setter pair, no protocol conformance machinery. The property name and type are both derived from the key-path expression at compile time. This is also why there's no runtime overhead beyond the resolution call itself. There's no property wrapper access chain to traverse on every read.

---

## Dependency Modes

The macro's `mode` parameter covers the same ground that `@Injected`, `@LazyInjected`, `@WeakLazyInjected`, and `@DynamicInjected` each handled separately. One attribute, one parameter.

### Immediate (default)

Resolved once when the containing type is initialized. This is the right choice for the vast majority of dependencies.

```swift
@Dependency(\.myService)
final class SomeViewModel {
    // internal var myService = Container.shared.myService()
}
```

### Lazy

Resolved on first access and then cached. Available on classes and actors, but not structs (which don't support `lazy var`).

```swift
@Dependency(\.myService, mode: .lazy)
final class SomeViewModel {
    // internal lazy var myService = Container.shared.myService()
}
```

Lazy is useful when the dependency is expensive to create and not always needed. It avoids paying the initialization cost upfront.

### Optional

Wraps the resolved value in `Optional`, yielding a `T?` property. A pass-through overload in the macro prevents double-wrapping when the factory already returns an optional.

```swift
@Dependency(\.myService, mode: .optional)
final class SomeViewModel {
    // internal var myService: MyServiceType? = ...
}
```

### Weak

Holds a weak reference to the resolved instance. Useful when the consuming object shouldn't extend the lifetime of its dependency, for example when both are separately owned by a parent.

```swift
@Dependency(\.myService, mode: .weak)
final class SomeViewModel {
    // internal weak var myService = Container.shared.myService()
}
```

### Dynamic

Re-resolves from the container on every property access. This is the mode to reach for when you need the latest container state without recreating the consumer. Feature-flag-driven services are the canonical example.

```swift
@Dependency(\.myService, mode: .dynamic)
final class SomeViewModel {
    // @DynamicDependency internal var myService = Container.shared.myService()
}
```

The generated `@DynamicDependency` property wrapper captures the factory call as a deferred closure, so the container is queried fresh on every read. Note that `.dynamic` is not supported on SwiftUI `View` types; SwiftUI's `@State` handles that use case instead.

---

## Renaming Generated Properties

Sometimes the factory key path is verbose and a shorter local name is clearer at the call site. The `name:` parameter handles this:

```swift
@Dependency(\.movieRepository, name: "repo")
final class HomeViewModel {
    // internal var repo = Container.shared.movieRepository()
    func load() async {
        await repo.load()  // shorter name, same factory
    }
}
```

`name:` and `mode:` can be combined freely:

```swift
@Dependency(\.movieRepository, name: "repo", mode: .lazy)
@MainActor @Observable final class HomeViewModel { }
```

---

## Custom Containers

`@Dependency` isn't tied to the default `Container`. The container type is inferred from the key-path root, so custom `SharedContainer` subclasses work without any extra annotation:

```swift
@Dependency(\MyContainer.myService)
final class SomeService {
    // internal var myService = MyContainer.shared.myService()
}
```

---

## SwiftUI Views

When the macro is applied to a type conforming to `View`, it generates a `@State` property instead of a plain `var`. This is important: a plain `var` on a `View` struct would be recreated on every render pass. `@State` hands ownership to SwiftUI, ensuring the dependency is resolved exactly once and survives re-renders.

```swift
@Dependency(\.viewModel)
struct HomeView: View {
    // @State internal var viewModel = Container.shared.viewModel()
    var body: some View { ... }
}
```

The macro detects `View` conformance automatically. The `.lazy`, `.weak`, and `.dynamic` modes are not supported on views. Use the default mode and let SwiftUI's `@State` manage the lifecycle.

---

## Actor Isolation

The macro generates code that correctly inherits the enclosing type's actor isolation in all the common configurations.

For a `@MainActor` class, the generated property is `@MainActor`-isolated and the factory is called on the main actor with no extra annotation needed. For a `nonisolated` class (a pattern that's become more common with Swift 6.2's Approachable Concurrency), the macro generates a plain nonisolated stored property initialized from a nonisolated factory. The one constraint: a `nonisolated` consumer can't use an actor-isolated factory, for the same reason you can't call a `@MainActor` function from a `nonisolated` context.

Custom global actors work identically to `@MainActor`:

```swift
@Dependency(\.testActorService)
@TestActor @Observable final class TestActorViewModel { }
```

---

## Testing with @Dependency

The testing story is essentially unchanged from the property wrapper approach. Register mock factories before constructing the consumer, and the macro-generated immediate properties will pick them up at initialization time:

```swift
@Suite(.container)
struct MyTests {
    @Test func usesOverride() {
        Container.shared.myService.register { MockService() }
        let sut = MyViewModel()
        #expect(sut.myService is MockService)
    }
}
```

Dynamic mode is particularly convenient for tests that need to observe multiple registrations on a single live instance:

```swift
@Suite(.container)
struct DynamicTests {
    @Test func reflectsLateRegistration() {
        let sut = MyViewModel()
        #expect(sut.myService is MyService)          // default registration

        Container.shared.myService.register { MockService() }
        #expect(sut.myService is MockService)        // visible immediately
    }
}
```

The `.container` trait from `FactoryTesting` resets `Container.shared` between test runs, so registrations in one test never bleed into another regardless of which mode you're using.

---

## The Comparison at a Glance

|  | `@Injected` | Manual init | `@Dependency` macro |
|--|--|--|--|
| Nonisolated class | ✗ compile error | ✓ | ✓ |
| `@MainActor` class with non-`Sendable` T | ✗ compile error | ✓ | ✓ |
| `nonisolated` modifier on property | ✗ not supported | N/A | N/A |
| Boilerplate per property | medium | high | minimal |
| Modes | separate wrappers | manual | single parameter |
| `@ObservationIgnored` / `@State` | manual | manual | automatic |

---

## Closing Thoughts

The `@Dependency` macro is a natural evolution for Factory in a Swift 6 world. Property wrappers were the right tool for their era; attached macros are the right tool now. The generated code is straightforward: plain stored properties initialized from the container. You can inspect exactly what's produced by expanding the macro in Xcode.

For new code written against Swift 6 strict concurrency, `@Dependency` should be the default choice. For existing codebases, the migration is mechanical: replace each `@Injected` property with the equivalent `@Dependency` attribute at the class declaration, drop the now-redundant type annotation and `@ObservationIgnored`, and let the compiler tell you if anything needs adjustment.

The boilerplate savings are real, but the more durable benefit is the concurrency correctness. Code that compiles cleanly under Swift 6's strict mode is code you can trust.

---

*Factory and FactoryMacros are open source. You can find the source, documentation, and more at [github.com/hmlongco/Factory](https://github.com/hmlongco/Factory).*
