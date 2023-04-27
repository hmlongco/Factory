![](https://github.com/hmlongco/Factory/blob/main/Logo.png?raw=true)

A new approach to Container-Based Dependency Injection for Swift and SwiftUI.

## Factory 2.1

Factory is strongly influenced by SwiftUI, and in my opinion is highly suited for use in that environment. Factory is...

- **Adaptable**: Factory doesn't tie you down to a single dependency injection strategy or technique.
- **Powerful**: Factory supports containers, scopes, passed parameters, contexts, decorators, unit tests, SwiftUI Previews, and much, much more.
- **Performant**: Little to no setup time is needed for the vast majority of your services, resolutions are extremely fast, and no compile-time scripts or build phases are needed.
- **Safe**: Factory is compile-time safe; a factory for a given type must exist or the code simply will not compile.
- **Concise**: Defining a registration usually takes just a single line of code. Same for resolution.
- **Flexible**: Working with UIKIt or SwiftUI? iOS or macOS? Using MVVM? MVP? Clean? VIPER? No problem. Factory works with all of these and more.
- **Documented**: Factory 2.0 has extensive DocC documentation and examples covering its classes, methods, and use cases.
- **Lightweight**: With all of that Factory is slim and trim, under 800 lines of executable code.
- **Tested**: Unit tests with 100% code coverage helps ensure correct operation of registrations, resolutions, and scopes.
- **Free**: Factory is free and open source under the MIT License.

Sound too good to be true? Let's take a look.
  
 ## A Simple Example
 
Most container-based dependency injection systems require you to define in some way that a given service type is available for injection and many require some sort of factory or mechanism that will provide a new instance of the service when needed.
 
 Factory is no exception. Here's a simple dependency registration that returns a service that conforms to `MyServiceType`.
 
```swift
extension Container {
    var myService: Factory<MyServiceType> { 
        Factory(self) { MyService() }
    }
}
```

Unlike Resolver which often requires defining a plethora of nested registration functions, or SwiftUI, where defining a new environment variable requires creating a new EnvironmentKey and adding additional getters and setters, here we simply add a new `Factory` computed variable to the default container. When it's called our Factory is created, its closure is evaluated, and we get an instance of our dependency when we need it. 

Injecting an instance of our service is equally straightforward. Here's just one of the many ways Factory can be used.

```swift
class ContentViewModel: ObservableObject {
    @Injected(\.myService) private var myService
    ...
}
```
This particular view model uses one of Factory's `@Injected` property wrappers to request the desired dependency. Similar to `@Environment` in SwiftUI, we provide the property wrapper with a keyPath to a factory of the desired type and it resolves that type the moment `ContentViewModel` is created.

And that's the core mechanism. In order to use the property wrapper you *must* define a factory within the specified container. That factory *must* return the desired type when asked. Fail to do either one and the code will simply not compile. As such, Factory is compile-time safe.

By the way, if you're concerned about building Factory's on the fly, don't be. Like SwiftUI Views, Factory structs and modifiers are lightweight and transitory value types. They're created inside computed variables **only** when they're needed and then immediately discarded once their purpose has been served.

For more examples of Factory definitions that define scopes, use constructor injection, and do parameter passing, see the [Registrations](https://hmlongco.github.io/Factory/documentation/factory/registrations) page.

## Resolving Factories

Earlier we demonstrated how to use the ``Injected`` property wrapper. But it's also possible to bypass the property wrapper and talk to the factory yourself.

```swift
class ContentViewModel: ObservableObject {
    private let myService = Container.shared.myService()
    private let eventLogger = Container.shared.eventLogger()
    ...
}
```
Just call the desired factory as a function and you'll get an instance of its managed dependency. It's that simple.

If you're into container-based dependency injection, note that you can also pass an instance of a container to a view model and obtain an instance of your service directly from that container.
```swift
class ContentViewModel: ObservableObject {
    let service: MyServiceType
    init(container: Container) {
        service = container.service()
    }
}
```
Or if you want to use a Composition Root structure, just use the container to provide the required dependencies to a constructor.

```swift
extension Container {
    var myRepository: Factory<MyRepositoryType> {
        Factory(self) { MyRepository(service: self.networkService()) }
    }
    var networkService: Factory<Networking> {
        Factory(self) { MyNetworkService() }
    }
}

@main
struct FactoryDemoApp: App {
    let viewModel = MyViewModel(repository: Container.shared.myRepository())
    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView(viewModel: viewModel)
            }
        }
    }
}

```
Factory is flexible, and it doesn't tie you down to a specific dependency injection pattern or technique.

See [Resolutions](https://hmlongco.github.io/Factory/documentation/factory/resolutions) for more examples.

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
    @StateObject var model = ContentViewModel()
    var body: some View {
        Text(model.text())
            .padding()
    }
}
```

Our ContentView uses our view model, which is assigned to a StateObject. Great. But now we want to preview our code. How do we change the behavior of `ContentViewModel` so that its `MyService` dependency isn't making live API calls during development? 

It's easy. Just replace `MyService` with a mock that also conforms to `MyServiceType`.

```swift
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let _ = Container.myService.register { MockService2() }
        ContentView()
    }
}
```

Note the line in our preview code where we’re gone back to our container and registered a new closure on our factory. This function overrides the default factory closure.

Now when our preview is displayed `ContentView` creates a `ContentViewModel` which in turn has a dependency on `myService` using the `Injected` property wrapper. And when the wrapper asks the factory for an instance of `MyServiceType` it now gets a `MockService2` instead of the `MyService` type originally defined.

This is a powerful concept that lets us reach deep into a chain of dependencies and alter the behavior of a system as needed.

## Testing

The same concept can be used used when writing unit tests. Consider the following.

```swift
final class FactoryCoreTests: XCTestCase {

