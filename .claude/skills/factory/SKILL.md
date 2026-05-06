---
name: factory
description: In-depth guide to Factory, a container-based dependency injection system for Swift and SwiftUI. Use this skill any time the user is writing, reading, refactoring, debugging, or testing Swift code that uses Factory, FactoryKit, or FactoryTesting — including registrations on Container, the `@Injected`/`@LazyInjected`/`@WeakLazyInjected`/`@DynamicInjected`/`@InjectedObject`/`@InjectedObservable` property wrappers, `Factory<T>` and `ParameterFactory<P, T>`, scopes (`.unique`, `.cached`, `.shared`, `.singleton`, `.graph`), context modifiers (`.onTest`, `.onPreview`, `.onDebug`, `.onArg`, `.onSimulator`, `.onDevice`), `AutoRegistering`, custom containers, the `.container` Swift Testing trait, and cross-module wiring with `promised()`. Trigger when you see `Factory<`, `Container.shared`, `extension Container`, `@Injected(\.`, `import FactoryKit`, or when the user mentions "Factory DI", "FactoryKit", or compares against Resolver, Swinject, or Needle.
---

# Factory

Factory is a compile-time-safe, container-based DI system for Swift. It avoids codegen and runtime registration ceremony by making each registration a computed property on a container — if the property doesn't exist, the call site doesn't compile.

Use this skill as the reference when working with Factory code. The authoritative source is the DocC catalog at `Sources/FactoryKit/FactoryKit.docc/`; this skill condenses and organizes it.

## Module names

The package ships two products:

- `FactoryKit` — the library. Import this in app/library code: `import FactoryKit`.
- `FactoryTesting` — Swift Testing traits. Import only in test targets: `import FactoryTesting`.

The library is named `FactoryKit` (not `Factory`) so the import doesn't collide with the `Factory` type. Don't import `FactoryKit` into a test target that also imports `FactoryTesting` — that creates duplicate factories and indeterminate behavior.

## Core mental model

Three things to keep straight:

1. A `Factory<T>` is a *transient value* — a struct that's built fresh every time you read its computed property and discarded right after. Treat it like a SwiftUI `View`. Do not cache it in a `lazy var`; that creates a retain cycle on the container.
2. The *container* (not the Factory) owns registrations and scope caches. If the container deallocs, its registrations and caches go with it. Singletons are the exception — they're global.
3. Modifiers (`.singleton`, `.cached`, `.onTest`, etc.) re-apply on every read of the computed property. The innermost (factory-defined) value wins by default. See "The Factory wins" below.

## Defining factories

### Standard factory

```swift
import FactoryKit

extension Container {
    var myService: Factory<MyServiceType> {
        self { MyService() }            // sugar — ContainerManager.callAsFunction
    }
}
```

Equivalent long form:

```swift
extension Container {
    var myService: Factory<MyServiceType> {
        Factory(self) { MyService() }
    }
}
```

The sugar (`self { ... }`) is `@inlinable @inline(__always)`, so there's no perf cost.

### Constructor injection

Factories can pull their own dependencies from the same container:

```swift
extension Container {
    var repository: Factory<Repository> {
        self { Repository(network: self.network()) }
    }
    var network: Factory<Networking> {
        self { LiveNetwork() }.singleton
    }
}
```

### Parameters — `ParameterFactory<P, T>`

When a service needs a runtime value:

```swift
extension Container {
    var paramService: ParameterFactory<Int, ParamService> {
        self { ParamService(value: $0) }
    }
}

let svc = Container.shared.paramService(42)
```

Multi-parameter: use a tuple, dict, or struct.

```swift
var twoArg: ParameterFactory<(Int, String), Service> {
    self { (a, b) in Service(a: a, b: b) }
}
```

> `@Injected` does **not** work with `ParameterFactory` — there's no way to feed parameters into the property wrapper at init. Resolve from the container directly, or use the global `dependency(\.path, parameter: ...)`.

By default, scoping a `ParameterFactory` caches the *first* resolved value and returns it for all subsequent calls regardless of parameter. To cache per-parameter (parameter must be `Hashable`):

```swift
var paramService: ParameterFactory<Int, ParamService> {
    self { ParamService(value: $0) }.scopeOnParameters.cached
}
```

### Optional / promised factories (cross-module pattern)

