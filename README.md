![](https://github.com/hmlongco/Factory/blob/main/Logo.png?raw=true)

A new approach to Container-Based Dependency Injection for Swift and SwiftUI.

## Why Something New?

The first dependency injection system I ever wrote was [Resolver](https://github.com/hmlongco/Resolver). This open source project, while quite powerful and still in use in many applications, suffers from a few drawbacks.

1. Resolver requires pre-registration of all services up front. 
2. Resolver uses type inference to dynamically find and return registered services from a container.

The first drawback is relatively minor. While preregistration could lead to a performance hit on application launch, in practice the process is usually quick and not normally noticeable.

No, it’s the second one that’s somewhat more problematic.

Failure to find a matching type can lead to an application crash if we attempt to resolve a given type and a matching registration is not found. In real life that isn’t really a problem as such a thing tends to be noticed and fixed rather quickly the very first time you run a unit test or the second you run the application to see if your newest feature works.
 
 But... could we do better? That question lead me on a quest for compile-time type safety. Several other systems have attempted to solve this, but I didn't want to have to add a source code scanning and generation step to my build process, nor did I want to give up a lot of the control and flexibility inherent in a run-time-based system.
 
 I also wanted something simple, fast, clean, and easy to use.
 
 Could I have my cake and eat it too?
 
 ## Features
 
 Factory is strongly influenced by SwiftUI, and in my opinion is highly suited for use in that environment. Factory is...
 
 * **Safe:** Factory is compile-time safe; a factory for a given type *must* exist or the code simply will not compile.
 * **Flexible:** It's easy to override dependencies at runtime and for use in SwiftUI Previews.
 * **Powerful:** Like Resolver, Factory supports application, cached, shared, and custom scopes, custom containers, arguments, decorators, and more.
 * **Lightweight:** With all of that Factory is slim and trim, just 400 lines of code and half the size of Resolver.
 * **Performant:** Little to no setup time is needed for the vast majority of your services, resolutions are extremely fast, and no compile-time scripts or build phases are needed.
 * **Concise:** Defining a registration usually takes just a single line of code. Same for resolution.
 * **Tested:** Unit tests ensure correct operation of registrations, resolutions, and scopes.
 * **Free:** Factory is free and open source under the MIT License.
 
 Sound too good to be true? Let's take a look.
  
 ## A Simple Example
 
Most container-based dependency injection systems require you to define in some way that a given service type is available for injection and many require some sort of factory or mechanism that will provide a new instance of the service when needed.
 
 Factory is no exception. Here's a simple dependency registration.
 
```swift
extension Container {
    static let myService = Factory { MyService() as MyServiceType }
}
```
Unlike Resolver which often requires defining a plethora of nested registration functions, or SwiftUI, where defining a new environment variable requires creating a new EnvironmentKey and adding additional getters and setters, here we simply add a new `Factory` to the default container. When called, the factory closure is evaluated and returns an instance of our dependency. That's it.

Injecting and using the service where needed is equally straightforward. Here's one way to do it.

```swift
class ContentViewModel: ObservableObject {
    @Injected(Container.myService) private var myService
    ...
}
```
Here our view model uses one of Factory's `@Injected` property wrappers to request the desired dependency. Similar to `@EnvironmentObject` in SwiftUI, we provide the property wrapper initializer with a reference to a factory of the desired type and it handles the rest.

And that's the core mechanism. In order to use the property wrapper you *must* define a factory. That factory *must* return the desired type when asked. Fail to do either one and the code will simply not compile. As such, Factory is compile-time safe.

 ## Factory

Similar to a `View` in SwiftUI, a `Factory` is a lightweight struct that exists to define and manage a specific dependency. Just provide it with a closure that constructs and returns an instance of your dependency or service, and Factory will handle the rest.

```swift
static let myService = Factory { MyService() as MyServiceType }
```

The type of a factory is inferred from the return type of the closure. Here's we're casting `MyService` to the protocol it implements, so any dependency returned by this factory will always conform to `MyServiceType`. 

We can also get the same result by explicitly specializing the generic Factory as shown below. Both the specialization and the cast are equivalent and provide the same result.

```swift
static let myService = Factory<MyServiceType> { MyService() }
```

Do neither one and the factory type will always be the returned type. In this case it's `MyService`.

```swift
static let myService = Factory { MyService() }
```

Due to the lazy nature of static variables, no factory is instantiated until it's referenced for the first time. Contrast this with Resolver, which forced us to run code to register *everything* prior to resolving anything.

Finally, note that it's possible to bypass the property wrapper and talk to the factory yourself in a *Service Locator* pattern.

```swift
class ContentViewModel: ObservableObject {
    // dependencies
    private let myService = Container.myService()
    private let eventLogger = Container.eventLogger()
    ...
}
```
Just call the desired specific factory as a function and you'll get an instance of its managed dependency. It's that simple.

*You can access the factory directly or the property wrapper if you prefer, but either way for clarity I'd suggest grouping all of a given object's dependencies in a single place near the top of the class and marking them as private.*

## Mocking and Testing

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

Now when our preview is displayed `ContentView` creates a `ContentViewModel` which in turn has a dependency on `myService` using the `Injected` property wrapper. 

And when the wrapper asks the factory for an instance of `MyServiceType` it now gets a `MockService2` instead of the `MyService` type originally defined.


This is a powerful concept that lets us reach deep into a chain of dependencies and alter the behavior of a system as needed.

But we're not done yet. 

Factory has quite a few more tricks up its sleeve...

## Scope

If you've used Resolver or some other dependency injection system before then you've probably experienced the benefits and power of scopes.

And if not, the concept is easy to understand: Just how long should an instance of an object live?

You've no doubt stuffed an instance of a class into a variable and created a singleton at some point in your career. This is an example of a scope. A single instance is created and then used and shared by all of the methods and functions in the app.

This can be done in Factory just by adding a scope attribute.

```swift
extension Container {
    static let myService = Factory(scope: .singleton) { MyService() as MyServiceType }
}
```
Now whenever someone requests an instance of `myService` they'll get the same instance of the object as everyone else.

If not specified the default scope is unique. A new instance of the service will be instantiated and returned every time one is requested from the factory.

Other common scopes are `cached` and `shared`. Cached items are persisted until the cache is reset, while shared items exist just as long as someone holds a strong reference to them. When the last reference goes away, the weakly held shared reference also goes away.

You can also add your own special purpose caches to the mix. Try this.

```swift
extension Container.Scope {
    static var session = Cached()
}

extension Container {
    static let authenticatedUser = Factory(scope: .session) { AuthenticatedUser() }
    static let profileImageCache = Factory(scope: .session) { ProfileImageCache() }
}
```
Once created, a single instance of `AuthenticatedUser` and `ProfileImageCache` will be provided to anyone that needs one... up until the point where the session scope is reset, perhaps by a user logging out.

```swift
func logout() {
    Container.Scope.session.reset()
    ...
}
```
Scopes are powerful tools to have in your arsenal. Use them.

## Graph Scope

There's one additional scope, called `graph`. This scope will reuse any factory instances resolved during a given resolution cycle. This can come in handy when a single class implements multiple protocols. Consider the following...
```swift
class ProtocolConsumer {
    @Injected(Container.idProvider) var ids
    @Injected(Container.valueProvider) var values
    init() {}
}
```
The `ProtocolConsumer` wants two different protocols. But it doesn't know that a single class provides both services. (Nor should it care.) Take a look at the referenced factories.
```swift
extension Container {
    static let consumer = Factory { ProtocolConsumer() }
    static let idProvider = Factory<IDProviding> { commonProviding() }
    static let valueProvider = Factory<ValueProviding> { commonProviding() }
    private static let commonProviding = Factory(scope: .graph) { MyService() }
}
```
Both provider factories reference the same factory. When Factory is asked for an instance of `consumer`, both providers will receive the same instance of `MyService`.

There are a few caveats and considerations for using graph. The first is that anyone who wants to participate in the graph needs to explicitely state as such using the graph scope. Note the scope parameter for `commonProviding`.

The second is that there needs to be a "root" to the graph. In the above example, the `consumer` object is the root. Factory is asked for a consumer, which in turn requires two providers. If you were to instantiate an instance of `ProtocolConsumer` yourself, each one of ProtocolConsumer's Injected property wrappers would initialize sequentually on the same thread, resulting in two separate and distinct resolution cycles.

## Constructor Injection

At times we might prefer (or need) to use a technique known as *constructor injection* where dependencies are provided to an object upon initialization. 

That's easy to do in Factory. Here we have a service that needs an instance of `MyServiceType`.

```swift
extension Container {
    static let constructedService = Factory { ConstructedService(service: myService()) }
}
```
All of the factories in a container are visible to the other factories in that container. Just call the needed factory as a function and the dependency will be provided.

## Passing Parameters

Like it or not, some services require one or more parameters to be passed to them in order to be initialized correctly. In that case use `ParameterFactory`.

```swift
extension Container {
    static var parameterService = ParameterFactory<Int, MyServiceType> { n in
        ParameterService(value: n)
    }
}

```

One caveat is that you can't use the `@Injected` property wrapper with `ParameterFactory` as there's no way to get the needed parameters to the property wrapper before the wrapper is initialized. That being the case, you'll probably need to reference the container directly and do something similar to the following.

```swift
class MyClass {
    var myService: MyServiceType
    init(_ n: Int) {
         myService = Container.parameterService(n)
    }
}
```
If you need to pass more than one parameter just use a tuple, dictionary, or struct.
```swift
static var tupleService = ParameterFactory<(Int, Int), MultipleParameterService> { (a, b) in
    MultipleParameterService(a: a, b: b)
}
```
Finally, if you define a scope keep in mind that the first argument passed will be used to create the dependency and *that* dependency will be cached. Since the cached object will be returned from now on any arguments passed in later requests will be ignored until the scope is reset.

## Optionals and Dynamic Registration

With Factory registrations can be performed at any time. Consider the following optional factory.

```swift
extension Container {
    static let userProviding = Factory<UserProviding?> { nil }
}

func authenticated(with user: User) {
    ...
    Container.userProviding.register { UserProvider(user: user) }
    ...
}

func logout() {
    ...
    Container.userProviding.reset()
    ...
}
```
Now any view model or service that needs an instance of an authenticated user will receive one (or nothing if no user is authenticated). Here's an example:
```swift
class SomeViewModel: ObservableObject {
    @Injected(Container.userProviding) private let provider
    func update(email: String) {
        provider?.updateEmailAddress(email)
    }
}
```
The injected provider is optional by default since the Factory was defined that way. You *could* explicitly unwrap the optional...
```swift
@Injected(Container.userProviding) private let provider: UserProviding!
```

But doing so violates the core premise on which Factory was built in the first place: *Your code is guaranteed to be safe.* 

I'd advise against it.

A few other things here. First, note that we used `@Injected` to supply an optional type. We don't need a `@OptionalInjected` property wrapper to do this as we did in Resolver. Same for `@LazyInjected`.

Next, note that Factory is *thread-safe.* Registrations and resolutions lock and unlock the containers and caches as needed.

And finally, note that calling register also *removes any cached dependency from its associated scope.* This ensures that any new dependency injection request performed from that point on will always get the most recently defined instance of an object.

This technique can also be handy when doing registrations in a project with multiple modules. See: [Factory: Multiple Module Registration](https://betterprogramming.pub/factory-multiple-module-registration-f9d19721a31d?sk=a03d78484d8c351762306ff00a8be67c)

## AutoRegistering

If you use the above technique to create optional registrations across multiple modules in your project you may find that you need to register some instances prior to application initialization. If so you can do the following.
```swift
extension Container: AutoRegistering {
    static func registerAllServices() {
        autoRegisteredService.register {
            ModuleA.register()
            ModuleB.register()
            ...
        }
    }
}
```
Just make `Container` conform to `AutoRegistering` and provide the `registerAllServices` static function. This function will be called *once* prior to the very first Factory service resolution.

## Lazy and Weak Injections
Factory also has `LazyInjected` and `WeakLazyInjected` property wrappers. Use `LazyInjected` when you want to defer construction of some class until it's actually needed. Here the child `service` won't be instantiated until the `test` function is called.
```swift
class ServicesP {
    @LazyInjected(Container.servicesC) var service
    let name = "Parent"
    init() {}
    func test() -> String? {
        service.name
    }
}
```
And `WeakLazyInjected` is useful when building parent/child relationships and you want to avoid retain cycles back to the parent class. It's also lazy since otherwise you'd have a cyclic dependency between the parent and the child. (P needs C which needs P which needs C which...)'
```swift
class ServicesC {
    @WeakLazyInjected(Container.servicesP) var service: ServicesP?
    init() {}
    let name = "Child"
    func test() -> String? {
        service?.name
    }
}
```
And the factories. Note the shared scopes so references can be kept and maintained for the parent/child relationships.
```swift
extension Container {
    static var servicesP = Factory(scope: .shared) { ServicesP() }
    static var servicesC = Factory(scope: .shared) { ServicesC() }
}
```
Note that if you use `WeakLazyInjected` then that class must have been instantiated previously and a strong reference to the class must be maintained elsewhere. If not then the class will be released as soon as it's created. Think of it like...
```swift
weak var gone: MyClass? = MyClass()
```
`WeakLazyInjected` can also come in handy when you need to break circular dependencies. See below.

## Functional Injection

Factory can inject more than service classes and structs. Functional Injection is a powerful tool that can, in many cases, eliminate the need for defining protocols, implementations, and the various stubs and mocks one needs when doing traditional Protocol-Oriented-Programing.

Consider:
```swift
typealias AccountProviding = () async throws -> [Account]

extension Container {
    static let accountProvider = Factory<AccountProviding> {
        { try await Network.get(path: "/accounts") }
    }
}
```
And here's the view model that utilizes it.
```swift
class AccountViewModel: ObservableObject {
    @Injected(Container.accountProvider) var accountProvider
    @Published var accounts: [Account] = []
    @MainActor func load() async {
        do {
            accounts = try await accountProvider()
        } catch {
            print(error)
        }
    }
}
```
Now consider how easy it is to write a test with mock accounts...
```swift
func testAllAccounts() async {
    Container.accountProvider.register {{ Account.mockAccounts }}
    do {
        let viewModel = AccountViewModel()
        try await viewModel.load()
        XCTAssert(viewModel.accounts.count == 5)
    } catch {
        XCTFail("Account load failed")
    }
}
```
Or test edge cases like no accounts found. Or test specific errors.
```swift
func testEmptyAccounts() async {
    Container.accountProvider.register {{ [] }}
    ...
}

func testErrorLoadingAccounts() async {
    Container.accountProvider.register {{ throw APIError.network }}
    ...
}
```
Here's an article that goes into the technique in more detail: [Factory and Functional Dependency Injection](https://betterprogramming.pub/factory-and-functional-dependency-injection-2d0a38042d05)

## Custom Containers

In a large project you might want to segregate factories into additional, smaller containers.

```swift
class OrderContainer: SharedContainer {
    static let optionalService = Factory<SimpleService?> { nil }
    static let constructedService = Factory { MyConstructedService(service: myServiceType()) }
    static let additionalService = Factory(scope: .session) { SimpleService() }
}
```
Just define a new container derived from `SharedContainer` and add your factories there. You can have as many as you wish, and even derive other containers from your own. 

```swift
class PaymentsContainer: OrderContainer {
    static let paymentsServiceType = Factory<PaymentsServiceType> { PaymentsService(service: myServiceType()) }
}
```

While a container *tree* makes dependency resolutions easier, don't forget that if need be you can reach across containers simply by specifying the full container.factory path.

```swift
class PaymentsContainer: SharedContainer {
    static let anotherService = Factory { AnotherService(OrderContainer.optionalService()) }
}
```
It's important to note that in Factory a custom container is not really a "container" in the traditional sense. It's a name space, used to group similar or related factories together. All registrations and scopes are still managed by the parent `SharedContainer` class on which all containers are based.

## SharedContainer

You can also add your own factories to the root `SharedContainer` class. Anything added there will be visible and available to every container in the system.

```swift
extension SharedContainer {
    static let api = Factory<APIServiceType> { APIService() }
}
```
As mentioned earlier, any registrations defined with your app are managed here.

## Circular Dependency Chain Detection

What's a circular dependency? Let's say that A needs B to be constructed, and B needs a C. But what happens if C needs an A? Examine the following class definitions.
```swift
class CircularA {
    @Injected(Container.circularB) var circularB
}

class CircularB {
    @Injected(Container.circularC) var circularC
}

class CircularC {
    @Injected(Container.circularA) var circularA
}
```
Attempting make an instance of `CircularA` is going to result in an infinite loop. Why? Well, A's injected property wrapper needs a B in to construct an A. Okay, fine. Let's make one. But B's wrapper needs a C, which can't be made without injecting an A, which once more needs a B... and so on. Ad infinitum.

This is a circular dependency chain.

Unfortunately, by the time this code is compiled and run it's too late to break the cycle. We've effectively coded an infinite loop into our program. All Factory can do in this case is die gracefully and in the process dump the dependency chain that indicates where the problem lies.
```
2022-12-23 14:57:23.512032-0600 FactoryDemo[47546:6946786] Factory/Factory.swift:393: 
Fatal error: circular dependency chain - CircularA > CircularB > CircularC > CircularA
```
With the above information in hand we should be able to find the problem and fix it.

We could fix things by chaging CircularC's injection wrapper to `LazyInjected` or, better yet, `WeakLazyInjected` in order to avoid a retain cycle. But a better solution would probably entail finding and breaking out the functionality that `CircularA` and `CircularC` are depending upon into a *third* object they both could include.

Circular dependencies such as this are usually a violation of the Single Responsibility Principle, and should be avoided.

*Note: Due to the overhead involved, circular dependency detection only occurs when running the application in DEBUG mode. The code is stripped out of production builds for improved performance.*

## SwiftUI Integrations

Factory can be used in SwiftUI to assign a dependency to a `StateObject` or `ObservedObject`.
```swift
class ContentView: ObservableObject {
    @StateObject private var viewModel = Container.contentViewModel()
    var body: some View {
        ...
    }
}
```
Keep in mind that if you assign to an `ObservedObject` your Factory is responsible for managing the object's lifecycle (see the section on Scopes above).

Unlike Resolver, Factory doesn't have an @InjectedObject property wrapper. There are [a few reasons for this](https://github.com/hmlongco/Factory/issues/15), but for now doing your own assignment to `StateObject` or `ObservedObject` is the preferred approach. 

That said, at this point in time I feel that we should probably avoid using Factory to create the view model in the first place.  It's usually unnecessary, [you really can't use protocols with view models anyway](https://betterprogramming.pub/swiftui-view-models-are-not-protocols-8c415c0325b1), and for the most part Factory's really designed to provide the VM and other services with the dependencies that *they* need. 

Especially since those services have no access to the environment.

## SwiftUI Previews

With that in mind, here's an example of updating a view model's service dependency in order to setup a particular state for  preview.

```swift
class ContentView: ObservableObject {
    @StateObject var viewModel = ContentViewModel()
    var body: some View {
        ...
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let _ = Container.myService.register { MockServiceN(4) }
        ContentView()
    }
}
```
If we can control where the view model gets its data then we can put the view model into pretty much any state we choose.

If we want to do multiple previews at once, each with different data, we simply need to instantiate our view models and pass them into the view as parameters.
```swift
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            let _ = Container.myService.register { MockServiceN(4) }
            let vm1 = ContentViewModel()
            ContentView(viewModel: vm1)

            let _ = Container.myService.register { MockServiceN(8) }
            let vm2 = ContentViewModel()
            ContentView(viewModel: vm2)
        }
    }
}
```

## Common Setup

If we have several mocks that we use all of the time in our previews or unit tests, we can also add a setup function to a given container to make this easier.

```swift
extension Container {
    static func setupMocks() {
        myService.register { MockServiceN(4) }
        sharedService.register { MockService2() }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let _ = Container.setupMocks()
        ContentView()
    }
}
```

## Reset

Using register on a factory lets us change the state of the system. But what if we need to revert back to the original behavior?

Simple. Just reset it to bring back the original factory closure. Or, if desired, you can reset *everything* back to square one with a single command.

```Swift
Container.myService.reset() // single
Container.Registrations.reset() // all 
```

The same applies to scope management. You can reset a single cache, or all of them if desired. This includes any caches you might have added, like the `session` scope we added above.

```Swift
Container.Scope.cached.reset() // single
Container.Scope.reset() // all scopes except singletons
Container.Scope.reset(includingSingletons: true) // all including singletons
```
The `includingSingletons` option must be explicitly specified in order to reset singletons. You have the power. Use it wisely.

## Xcode Unit Tests

Finally, Factory has a few additional provisions added to make unit testing easier. In your unit test setUp function you can *push* the current state of the registration system and then register and test anything you want.

```swift
final class FactoryCoreTests: XCTestCase {

    override func setUp() {
        super.setUp()
        Container.Registrations.push()
        Container.setupMocks()
     }

    override func tearDown() {
        super.tearDown()
        Container.Registrations.pop()
    }
    
    func testSomething() throws {
        Container.myServiceType.register(factory: { MockService() })
        let model = Container.someViewModel()
        XCTAssertTrue(model.isLoaded)
        ...
    }
}
```

Then in your tearDown function simply *pop* your changes to restore everything back to the way it was prior to running that test suite.

## Resolver

Factory will probably mark the end of Resolver. I learned a lot from that project, and it even won me an [Open Source Peer Bonus from Google](https://opensource.googleblog.com/2021/09/announcing-latest-open-source-peer-bonus-winners.html). (I always thought it a bit strange for an iOS developer to get an award from Google, but there you have it.)

But Factory is smaller, faster, cleaner and all in all a much better solution than Resolver could ever be.

## Installation

Factory is available as a Swift Package. Just add it to your projects.

It's also available via CocoaPods. Just add `pod Factory` to your Podfile.

Finally, Factory is just a single file. Download the project and then add Factory.swift to your project. It's that easy.

## License

Factory is available under the MIT license. See the LICENSE file for more info.

## Author

Factory is designed, implemented, documented, and maintained by [Michael Long](https://www.linkedin.com/in/hmlong/), a Lead iOS Software Engineer and a Top 1,000 Technology Writer on Medium.

* LinkedIn: [@hmlong](https://www.linkedin.com/in/hmlong/)
* Medium: [@michaellong](https://medium.com/@michaellong)
* Twitter: @hmlco

Michael was also one of Google's [Open Source Peer Reward](https://opensource.googleblog.com/2021/09/announcing-latest-open-source-peer-bonus-winners.html) winners in 2021 for his work on Resolver.

## Additional Resources

* [Factory and Functional Dependency Injection](https://betterprogramming.pub/factory-and-functional-dependency-injection-2d0a38042d05)
* [Factory: Multiple Module Registration](https://betterprogramming.pub/factory-multiple-module-registration-f9d19721a31d?sk=a03d78484d8c351762306ff00a8be67c)
* [Resolver: A Swift Dependency Injection System](https://github.com/hmlongco/Resolver)
* [Inversion of Control Design Pattern ~ Wikipedia](https://en.wikipedia.org/wiki/Inversion_of_control)
* [Inversion of Control Containers and the Dependency Injection pattern ~ Martin Fowler](https://martinfowler.com/articles/injection.html)
* [Nuts and Bolts of Dependency Injection in Swift](https://cocoacasts.com/nuts-and-bolts-of-dependency-injection-in-swift/)
* [Dependency Injection in Swift](https://cocoacasts.com/dependency-injection-in-swift)
* [Swift 5.1 Takes Dependency Injection to the Next Level](https://medium.com/better-programming/taking-swift-dependency-injection-to-the-next-level-b71114c6a9c6)
* [Builder: A Declarative UIKit Library (Uses Factory in Demo)](https://github.com/hmlongco/Builder)