    override func setUp() {
        super.setUp()
        Container.shared = Container()
    }
    
    func testLoaded() throws {
        Container.shared.accountProvider.register { MockProvider(accounts: .sampleAccounts) }
        let model = Container.shared.someViewModel()
        model.load()
        XCTAssertTrue(model.isLoaded)
    }

    func testEmpty() throws {
        Container.shared.accountProvider.register { MockProvider(accounts: []) }
        let model = Container.shared.someViewModel()
        model.load()
        XCTAssertTrue(model.isEmpty)
    }

    func testErrors() throws {
        Container.shared.accountProvider.register { MockProvider(error: .notFoundError) }
        let model = Container.shared.someViewModel()
        model.load()
        XCTAssertTrue(model.errorMessage = "Some Error")
    }
    
}
```
Again, Factory makes it easy to reach into a chain of dependencies and make specific changes to the system as needed. This makes testing loading states, empty states, and error conditions simple.

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

Factory has other scope types, plus the ability to add more of your own. See [Scopes](https://hmlongco.github.io/Factory/documentation/factory/scopes) for additional examples.

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

One powerful new feature in Factory 2.1 is contexts. Let's say that for logistical reasons whenever your application runs in debug mode you *never* want it to make calls to your application's analytics engine.

Easy. Just register an override for that particular context.

```swift
container.analytics.onDebug { 
    StubAnalyticsEngine()
}
```
There are other contexts for unit testing, for SwiftUI previews, and even when running UITests both in the simulator or when running an app on services like BrowserStack. See the documentation for more.

## Debugging

Factory can also help you debug your code. When running in DEBUG mode Factory allows you to trace the injection process and see every object instantiated or returned from a cache during a given resolution cycle.
```
0: Factory.Container.cycleDemo<CycleDemo> = N:105553131389696
1:     Factory.Container.aService<AServiceType> = N:105553119821680
2:         Factory.Container.implementsAB<AServiceType & BServiceType> = N:105553119821680
3:             Factory.Container.networkService<NetworkService> = N:105553119770688
1:     Factory.Container.bService<BServiceType> = N:105553119821680
2:         Factory.Container.implementsAB<AServiceType & BServiceType> = C:105553119821680
```
This can make it a lot easier to see the entire dependency tree for a given object or service.

See [Debugging](https://hmlongco.github.io/Factory/documentation/factory/debugging) for more on this and other features.

## Documentation

A single README file barely scratches the surface. Fortunately, Factory is throughly documented. 

Current DocC documentation can be found in the project as well as online on [GitHub Pages](https://hmlongco.github.io/Factory/documentation/factory).

## Installation

Factory supports CocoaPods and the Swift Package Manager.
```
pod "Factory"
```
Or download the source files and add the Factory folder to your project.

Note that the current version of Factory (2.1) require Swift 5.1 minimum and that the minimum version of iOS currently supported with this release is iOS 11.

## Factory 2.0 Migration

If you started with Factory 1.x a [migration document is available here](https://hmlongco.github.io/Factory/documentation/factory/migration).

* Factory 2.0 adds true Factory containers for container-based dependency resolution
* Factory 2.0 adds container-based scopes
* Factory 2.0 adds decorators to containers and factories
* Factory 2.0 adds debug trace support
* Factory 2.0 adds keyPath-based property wrappers
* Factory 2.0 adds a new InjectedObject property wrapper for SwiftUI Views

## Discussion Forum

Discussion and comments on Factory and Factory 2.0 can be found in [Discussions](https://github.com/hmlongco/Factory/discussions). Go there if you have something to say or if you want to stay up to date.

## License

Factory is available under the MIT license. See the LICENSE file for more info.

## Sponsor Factory!

If you want to support my work on Factory and Resolver, consider a [GitHub Sponsorship](https://github.com/sponsors/hmlongco)! Many levels exist for increased support and even for mentorship and company training. 

Or you can just buy me a cup of coffee!

And many thanks to my new sponsors: sueddeutsche, doozMen.

## Author

Factory is designed, implemented, documented, and maintained by [Michael Long](https://www.linkedin.com/in/hmlong/), a Lead iOS Software Engineer and a Top 1,000 Technology Writer on Medium.

* LinkedIn: [@hmlong](https://www.linkedin.com/in/hmlong/)
* Medium: [@michaellong](https://medium.com/@michaellong)
* Twitter: [@hmlco](https://twitter.com/hmlco)

Michael was also one of Google's [Open Source Peer Reward](https://opensource.googleblog.com/2021/09/announcing-latest-open-source-peer-bonus-winners.html) winners in 2021 for his work on Resolver.

## Additional Resources

* [Factory Documentation](https://hmlongco.github.io/Factory/documentation/factory)
* [Factory 1.0 and Functional Dependency Injection](https://betterprogramming.pub/factory-and-functional-dependency-injection-2d0a38042d05)
* [Factory 1.0: Multiple Module Registration](https://betterprogramming.pub/factory-multiple-module-registration-f9d19721a31d?sk=a03d78484d8c351762306ff00a8be67c)
* [Resolver: A Swift Dependency Injection System](https://github.com/hmlongco/Resolver)
* [Inversion of Control Design Pattern ~ Wikipedia](https://en.wikipedia.org/wiki/Inversion_of_control)
* [Inversion of Control Containers and the Dependency Injection pattern ~ Martin Fowler](https://martinfowler.com/articles/injection.html)
* [Nuts and Bolts of Dependency Injection in Swift](https://cocoacasts.com/nuts-and-bolts-of-dependency-injection-in-swift/)
* [Dependency Injection in Swift](https://cocoacasts.com/dependency-injection-in-swift)
* [Swift 5.1 Takes Dependency Injection to the Next Level](https://medium.com/better-programming/taking-swift-dependency-injection-to-the-next-level-b71114c6a9c6)
* [Builder: A Declarative UIKit Library (Uses Factory in Demo)](https://github.com/hmlongco/Builder)