When a protocol is declared in module P but the implementation lives in module B that P can't see, declare an optional factory in P and wire it from the app:

```swift
// Module P (protocol-only)
extension Container {
    var accountLoader: Factory<AccountLoading?> { promised() }
}

// App target — has visibility into both P and B
extension Container: @retroactive AutoRegistering {
    func autoRegister() {
        accountLoader.register { AccountLoader() }   // from module B
    }
}
```

`promised()` returns `nil` in release if no registration exists, and `fatalError`s in DEBUG to surface the wiring bug. Prefer `promised()` over `Factory<T?> { self { nil } }` and *never* over `Factory<T?> { self { fatalError() } }` — promise is the safe alternative to fatal-on-resolve.

A `ParameterFactory` overload of `promised()` exists for parameterized cross-module factories.

### Same-type / multiple instances

Factory keys are derived from the property name (via `#function`), so this works fine:

```swift
extension Container {
    var heading: Factory<String> { self { "Heading" } }
    var subhead: Factory<String> { self { "Subhead" } }
}
```

## Resolving

Five ways to get an instance, all equivalent for unscoped factories:

```swift
// 1. Service-locator on shared container
let svc = Container.shared.myService()

// 2. From a passed container instance
init(container: Container) { self.svc = container.myService() }

// 3. Property wrapper (resolves on init)
@Injected(\.myService) var svc

// 4. Lazy property wrapper (resolves on first access)
@LazyInjected(\.myService) var svc

// 5. Global function (handy in nonisolated classes)
let svc: MyServiceType = dependency(\.myService)
let p   = dependency(\.paramService, parameter: 42)
```

`callAsFunction()` is the sugar; the explicit form is `myService.resolve()`.

## Property wrappers

| Wrapper | Resolves | Notes |
|---|---|---|
| `@Injected(\.x)` | At init | Eager. Standard choice. |
| `@LazyInjected(\.x)` | First access | Use when the dep is heavy or might not be needed. Safe for breaking circular deps. |
| `@WeakLazyInjected(\.x)` | First access | Holds weakly. Use for delegate/parent refs to avoid retain cycles. Wrapped value is `T?`. |
| `@DynamicInjected(\.x)` | Every access | Re-resolves the factory each time the property is read. If the dep is stateful, give it a `.cached`/`.singleton` scope or you'll get a fresh instance per access. |
| `@InjectedObject(\.x)` | At init | SwiftUI only. Wraps `StateObject<T: ObservableObject>`. View owns the object. |
| `@InjectedObservable(\.x)` | First access | iOS 17+. For `@Observable` types. Backed by `@State`; thunked so it's resolved once per view lifetime. |
| `@InjectedContainer` / `@InjectedContainer(MyContainer.self)` | At init | Inject a container reference. |
| `@InjectedType` | At init | Type-only resolution; requires a `Resolving` container (see Resolver mode). Optional `T?`. |

All wrappers accept either `\.x` (default `Container`) or `\CustomContainer.x`.

The projected value of `@Injected`/`@LazyInjected`/`@WeakLazyInjected` exposes `.factory`, `.resolve(reset:)`, and (for the lazy ones) `.resolvedOrNil()`.

```swift
deinit { $myService.resolvedOrNil()?.cleanup() }    // doesn't force resolution
```

When using `@Observable` (Observation framework), Factory's wrappers must be marked `@ObservationIgnored`:

```swift
@MainActor @Observable
class ContentViewModel {
    @ObservationIgnored @Injected(\.myService) private var service
    var results: Results = .empty
}
```

## Scopes

Scope = lifetime of resolved instances.

| Scope | Behavior | Reset by |
|---|---|---|
| `.unique` (default) | New instance every resolve | n/a |
| `.cached` | One per container, until cache reset | `container.manager.reset(scope: .cached)` |
| `.shared` | Weak ref per container; lives only while someone holds strong ref | release strong refs |
| `.singleton` | One globally — *not* tied to any container | `Scope.singleton.reset()` |
| `.graph` | One per resolution cycle | automatic at cycle end |
| `.scope(.custom)` | User-defined `Cached()` instance | `container.manager.reset(scope: .custom)` |

Apply with modifier syntax:

```swift
self { MyService() }.cached
self { MyService() }.singleton
self { Reachability() }.shared.decorator { print("created \($0)") }
```

