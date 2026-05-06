# Factory

A modern, container-based dependency injection system for Swift and SwiftUI. Compile-time safe, lightweight (~1k lines), zero-codegen.

This file is the quick orientation. For deep guidance on Factory APIs and idioms, invoke the `factory` skill in `.claude/skills/factory/SKILL.md`.

## Repository layout

- `Sources/FactoryKit/FactoryKit/` — the library (the import target is `FactoryKit`, not `Factory`).
  - `Factory.swift` — `Factory<T>` and `ParameterFactory<P, T>`
  - `Containers.swift` — `Container`, `SharedContainer`, `ManagedContainer`, `ContainerManager`, `AutoRegistering`
  - `Injections.swift` — `@Injected`, `@LazyInjected`, `@WeakLazyInjected`, `@DynamicInjected`, `@InjectedObject`, `@InjectedObservable`, `@InjectedContainer`, `@InjectedType`
  - `Scopes.swift` — `.unique`, `.cached`, `.shared`, `.singleton`, `.graph`, custom scopes
  - `Modifiers.swift` — `FactoryModifying`, scope/decorator/context/once/reset/preview
  - `Contexts.swift` — `FactoryContextType` (`.preview`, `.test`, `.debug`, `.simulator`, `.device`, `.arg`, `.args`)
  - `Dependency.swift` — global `dependency(\.keyPath)` / `dependency(\.keyPath, parameter:)`
  - `Resolver.swift` — opt-in typed `Resolving` mode (register/resolve by `T.Type`)
  - `Registrations.swift`, `Key.swift`, `Locking.swift`, `Globals.swift` — internals
- `Sources/FactoryKit/FactoryKit.docc/` — full DocC catalog (Basics, Advanced, Development, Additional). Source of truth for usage docs.
- `Sources/FactoryTesting/ContainerTrait.swift` — Swift Testing `.container` trait + `ContainerTrait<C>` for parallel-safe tests.
- `Tests/` — XCTest and Swift Testing suites (see for canonical usage examples).
- `FactoryDemo/` — sample iOS app exercising the API.
- `Package.swift` — Swift 6 language mode, strict concurrency, products `FactoryKit` and `FactoryTesting`.

## Core mental model

A `Factory<T>` is a transient value type returned from a computed property on a `Container`. Every call to that property builds a fresh `Factory` (cheap, like a SwiftUI `View`). The container — not the `Factory` — owns registrations and scope caches.

```swift
import FactoryKit

extension Container {
    var myService: Factory<MyServiceType> {
        self { MyService() }            // sugar for Factory(self) { ... }
    }
}
```

Resolution:

```swift
let svc = Container.shared.myService()  // service-locator style
let svc = container.myService()          // passed-container style

class VM {
    @Injected(\.myService) var service   // resolved at init
}
```

Mocking is just registering a new closure on the container's factory:

```swift
Container.shared.myService.register { MockService() }
```

## Most common patterns

Constructor injection from the container:

```swift
extension Container {
    var repo: Factory<Repo> { self { Repo(net: self.network()) } }
    var network: Factory<Networking> { self { LiveNetwork() }.singleton }
}
```

Scopes (modifiers on the Factory):

```swift
self { MyService() }           // unique (default — new every call)
self { MyService() }.cached    // cached on the container
self { MyService() }.shared    // weakly cached on the container
self { MyService() }.singleton // global, container-independent
self { MyService() }.graph     // cached for one resolution cycle
self { MyService() }.scope(.session)  // custom scope
```

Parameters require `ParameterFactory` (no property-wrapper form):

```swift
extension Container {
    var paramService: ParameterFactory<Int, ParamService> {
        self { ParamService(value: $0) }
    }
}
let s = Container.shared.paramService(42)
```

SwiftUI:

```swift
@InjectedObject(\.contentViewModel) var vm        // ObservableObject — uses StateObject
@InjectedObservable(\.contentViewModel) var vm    // @Observable (iOS 17+) — uses State
```

Contexts (auto-overrides for environments):

```swift
container.analytics
    .onTest    { MockAnalytics() }   // DEBUG-only
    .onPreview { MockAnalytics() }   // DEBUG-only
    .onDebug   { MockAnalytics() }   // DEBUG-only
    .onArg("mock1") { MockServiceN(1) }  // available at runtime
    .onSimulator { ... }
    .onDevice    { ... }
```

Cross-module wiring with `AutoRegistering`:

```swift
extension Container: @retroactive AutoRegistering {
    func autoRegister() {
        accountLoader.register { AccountLoader() }   // wired from the app target
    }
}
```

Optional / promised factories for modules where the impl lives elsewhere:

```swift
extension Container {
    var accountLoader: Factory<AccountLoading?> { promised() }
}
```

## Testing

Swift Testing — use `FactoryTesting`'s `.container` trait so each test gets a fresh, isolated `Container.shared` (works because `Container.shared` is `@TaskLocal`):

```swift
import Testing
import FactoryTesting

@Suite(.container)
struct MyTests {
    @Test func loaded() async {
        Container.shared.accountProvider.register { MockProvider(.sample) }
        let vm = Container.shared.someViewModel()
        await vm.load()
        #expect(vm.isLoaded)
    }
}
```

> Important: add `FactoryTesting` to the test target. Do **not** import `FactoryKit` into the test target — that creates duplicate factories.

XCTest — reset between tests (or push/pop):

```swift
override func setUp() {
    super.setUp()
    Container.shared.reset()         // wipes registrations + caches
    // or: Container.shared.manager.push() / .pop() in tearDown
}
```

Singletons survive container reset because they're global. Reset them explicitly:

```swift
Scope.singleton.reset()
Container.shared.someSingletonFactory.reset()
```

## Things to know when writing code in this repo

- The library import is `FactoryKit`, not `Factory` — `Factory` is the type name. Earlier 1.x/2.x users see migration notes in `Sources/FactoryKit/FactoryKit.docc/Additional/Migration.md`.
- The package uses Swift 6 language mode with strict concurrency. `Container.shared` is `@TaskLocal var`. Custom containers must follow the same pattern (see `Containers.md`).
- Don't store a `Factory` in a `lazy var` on the container — Factory holds a strong reference back to the container and you'll create a retain cycle.
- `.register { ... }` on a factory implicitly clears that factory's scope cache. Calling `.reset()` with no argument clears registrations *and* contexts — usually you want `.reset(.scope)`.
- Modifier order matters: the innermost (factory-defined) values win on each resolution. Use `.once()` or push setup into `autoRegister` if you need an external override to stick. See `Advanced/Modifiers.md`.
- Circular dependency detection runs in DEBUG only and will `fatalError` with a chain dump. Use `.manager.trace.toggle()` to log resolution graphs.
- `@MainActor`-isolated factories: annotate the computed property with `@MainActor`. Factory 3.0 no longer requires `@MainActor in` inside the closure (that was the 2.x form).

## Where to read next

- Quickstart: `Sources/FactoryKit/FactoryKit.docc/Basics/GettingStarted.md`
- Containers + lifecycle: `Basics/Containers.md`
- Scopes: `Basics/Scopes.md`
- Testing (Swift Testing + XCTest + UITest): `Development/Testing.md`
- SwiftUI integration: `Development/SwiftUI.md`, `Development/Previews.md`
- Multi-module wiring: `Advanced/Modules.md`, `Advanced/Optionals.md`
- Public DocC site: https://hmlongco.github.io/Factory/documentation/factorykit
