[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fhmlongco%2FFactory%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/hmlongco/Factory)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fhmlongco%2FFactory%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/hmlongco/Factory)

![](https://github.com/hmlongco/Factory/blob/main/Logo.png?raw=true)

A modern approach to Container-Based Dependency Injection for Swift and SwiftUI.

## Factory Version 3.2.0

Factory is strongly influenced by SwiftUI, and in my opinion is highly suited for that environment. Factory is...

- **Adaptable**: Factory doesn't tie you down to a single dependency injection strategy or technique.
- **Powerful**: Factory supports containers, scopes, passed parameters, contexts, decorators, unit tests, SwiftUI Previews, and much, much more.
- **Performant**: Little to no setup time is needed for the vast majority of your services, resolutions are extremely fast, and no compile-time scripts or build phases are needed.
- **Safe**: Factory is compile-time safe; a factory for a given type must exist or the code simply will not compile.
- **Concise**: Defining a registration usually takes just a single line of code. Same for resolution.
- **Flexible**: Working with UIKIt or SwiftUI? iOS or macOS? Using MVVM? MVP? Clean? VIPER? No problem. Factory works with all of these and more.
- **Documented**: Factory has extensive DocC documentation and examples covering its classes, methods, and use cases.
- **Lightweight**: With all of that Factory is slim and trim, under 1,000 lines of executable code.
- **Tested**: Unit tests with 100% code coverage helps ensure correct operation of registrations, resolutions, and scopes.
- **Testable**: Factory ensures your application's views and services are easily previewable and testable. 
- **Free**: Factory is free and open source under the MIT License.

Sound too good to be true? Let's take a look.

---

## A Simple Factory
 
Most container-based dependency injection systems require you to define in some way that a given service type is available for injection, and many require some sort of factory or mechanism that will provide a new instance of the service when needed.
 
 Factory is no exception. Here's a simple dependency registration that returns a service that conforms to `MyServiceType`.
 
```swift
extension Container {
    var myService: Factory<MyServiceType> { 
        self { MyService() }
    }
}
```

Unlike frameworks that require registering every single type up front, or SwiftUI, where defining a new environment variable requires creating a new EnvironmentKey and adding additional getters and setters, here we simply add a new `Factory` computed variable to the default container. When it's called our Factory is created, its closure is evaluated, and we get an instance of our dependency when we need it. 

*That `self { ... }` syntax is sugared shorthand for the original, more formal, and more explicit `Factory(self) { ... }` format. Both are equivalent and are covered in [Simplified Syntax](#simplified-syntax) below.*

Injecting an instance of our service is equally straightforward. Here's just one of the many ways Factory can be used.

```swift
@Observable
class ContentViewModel {
    @ObservationIgnored @Injected(\.myService) private var myService
    ...
}
```
This particular view model uses one of Factory's `@Injected` property wrappers to request the desired dependency. Similar to `@Environment` in SwiftUI, we provide the property wrapper with a keyPath to a factory of the desired type and it resolves that type the moment `ContentViewModel` is created.

And that's the core mechanism. In order to use the property wrapper you *must* define a factory within the specified container. That factory *must* return the desired type when asked. Fail to do either one and the code will simply not compile. As such, Factory is compile-time safe.

By the way, if you're concerned about building Factory's on the fly, don't be. Like SwiftUI Views, Factory structs and modifiers are lightweight and transitory value types. They're created inside computed variables **only** when they're needed and then immediately discarded once their purpose has been served.

For more examples of Factory definitions that define scopes, use constructor injection, and do parameter passing, see the [Registrations](https://hmlongco.github.io/Factory/documentation/factorykit/registrations) page.

## Other Factory Resolution Methods

Earlier we demonstrated how to use the `@Injected` property wrapper. But it's also possible to bypass the property wrapper and talk to the factory yourself.

```swift
@Observable
class ContentViewModel {
    private let myService = Container.shared.myService()
    private let eventLogger = Container.shared.eventLogger()
    ...
}
```
Just call the desired factory as a function and you'll get an instance of its managed dependency. It's that simple.

If you're into container-based dependency injection, note that you can simply pass a container to a view model and obtain an instance of your service directly from that container.
```swift
@Observable
class ContentViewModel {
    let service: MyServiceType
    init(container: Container) {
        service = container.myService()
    }
}
```
Or if you want to use a Composition Root structure, just use the container to provide the required dependencies to a constructor.

```swift
extension Container {
    var myRepository: Factory<MyRepositoryType> {
        self { MyRepository(service: self.networkService()) }
    }
    var networkService: Factory<Networking> {
        self { MyNetworkService() }
    }
}

@main
struct FactoryDemoApp: App {
    let viewModel = MyViewModel(repository: Container.shared.myRepository())
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView(viewModel: viewModel)
            }
        }
    }
}

```
Factory also has a set of global dependency resolution functions. This global function can be easily replaced should you want to minimize your codebase's apparent dependency on Factory.
```swift
final class NetworkService {
    let preferences: Preferences = dependency(\.preferences)
    lazy var service: Service = dependency(\.service, parameter: Mode.secret)
    ...
}
```

The bottom line is that Factory is *extremely* flexible and it doesn't tie you down to a specific dependency injection pattern or technique.

See [Resolutions](https://hmlongco.github.io/Factory/documentation/factorykit/resolutions) for more examples.

## Mocking

If we go back and look at our original view model code one might wonder why we've gone to all of this trouble? Why not simply say `let myService = MyService()` and be done with it? 

Or keep the container idea, but write something similar to this…

```swift
extension Container {
    static var myService: MyServiceType { MyService() }
}
```

Well, the primary benefit one gains from using a container-based dependency injection system is that we're able to change the behavior of the system as needed. Consider the following code:

```swift
struct ContentView: View {
    @State private var model = ContentViewModel()
    var body: some View {
        Text(model.text())
            .padding()
    }
}
```

Our ContentView uses our view model, which is assigned to a `@State` property. Great. But now we want to preview our code. How do we change the behavior of `ContentViewModel` so that its `MyService` dependency isn't making live API calls during development? 

It's easy. Just replace `MyService` with a mock that also conforms to `MyServiceType`.

```swift
#Preview {
    Container.shared.myService { MockService2() }
    ContentView()
}
```
Note the line in our preview code where we’re gone back to our container and registered a new closure on our factory. This function overrides the default factory closure.

Now when our preview is displayed `ContentView` creates a `ContentViewModel` which in turn has a dependency on `myService` using the `Injected` property wrapper. And when the wrapper asks the factory for an instance of `MyServiceType` it now gets a `MockService2` instead of the `MyService` type originally defined.

This is a powerful concept that lets us reach deep into a chain of dependencies and alter the behavior of a system as needed.

Note that Factory 3.2.0 added the new `callAsFunction` registration function that eliminated some of the boilerplate.
```swift
#Preview {
    // the old way
    let _ = Container.shared.myService.register { MockService2() }
    ContentView()
}
```
We'll use the new format going forward.

See the [Previews](https://hmlongco.github.io/Factory/documentation/factorykit/previews) documentation for more.

## Testing

The mocking concept can also be used when writing unit tests. Consider the following...

```swift
@Suite(.container) // note container trait
struct FactoryTests {

    @Test func testLoaded() async {
        Container.shared.accountProvider { MockProvider(accounts: .sampleAccounts) }
        let model = Container.shared.someViewModel()
        model.load()
        #expect(model.isLoaded)
    }

    @Test func testEmpty() async {
        Container.shared.accountProvider { MockProvider(accounts: []) }
        let model = Container.shared.someViewModel()
        model.load()
        #expect(model.isEmpty)
    }

    @Test func testErrors() async {
        Container.shared.accountProvider { MockProvider(error: .notFoundError) }
        let model = Container.shared.someViewModel()
        model.load()
        #expect(model.errorMessage == "Some Error")
    }
    
}
```

Again, Factory makes it easy to reach into a chain of dependencies and make specific changes to the system as needed. This makes testing loading states, empty states, and error conditions simple.


Swift Testing's test trait support also makes it possible to run all of our tests in parallel! 

The `.container` trait shown above provides a new, fresh instance of the main shared container to each one of the tests.

See the [Testing Documentation](https://hmlongco.github.io/Factory/documentation/factorykit/testing) for more.

## XCTest

Still using XCTest? Don't worry. Factory works there too.

```swift
final class FactoryCoreTests: XCTestCase {

    override func setUp() {
        super.setUp()
        Container.shared.reset()
    }
    
    func testLoaded() throws {
        Container.shared.accountProvider { MockProvider(accounts: .sampleAccounts) }
        let model = Container.shared.someViewModel()
        model.load()
        XCTAssertTrue(model.isLoaded)
    }
    
    // other tests
    
}
```

But we're not done yet. 

Factory has quite a few more tricks up its sleeve...

## Scope

If you've used Resolver or some other dependency injection system before then you've probably experienced the benefits and power of scopes.

And if not, the concept is easy to understand: Just how long should an instance of an object live?

You've no doubt stuffed an instance of a class into a variable and created a singleton at some point in your career. This is an example of a scope. A single instance is created and then used and shared by all of the methods and functions in the app.

This can be done in Factory just by adding a scope modifier.

```swift
extension Container {
    var networkService: Factory<NetworkProviding> { 
        self { NetworkProvider() }
            .singleton
    }
    var myService: Factory<MyServiceType> { 
        self { MyService() }
            .scope(.session)
    }
}
```
Now whenever someone requests an instance of `networkService` they'll get the same instance of the object as everyone else.

Note that the client neither knows nor cares about the scope. Nor should it. The client is simply given what it needs when it needs it. 

If no scope is specified the default scope is unique. A new instance of the service will be instantiated and returned every time one is requested from the factory.

Other common scopes are `cached` and `shared`. Cached items are persisted until the cache is reset, while shared items exist just as long as someone holds a strong reference to them. When the last reference goes away, the weakly held shared reference also goes away.

Factory has other scope types, plus the ability to add more of your own. See [Scopes](https://hmlongco.github.io/Factory/documentation/factorykit/scopes) for additional examples.

Scopes and scope management are powerful tools to have in your dependency injection arsenal.

## Simplified Syntax

You may have noticed in the previous example that Factory also provides a bit of syntactical sugar that lets us make our definitions more concise. We simply ask the enclosing container to make a properly bound Factory for us using `self.callAsFunction { ... }`.

```swift
extension Container {
    var sugared: Factory<MyServiceType> { 
        self { MyService() }
    }
    var formal: Factory<MyServiceType> { 
        Factory(self) { MyService() }
    }
}
```
Both definitions provide the same exact result. The sugared function is even inlined, so there's not even a performance difference between the two versions.

## Contexts

One powerful feature in Factory is contexts. Let's say that for logistical reasons whenever your application runs in debug mode you *never* want it to make calls to your application's analytics engine.

Easy. Just register an override for that particular context.

```swift
container.analytics.onDebug { 
    StubAnalyticsEngine()
}
```
There are other contexts for unit testing, for SwiftUI previews, and even when running **UITests** both in the simulator or when running an app on services like BrowserStack.

For a complete list, go to [Contexts](https://hmlongco.github.io/Factory/documentation/factorykit/contexts).

## Debugging

Factory can also help you debug your code. When running in DEBUG mode Factory allows you to trace the injection process and see every object instantiated or returned from a cache during a given resolution cycle.
```
0: Factory.Container.cycleDemo<CycleDemo> = F:105553131389696
1:     Factory.Container.aService<AServiceType> = F:105553119821680
2:         Factory.Container.implementsAB<AServiceType & BServiceType> = F:105553119821680
3:             Factory.Container.networkService<NetworkService> = F:105553119770688
1:     Factory.Container.bService<BServiceType> = F:105553119821680
2:         Factory.Container.implementsAB<AServiceType & BServiceType> = C:105553119821680
```
This can make it a lot easier to see the entire dependency tree for a given object or service.

See [Debugging](https://hmlongco.github.io/Factory/documentation/factorykit/debugging) for more on this and other features.

## Observation / Actor Isolation

Factory also works with Observation, `@MainActor` and actor isolation in Swift concurrency. Just annotate the Factory as needed.

```swift
// Observable view model isolated to @MainActor
@MainActor
@Observable
class ContentViewModel {
    @ObservationIgnored @Injected(\.myService) private var service
    ...
}

// Factory isolated to @MainActor
extension Container {
    @MainActor
    var contentViewModel: Factory<ContentViewModel> {
        self { ContentViewModel() }
    }
}

// View with injected view model
struct ContentView: View {
    @InjectedObservable(\.contentViewModel) var viewModel
    var body: some View {
        ...
    }
}
```
`InjectedObservable` was added to Factory 2.4.

See [SwiftUI](https://hmlongco.github.io/Factory/documentation/factorykit/swiftui) for more discussion.

## Nonisolated Classes

If you're using global MainActors but have nonisolated service classes that need dependencies of their own then you may not be able use the 
various "Injected" property wrappers due to an issue with Swift 6.2.

Factory has a global dependency resolution function that can be used in their place.

```swift
nonisolated final class NetworkService {
    let preferences: Preferences = dependency(\.preferences)
    lazy var service: Service = dependency(\.service, parameter: Mode.secret)
    ...
}
```
These functions can also be useful when you want to hide Factory and Factory Shared Containers from the rest of your code base. Should you
ever want to switch away from Factory, just expose your own `dependency` function with the same keyPaths.

One can also use them to pass parameters to Factory's, something the property wrappers don't allow.

## Factory Macros

`FactoryMacros` is an **unreleased** companion library that will ship alongside FactoryKit. It provides a `@Dependency` macro that generates injected stored properties automatically from a key-path expression, replacing hand-written `@Injected` declarations and surfacing a type's dependencies at its declaration site rather than buried in the body or initializer.

The macro expands at compile time into simple stored properties, avoiding the runtime overhead of property wrappers and their accessors.

The library code is in the **macros** branch if you want to experiment. Full documentation will accompany its release.

## Documentation

A single README file barely scratches the surface. Fortunately, Factory is thoroughly documented. 

Current DocC documentation can be found in the project as well as online on [GitHub Pages](https://hmlongco.github.io/Factory/documentation/factorykit).

## Demo Applications

Factory includes a test bed application, `FactoryDemo`, that's used to test basic functionality and ensure various features are working properly.

Factory 3.0 also has `MovieDemo`, a new TMDB movie browsing application that's been built to showcase how to use [Factory](https://github.com/hmlongco/Factory) and [Navigator](https://github.com/hmlongco/Navigator) in a modern, modular iOS application.

It can be obtained here: [MovieDemo](https://github.com/hmlongco/MovieDemo).

## Installation

Factory's primary import library is named `FactoryKit`. This is done in order to avoid SPM import conflicts between the library itself and the `Factory` object defined within the library.

Just add the Factory package to your project target, select the `FactoryKit` library when asked, and then import `FactoryKit` in your Swift files where needed.

```swift
import FactoryKit
```

If you're using Swift Testing you'll probably also want to also import the `FactoryTesting` library and add it to your test target. 

**Warning: Do not copy the FactoryKit library into the Test target. That can lead to duplicate factories and indeterminate behavior.**

```swift
// DO THIS
.testTarget(name: "MyAppTests", dependencies: [
    "MyApp",
    "FactoryTesting"
])

// DO NOT DO THIS
.testTarget(name: "MyAppTests", dependencies: [
    "MyApp",
    "FactoryKit", // BAD!!!
    "FactoryTesting"
])
```

With the sunsetting of CocoaPods, Factory 3.x supports the Swift Package Manager. Period.

> Note: If you still require CocoaPods support, drop down to Factory 2.5.3, or simply clone and embed Factory in your project directly.

## Migration

Factory 3.0.0 works with SPM, Xcode 26 (and 27) under Strict Concurrency guidelines, and with Swift Testing.

If you're a current Factory user you'll need to update your code and switch from importing `Factory` to importing `FactoryKit`. This avoids SPM naming conflicts between the import library name and the primary `Factory` object.

To do so, open your project in Xcode and...

1. Select `File > Packages > Update to Latest Package Versions`
2. Select `File > Packages > Reset Package Caches`
3. Go to your application target, remove the `Factory` library, and add the `FactoryKit` library
4. Go a global search and replace, renaming `import Factory` to `import FactoryKit`
5. Clean and build your project.

You may need to do the same for any other targets or modules that imported Factory.

One other significant change lies in MainActor Factory definitions. Factory 2.x required a definition that needed an additional `@MainActor` embedded in the Factory closure.

```swift
@MainActor
var contentViewModel: Factory<ContentViewModel> {
    self { @MainActor in ContentViewModel() }
}
```
Something that wasn't the most intuitive thing in the world. Factory 3.0 simplifies that.

```swift
@MainActor
var contentViewModel: Factory<ContentViewModel> {
    self { ContentViewModel() }
}
```
Keep in mind that resolution of `@MainActor` dependencies should occur *on* the `@MainActor` and not simply be awaited.

## Discussion Forum

Discussion and comments on Factory can be found in [Discussions](https://github.com/hmlongco/Factory/discussions). Go there if you have something to say or if you want to stay up to date.

## License

Factory is available under the MIT license. See the LICENSE file for more info.

## Sponsor Factory!

Many thanks to Mercedes-Benz, Süddeutsche Zeitung, and everyone else who's sponsored my open source work!

If you want to support my work on Factory, Navigator, and my other projects and articles, please consider a [GitHub Sponsorship](https://github.com/sponsors/hmlongco)! 

Many levels exist for increased support and even for mentorship and company training. 

Or you can just buy me a cup of coffee!

## Author

Factory is designed, implemented, documented, and maintained by [Michael Long](https://www.linkedin.com/in/hmlong/), a Lead iOS Software Engineer and a Top 1,000 Technology Writer on Medium.

* LinkedIn: [@hmlong](https://www.linkedin.com/in/hmlong/)
* Medium: [@michaellong](https://medium.com/@michaellong)
* BlueSky: [@hmlongco](https://bsky.app/profile/hmlongco.bsky.social)

Michael was also one of Google's [Open Source Peer Reward](https://opensource.googleblog.com/2021/09/announcing-latest-open-source-peer-bonus-winners.html) winners in 2021 for his work on Resolver.

## Contributors

Special thanks to Ákos Grabecz (agrabz) and Mahmood Tahir (tahirmt) for their recent contributions that ensure Factory works hand-in-hand with Swift Testing. 

## Additional Resources

* [Factory Documentation](https://hmlongco.github.io/Factory/documentation/factorykit)
* [MovieDemo: A modern, modular iOS application that uses Factory and Navigator](https://github.com/hmlongco/MovieDemo)
* [Factory 1.0 and Functional Dependency Injection](https://betterprogramming.pub/factory-and-functional-dependency-injection-2d0a38042d05)
* [Factory 1.0: Multiple Module Registration](https://betterprogramming.pub/factory-multiple-module-registration-f9d19721a31d?sk=a03d78484d8c351762306ff00a8be67c)
* [Resolver: A Swift Dependency Injection System](https://github.com/hmlongco/Resolver)
* [Inversion of Control Design Pattern ~ Wikipedia](https://en.wikipedia.org/wiki/Inversion_of_control)
* [Inversion of Control Containers and the Dependency Injection pattern ~ Martin Fowler](https://martinfowler.com/articles/injection.html)
* [Nuts and Bolts of Dependency Injection in Swift](https://cocoacasts.com/nuts-and-bolts-of-dependency-injection-in-swift/)
* [Dependency Injection in Swift](https://cocoacasts.com/dependency-injection-in-swift)
* [Swift 5.1 Takes Dependency Injection to the Next Level](https://medium.com/better-programming/taking-swift-dependency-injection-to-the-next-level-b71114c6a9c6)
* [Builder: A Declarative UIKit Library (Uses Factory in Demo)](https://github.com/hmlongco/Builder)