### `.graph` — single-resolution-cycle caching

Use when one concrete type implements multiple protocols and you want a single instance shared across the protocol-typed factories during one resolve:

```swift
extension Container {
    var consumer:  Factory<Consumer>           { self { Consumer() } }
    var idProvider: Factory<IDProviding>       { self { commonImpl() } }
    var valueProvider: Factory<ValueProviding> { self { commonImpl() } }
    private var commonImpl: Factory<IDProviding & ValueProviding> {
        self { CommonImpl() }.graph
    }
}
```

Resolving `consumer()` will inject the *same* `CommonImpl` into both `idProvider` and `valueProvider`. Resolving the wrappers separately (e.g. via `@Injected` in two properties on a hand-constructed `Consumer`) starts two cycles and gets two instances. The graph requires a single root resolve.

### Custom scopes

```swift
extension Scope {
    static let session = Cached()
}

extension Container {
    var authenticatedUser: Factory<User> {
        self { User() }.scope(.session)
    }
}

func logout() {
    Container.shared.manager.reset(scope: .session)
}
```

> Define custom scopes with `let`, not `static var` — the latter raises Swift concurrency warnings.

### Time to live

```swift
self { AuthSession() }.scope(.session).timeToLive(60 * 20)   // 20 min
```

The cached value is discarded on the next resolve after the TTL expires. A successful resolve before expiry refreshes the timestamp.

### Default scope per container

```swift
extension Container: @retroactive AutoRegistering {
    func autoRegister() {
        manager.defaultScope = .cached     // any unscoped factory becomes cached
    }
}
```

### Singleton caveats

- Singletons survive `Container.shared.reset()` because they're global.
- `.register { ... }` on a singleton normally clears its cache. Inside an `autoRegister` block this clearing is suppressed (otherwise multi-container apps would defeat the singleton).
- For test isolation under Swift Testing, the `.container` trait wraps `Scope.$singleton.withValue(Scope.singleton.clone())` so singletons are isolated per test.

## Containers

### The default `Container`

```swift
public final class Container: SharedContainer, @unchecked Sendable {
    @TaskLocal public static var shared = Container()
    public let manager: ContainerManager = ContainerManager()
    public init() {}
}
```

`Container.shared` is `@TaskLocal`. That's what makes parallel Swift Testing work — `TaskLocal.withValue(...)` swaps the shared container for the duration of a task.

### Custom containers

```swift
public final class PaymentsContainer: SharedContainer {
    @TaskLocal public static var shared = PaymentsContainer()
    public let manager = ContainerManager()
}

extension PaymentsContainer {
    var processor: Factory<PaymentProcessing> { self { Stripe() }.singleton }
}
```

Rules:

- `final class`
- conforms to `SharedContainer` (which extends `ManagedContainer`)
- `@TaskLocal public static var shared`
- public `let manager = ContainerManager()`

Use `\CustomContainer.x` keypaths to inject from it: `@Injected(\PaymentsContainer.processor)`.

You can also extend `SharedContainer` itself to expose a factory on every container type:

```swift
extension SharedContainer {
    var common: Factory<Common> { self { Common() } }
}
```

### Reaching across containers

Just spell out the path:

```swift
extension PaymentsContainer {
    var something: Factory<Something> {
        self { Something(net: Container.shared.network()) }
    }
}
```

### `AutoRegistering`

`autoRegister()` runs once per container instance, before the first factory on that container resolves. Use it to set up overrides, contexts, default scope, cross-module wiring.

```swift
extension Container: @retroactive AutoRegistering {
    public func autoRegister() {
        accountLoader.register { AccountLoader() }
        myService.onArg("mock1") { MockServiceN(1) }
        manager.defaultScope = .cached
    }
}
```

The `@retroactive` is required (Swift 6) since `AutoRegistering` and `Container` come from the same imported module — it silences the conformance warning.

`reset(options: .all)` re-arms the auto-register flag, so `autoRegister()` runs again after a full reset.

### Reset / push / pop

```swift
container.myService.reset()                     // single factory: registration + scope
container.manager.reset()                       // everything (== container.reset())
container.manager.reset(options: .registration) // factories only, keep caches
container.manager.reset(options: .scope)        // caches only, keep registrations
container.manager.reset(options: .context)      // contexts only
container.manager.reset(scope: .cached)         // one specific scope cache

container.manager.push()    // snapshot
container.manager.pop()     // restore most recent snapshot
```

`reset()` with no args clears *everything* including contexts. When you only want to clear caches after changing a context, use `.reset(.scope)`.

## Modifiers and ordering — "the factory wins"

Modifiers are re-applied every time the computed property runs. The internal definition is applied *last*, so it wins.

```swift
extension Container {
    var myService: Factory<MyService> {
        self { MyService() }
            .singleton
            .onTest { MockAnalytics() }    // baked-in onTest
    }
}

// Later, in a test, this looks like it should override:
Container.shared.myService.onTest { NullAnalytics() }
let svc = Container.shared.myService()    // → MockAnalytics, not Null
```

Why: reading `myService` rebuilds the Factory and re-applies `.onTest { MockAnalytics() }` on top of your override.

Three ways to deal with it:

1. **Don't bake mutable concerns into the Factory definition.** Move contexts to `autoRegister()`.

```swift
extension Container {
    var myService: Factory<MyService> { self { MyService() }.singleton }
}
extension Container: @retroactive AutoRegistering {
    func autoRegister() {
        #if DEBUG
        myService.onTest { MockAnalytics() }
        #endif
    }
}
```

2. **Chain at the call site:** `Container.shared.myService.onTest { Null() }()` — but you'd have to do this everywhere.

3. **`.once()`** — anything *before* `.once()` only applies on the first construction:

```swift
self { MyService() }
    .singleton
    .onTest { MockAnalytics() }
    .once()
```

Now external `.onTest { ... }` calls stick. `.once()` is the escape hatch; rule of thumb is "prefer option 1".

When you change a context on a scoped factory after first resolution, you must also clear its cached instance:

```swift
Container.shared.myService.onTest { NullAnalytics() }.reset(.scope)
```

## Contexts

A *context* is a runtime condition that selects a registration override. Defined contexts:

| Context | When | Available in Release? |
|---|---|---|
| `.arg("x")` | `ProcessInfo.arguments` contains `"x"` *or* `FactoryContext.setArg("x", forKey:)` was called | Yes |
| `.args(["x", "y"])` | any of the listed args | Yes |
| `.preview` | Xcode SwiftUI Previews | DEBUG only |
| `.test` | XCTest / Swift Testing process | DEBUG only |
| `.debug` | DEBUG build | DEBUG only |
| `.simulator` | running in simulator | Yes |
| `.device` | running on device | Yes |

Shortcuts: `.onArg(_:)`, `.onArgs(_:)`, `.onPreview`, `.onTest`, `.onDebug`, `.onSimulator`, `.onDevice`.

```swift
container.analytics
    .onTest    { MockAnalytics() }
    .onPreview { MockAnalytics() }
    .onArg("mock1") { MockServiceN(1) }
```

### Precedence (highest → lowest)

1. `arg` / `args`
2. `preview` *(DEBUG only)*
3. `test` *(DEBUG only)*
4. `simulator`
5. `device`
6. `debug` *(DEBUG only)*
7. registered factory (`.register { ... }`)
8. original factory closure

### Runtime args

```swift
FactoryContext.setArg("dark", forKey: "theme")
FactoryContext.removeArg(forKey: "theme")

theme
    .onArg("light") { LightTheme() }
    .onArg("dark")  { DarkTheme()  }
```

## SwiftUI

### View models

If the VM uses `@Injected` internally, just `@StateObject`-construct it normally:

```swift
struct ContentView: View {
    @StateObject private var vm = ContentViewModel()    // VM injects its own deps
}
```

If you want the container to construct the VM (e.g. constructor injection of services into the VM), use `@InjectedObject`:

```swift
extension Container {
    var contentViewModel: Factory<ContentViewModel> {
        self { ContentViewModel(service: self.myService()) }
    }
}

struct ContentView: View {
    @InjectedObject(\.contentViewModel) private var vm
}
```

`@InjectedObject` wraps a `StateObject` — the view owns the VM's lifecycle.

### Observation (`@Observable`, iOS 17+)

```swift
@MainActor @Observable
class ContentViewModel {
    @ObservationIgnored @Injected(\.myService) private var service
    var results: Results = .empty
}

extension Container {
    @MainActor
    var contentViewModel: Factory<ContentViewModel> { self { ContentViewModel() } }
}

struct ContentView: View {
    @InjectedObservable(\.contentViewModel) var vm
}
```

`@InjectedObservable` is backed by `@State<ThunkedValue<T>>`; the dep is created lazily on first read of `wrappedValue`, then memoized for the view's lifetime. Its projected value is a `Binding<T>` (read-only setter).

In Factory 3.0, a `@MainActor` factory only needs the annotation on the property — *not* on the closure. (2.x required `self { @MainActor in ... }`; that form is no longer needed.)

### Previews

```swift
#Preview {
    Container.shared.myService.preview { MockServiceN(4) }
    ContentView()
}
```

`.preview { ... }` wraps `register` and returns `EmptyView`, so `let _ =` is unnecessary. For multiple registrations:

```swift
#Preview {
    Container.preview {
        $0.myService.register { MockServiceN(4) }
        $0.anotherService.register { MockAnother() }
    }
    ContentView()
}
```

A common pattern is a `setupMocks()` extension shared across previews and tests:

```swift
extension Container {
    func setupMocks() {
        myService.register { MockServiceN(4) }
        sharedService.register { MockShared() }
    }
}
```

## Testing

### Swift Testing (preferred — supports parallel execution)

Add `FactoryTesting` to the test target. Use the `.container` trait:

```swift
import Testing
import FactoryTesting

@Suite(.container)
struct AccountTests {
    @Test func loaded() async {
        Container.shared.accountProvider.register { MockProvider(.sample) }
        let vm = Container.shared.accountsViewModel()
        await vm.load()
        #expect(vm.isLoaded)
    }

    @Test(.container, arguments: Parameters.allCases)
    func parameterized(p: Parameters) async {
        Container.shared.someService.register { MockService(parameter: p) }
        #expect(Container.shared.someService().parameter == p)
    }
}
```

Each test gets:

- a fresh `Container()` set as `Container.shared` for that task (via `TaskLocal.withValue`)
- a cloned singleton scope (via `Scope.$singleton.withValue(Scope.singleton.clone())`)

Tests run in parallel without stomping on each other.

The trait can take a transforming closure for setup right next to the trait:

```swift
@Test(.container {
    $0.someService.register { ErrorService() }
    await $0.mainActorService.register { MockMainActor() }   // await for actor-isolated factories
}) func t() async { ... }
```

### Custom container traits

```swift
public final class CustomContainer: SharedContainer {
    @TaskLocal public static var shared = CustomContainer()
    public let manager = ContainerManager()
}

extension Trait where Self == ContainerTrait<CustomContainer> {
    public static var customContainer: ContainerTrait<CustomContainer> {
        .init(shared: CustomContainer.$shared, container: .init())
    }
}

@Test(.customContainer) func t() async { ... }
@Test(.container, .customContainer) func t() async { ... }   // multiple
```

### XCTest

No TaskLocal magic — tests don't run in parallel by default with XCTest's classic scheduler. Manage state with reset or push/pop:

```swift
final class AccountTests: XCTestCase {
    override func setUp() {
        super.setUp()
        Container.shared.manager.push()
        Container.shared.setupMocks()
    }
    override func tearDown() {
        Container.shared.manager.pop()
        super.tearDown()
    }

    func testLoaded() async {
        Container.shared.accountLoading.register { MockNoAccounts() }
        let vm = Container.shared.accountsViewModel()
        await vm.load()
        XCTAssertTrue(vm.isEmpty)
    }
}
```

Or with an injected container:

```swift
final class AccountTests: XCTestCase {
    var container: Container!
    override func setUp() { container = Container(); container.setupMocks() }

    func test() {
        container.someService.register { MockService() }
        let vm = AccountsViewModel(container: container)
        ...
    }
}
```

If any dep is a `.singleton`, container injection alone isn't enough — singletons are global. Use `.container` trait or `Scope.singleton.reset()`.

### UI testing

Pass a launch arg, react via context:

```swift
// UI test
let app = XCUIApplication()
app.launchArguments.append("mock1")
app.launch()

// App
extension Container: @retroactive AutoRegistering {
    public func autoRegister() {
        #if DEBUG
        myServiceType.onArg("mock1") { MockServiceN(1) }
        #endif
    }
}
```

## Cross-module wiring

The recurring problem: protocol in module P, impl in module B, consumer in module A — A and B can't see each other.

Solution: P (or a thin `Services` module above P) declares the Factory; the app target wires the impl. Three flavors:

```swift
// 1. Optional via promised() — preferred
extension Container {
    public var loader: Factory<AccountLoading?> { promised() }
}

// 2. Optional with explicit nil
extension Container {
    public var loader: Factory<AccountLoading?> { self { nil } }
}

// 3. Optional with fatalError — fail-fast in dev, but ships crashes
extension Container {
    public var loader: Factory<AccountLoading?> { self { fatalError() } }
}
```

Use `promised()` unless you have a reason. It crashes in DEBUG (developer notices immediately), returns `nil` in release (feature degrades, app survives).

App target wires it:

```swift
import ModuleP
import ModuleA
import ModuleB

extension Container: @retroactive AutoRegistering {
    func autoRegister() {
        loader.register { AccountLoader() }
    }
}
```

If the protocol module is in the same target as the impl, the simpler "public protocol + public Factory + private impl" pattern is fine — no nullable needed.

For tagged groups of dependencies (Factory has no built-in tag system), maintain a `KeyPath` array:

```swift
extension Container {
    static var processors: [KeyPath<Container, Factory<Processor>>] = [
        \.processor1, \.processor2,
    ]
    func processors() -> [Processor] {
        Container.processors.map { self[keyPath: $0]() }
    }
}
```

## Concurrency

- The package builds under Swift 6 with strict concurrency.
- `Container.shared` is `@TaskLocal var`. Reading it across a Task suspension point is fine; writing it directly isn't supported (and as of 2.2 the default `Container.shared` can't be reassigned). Use `Container.$shared.withValue(...)` to set scoped values.
- For an actor-isolated dep, annotate the *Factory property*:

```swift
extension Container {
    @MainActor var vm: Factory<ContentViewModel> { self { ContentViewModel() } }
}
```

Don't put `@MainActor` inside the closure as in 2.x — 3.0 simplified that.

- For `nonisolated` consumers under Swift 6.2 where the property wrappers misbehave, use the global `dependency` function:

```swift
nonisolated final class NetworkService: Sendable {
    let prefs: Preferences = dependency(\.preferences)
    lazy var svc: Service = dependency(\.service, parameter: Mode.secret)
}
```

This is also useful when you want to wrap Factory behind your own seam — `dependency` keypaths can be rewritten to a different DI system later.

## Functional injection

Factories can return closures, not just objects. This sidesteps protocol-based mocking entirely for one-method services.

```swift
typealias AccountProviding = () async throws -> [Account]

extension Container {
    var accountProvider: Factory<AccountProviding> {
        self {{ try await Network.get(path: "/accounts") }}     // double braces!
    }
}

class AccountVM {
    @Injected(\.accountProvider) var provide
    @MainActor func load() async {
        accounts = (try? await provide()) ?? []
    }
}

// In tests
Container.shared.accountProvider.register {{ Account.mocks }}
Container.shared.accountProvider.register {{ throw APIError.network }}
```

The double braces are unavoidable: the outer braces are the factory closure, the inner braces are the closure being returned.

## Debugging

### Resolution trace

```swift
Container.shared.manager.trace.toggle()
let svc = Container.shared.someRoot()
```

Output:

```
0: FactoryKit.Container.cycleDemo<CycleDemo> = N:1055...696
1:     FactoryKit.Container.aService<AServiceType> = N:1055...680
2:         FactoryKit.Container.implementsAB<AServiceType & BServiceType> = N:1055...680
3:             FactoryKit.Container.networkService<NetworkService> = N:1055...688
1:     FactoryKit.Container.bService<BServiceType> = N:1055...680
2:         FactoryKit.Container.implementsAB<AServiceType & BServiceType> = C:1055...680
```

`N:` = newly created. `C:` = pulled from cache. The integer is the depth in the resolution cycle.

Trace is global (covers all containers). Custom logger:

```swift
Container.shared.manager.logger = { msg in MyLogger.debug("Factory: \(msg)") }
```

Trace is DEBUG-only.

### Circular dependency detection

DEBUG-only. If A → B → C → A, Factory hits a `fatalError` with the chain. To investigate, turn on trace before resolving and read the depth indentation. Common fix: switch one of the wrappers to `@LazyInjected` or `@WeakLazyInjected`, or — better — extract a third type that the cycle's two endpoints both depend on.

Disable detection:

```swift
Container.shared.manager.circularDependencyTesting = false
```

### Decorators

Run code on every resolution (cached or fresh):

```swift
self { ParentChildService() }
    .decorator { instance in instance.child.parent = instance }

self { Service() }
    .decorator { (instance, isNew) in if isNew { logger.log(instance) } }
```

Container-wide decorator (sees every dep resolved by the container):

```swift
Container.shared.decorator { resolved in print("resolved: \(type(of: resolved))") }
```

## Resolver mode (typed registration)

Opt-in `Resolving` protocol gives you Resolver-style runtime register/resolve by `T.Type`:

```swift
extension Container: Resolving {}

Container.shared.register { MyService() as MyServiceType }
let svc: MyServiceType? = Container.shared.resolve()
```

This is provided for migration from Resolver and isn't the recommended idiom. Stick with keypaths — they're compile-time safe.

## Common gotchas (checklist)

When debugging Factory code, walk this list:

- Did you import `FactoryKit` (not `Factory`)? In the test target, did you import `FactoryTesting` instead?
- Does the registration live on the correct container? `@Injected(\.x)` looks at `Container.shared`; for a custom container use `@Injected(\CustomContainer.x)`.
- Is the override unexpectedly losing? If the Factory definition bakes in `.onTest`/`.singleton` and you're trying to override at a call site, re-read "the factory wins" — move the override to `autoRegister()`, or add `.once()`, or chain at the resolve site.
- Did you `register` on a singleton at runtime and not see the change? `register` clears scope normally, but inside `autoRegister` it doesn't (singletons must survive container instantiation).
- Did `reset()` wipe more than you wanted? `reset()` ≡ `reset(options: .all)` — clears registrations, caches, *and* contexts. Use `reset(.scope)` after a context change.
- `@MainActor` warning on a Factory? Annotate the computed property with `@MainActor` (3.0). Do *not* add `@MainActor in` inside the closure (that was 2.x).
- `lazy var` Factory on a custom container → retain cycle. Use a computed property.
- Test bleed between Swift Testing tests? Use the `.container` trait. Make sure your custom container's `shared` is `@TaskLocal`.
- Singleton not reset between tests? Singletons are global. Use `.container` trait (it clones the singleton scope) or call `Scope.singleton.reset()` explicitly.
- `ParameterFactory` cached but parameter ignored? Default scope behavior caches the first resolved value. Add `.scopeOnParameters` (P must be `Hashable`).
- Cross-module wire missing in production? Prefer `promised()` over `fatalError()` factories — degrades gracefully.
- Optional `@Injected(\.x)` for a `Factory<T?>`? Works directly — there's no `@OptionalInjected`. Just spell the property type as `T?` (or let inference handle it).

## Where each topic is documented in the package

| Topic | File |
|---|---|
| Quickstart | `Sources/FactoryKit/FactoryKit.docc/Basics/GettingStarted.md` |
| Containers, lifecycle, AutoRegistering | `Basics/Containers.md` |
| Registration patterns | `Basics/Registrations.md` |
| Resolution patterns | `Basics/Resolutions.md` |
| Scopes (incl. graph, TTL, scopeOnParameters) | `Basics/Scopes.md` |
| SwiftUI integration | `Development/SwiftUI.md` |
| Previews | `Development/Previews.md` |
| Testing (Swift Testing + XCTest + UITest) | `Development/Testing.md` |
| Contexts | `Development/Contexts.md` |
| Resolution trace + debugging | `Development/Debugging.md` |
| Resolution cycles + graph scope | `Development/Chains.md`, `Advanced/Cycle.md` |
| Modifier ordering, `.once()` | `Advanced/Modifiers.md` |
| Multi-module wiring | `Advanced/Modules.md` |
| Optionals + `promised()` | `Advanced/Optionals.md` |
| Functional injection | `Advanced/Functional.md` |
| Tagging pattern | `Advanced/Tags.md` |
| Design rationale (why 1.x → 2.x → 3.x) | `Advanced/Design.md`, `Additional/Migration.md` |
