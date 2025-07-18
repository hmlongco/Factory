# Testing

Using Factory for Unit and UI Testing.

## Overview

Dependency injection exists to manage and decouple dependencies among objects; making the code more modular, maintainable, and testable. It says so right on the label.

As you've already seen, the main mechanism provided by Factory to accomplish this is registration. Going into the dependency system and registering a new type, typically a mock or stub or spy, in order for that type to be injected into the code under test.

```swift
Container.shared.accountLoading.register { MockNoAccounts() }
```
But Factory has other enhancements designed to make unit testing and user interface testing simpler and easier. 

Some, like <doc:Contexts> you may have already seen and used. Others, like pushing/popping container state, resetting, scoping with test traits and so on, are discussed below.

Before we look at them, it's important to first understand Xcode's test process and environment, and consider what that means when writing your own unit tests using Factory.

*Jump to the end for information on using Factory with Swift Testing in Xcode 16.*

## The Unit Test Environment

When you run a unit test, Xcode is launching and running your app in order to provide a relevant context for your test code. 

This means that application main ran, that the application delegate's `didFinishLaunchingWithOptions` function ran, and all the code needed to get to your first screen ran. When your app reaches a state where RunLoop.main starts idling and waiting for user input, *then* XCTest will start constructing test classes and running test cases.

All of which means that a LOT of code has already run before your first test has even fired. 

**Including dependency injection code.**

So when writing unit tests we need to keep in mind what our initial runtime application environment looks like, what Factory registrations may have already have occurred, and in particular, if any of those registrations were scoped and cached. 

This is specially true when dealing with *singletons*. But again, let's save that topic for a bit later.

#### Changing, Not Rebuilding

So our environment exists, running and awaiting our first test. All of our original runtime dependency injection extensions and registrations are also out there, ready to be resolved and injected when needed. 

And that's great. A cryptographic hashing dependency can be used in production and in test with no repercussions. We don't need to change a thing. And in fact, the more working code we can test in its shipping state, the better.

That said, other services like analytics might want to be swapped out during testing. Don't want to feed the system all of your dummy test data. Again, <doc:Contexts> can help with that.

But we're here to test, and one thing we probably *do* care about is the code is talks to our APIs and other services. Those are the classes and services that we're probably going to want to mock and reregister so we can test our view models and business logic against stable test data.

Again, Factory makes that easy.

```swift
func testNoAccounts() async {
    // register a mock
    Container.shared.accountLoading.register { MockNoAccounts() }
    // instantiate the model that uses the mock
    let model = Container.shared.accountsViewModel()
    // and test...
    await model.load()
    XCTAssertTrue(model.isLoaded)
    XCTAssertTrue(model.isEmpty)
}
```
Or we can write a test against unstable test data...

```swift
func testNoAccounts() async {
    // register a mock
    Container.shared.accountLoading.register { MockAccountError(404) }
    // instantiate the model that uses the mock
    let model = Container.shared.accountsViewModel()
    // and test...
    await model.load()
    XCTAssertFalse(model.isLoaded)
    XCTAssertTrue(model.isError)
}
```
Only if we're running a lot of tests like this then we're going to making a lot of changes to the dependency injection environment. And that's problematic. 

We need to make sure that a change made in one test doesn't affect a later test that relied on the *original* object that demonstrated a *different* behavior. Or setting up circumstances where randomizing tests can cause the same thing to occur.

Sound confusing? It is. Try tracking it down in actual code. 

How to solve it? Well, the best solution to that sort of problem is to avoid it in the first place.

Fortunately, Factory can help with that.

#### Pushing and Popping State

In your unit test setUp function you can *push* the current state of the registration system and then register and test anything you want.

Then in teardown you can *pop* the stack, eliminating all of your changes and restoring the container to its original state before the push.

This lets each set of tests start from the same initial state, regardless of what any prior test had changed.

The following example assumes we're using the shared container.

```swift
final class FactoryCoreTests: XCTestCase {

    override func setUp() {
        Container.shared.manager.push()
        Container.shared.setupMocks()
    }
    
    override func tearDown() {
        Container.shared.manager.pop()
    }
    
    func testNoAccounts() async {
        Container.shared.accountLoading.register { MockNoAccounts() }
        let model = Container.shared.accountsViewModel()
        await model.load()
        XCTAssertTrue(model.isLoaded)
        XCTAssertTrue(model.isEmpty)
    }

    func testError() async {
        Container.shared.accountLoading.register { MockAccountError(404) }
        let model = Container.shared.accountsViewModel()
        await model.load()
        XCTAssertTrue(model.isError)
    }
}
```
That's pretty much it. Our `AccountsViewModel` depended on an `AccountsLoading` service. 

Change the service provided and we change the *data* provided. Change the *data* provided and we change our view model's behavior.

And then we test the results to see if everything matches up with our expectations.

#### Diving Deeper

Note that the above is just one way of doing things. If, for example, our `AccountLoader` service depended on a custom network layer, we could reach further down the stack.

```swift
func testNoAccounts() async throws {
    let json = #"{ "accounts": [] }"#
    Container.shared.networking.register { MockJSON(json) }
    let model = Container.shared.accountsViewModel()
    // as before
}
```
We create the `AccountsViewModel`, the view model injects the `AccountLoading` service, and that service injects our mock network service.

Same for our error code.

```swift
func testNoAccounts() async throws {
    Container.shared.networking.register { MockError(404) }
    let model = Container.shared.accountsViewModel()
    // as before
}
```
Layering your code in such a fashion can dramatically reduce the number of mocks and other objects you need to create and mange. You don't just change the view model's dependencies. You change the dependencies the dependencies depend on.

Factory makes reaching deep into a dependency tree and adjusting behavior simple and easy.

It can even help you see what's *inside* that dependency tree. See <doc:Debugging> for more information.

#### Rebuilding The Container

In your unit test setUp function you can also just reset the container caches and start over from scratch. No teardown needed.

```swift
final class FactoryCoreTests: XCTestCase {

    override func setUp() {
        Container.shared.reset()
        Container.shared.setupMocks()
    }
    
    func testNoAccounts() throws {
        ...
    }
}
```
Note that this is pretty safe to do in the majority of cases. Your application has already launched, obtained what it needed, and is now idling.

#### Passed Containers

Finally, you can also pass the container into the view model itself.

```swift
final class FactoryCoreTests: XCTestCase {

    var container: Container!

    override func setUp() {
        container = Container()
        container.setupMocks()
    }
    
    func testSomething() throws {
        container.myServiceType.register(factory: { MockService() })
        let model = MyViewModel(container: container)
        model.load()
        XCTAssertTrue(model.isLoaded)
    }
}
```

This does, of course, assume that you structured your app appropriately.

#### Common Setup

As shown in the earlier examples, if we have several mocks that we use all of the time in our previews or unit tests, we can also add a setup function to a given container to make this easier.

```swift
extension Container {
    func setupMocks() {
        myService.register { MockServiceN(4) }
        sharedService.register { MockService2() }
    }
}
```

## Testing Singletons

Let's talk singletons. The singleton scope cache is global, meaning that it's *not* managed by any specific container. 

That being the case, neither the push/pull mechanism or the container rebuilding mechanisms described above will clear any cached singleton instances.

Singletons are, after all, expected to be singletons.

So what to do about it? 

#### Resetting Singletons

If needed we can reset *every* cached singleton with just a single method call. Just call reset on that particular scope.

```swift
Scope.singleton.reset()
```
Or you can reset a specific singleton by reaching out to its factory.

```swift
// reset everything for that factory
Container.shared.someSingletonFactory.reset()
// reset just the scope cache
Container.shared.someSingletonFactory.reset(options: .scope)
// or simply register a new instance
Container.shared.someSingletonFactory.register { MyNewMock() }
```
On that last point. Doing a registration change on a factory usually clears it's associated scope automatically. The assumption, of course, being that if you register something you expect it to be used. 

This also applies to singletons *unless you're inside of a autoRegister block.* AutoRegistration can happen on every container creation, and automatically clearing a registered singleton each and every time that occurs kind of defeats the idea of multiple containers on one hand and singletons on the other.

So all that said, we can deal with them. But as a general rule, singletons can complicate your life, your code, and your tests, and as such they should be avoided and only be used when there's an overriding need for there to be one and only one instance of an object across multiple containers.

Got that, Highlander?

## Complexity Management

If all of the pushing and popping and resetting sounds complex, that's because it is.

Keep in mind that we're usually dealing with a single shared container, often accessed directly using `Container.shared`, or indirectly using property wrappers like `@Injected` that call `Container.shared` under the hood.

Every test is accessing that container and its values.

Which means we have to manage our global state carefully so each test is beginning from a known starting point.

But there's a better way.

## Xcode 16 and Swift Testing

The challenge that Swift Testing brought to our lives is that it defaults to parallel test runs. While this can speed up test runs significantly it's not that straightforward. 

Especially when we keep in mind our original problem of having a consistent, known starting point.

Given what we've seen thus far, the problem seems almost impossible. How do we keep tests running in parallel from stepping all over each other?

Luckily there is an answer: [Test Scoping Traits](https://developer.apple.com/documentation/testing/trait)

With Xcode 16.3's test traits we can make each of our tests local, each isolated to their own task, and allow each to begin from a known starting point.

#### Bad Tests

Consider the following somewhat problematic code. We have two tests, and under Swift Testing those tests are going to run in parallel.

```swift
import Testing

struct AppTests {
  @Test func testA() async {
    Container.shared.someService.register { ErrorService() }
    let service = Container.shared.someService()
    #expect(service.error == "Oops")
  }

  @Test(arguments: Parameters.allCases) 
  func testB(parameter: Parameters) async {
    Container.shared.someService.register { MockService(parameter: parameter) }
    let service = Container.shared.someService()
    #expect(service.parameter == parameter)
  }
}
```

In the code you'll see that the two tests both register different values for `someService` on the same shared container. 

Which means that these tests could suffer from race conditions should they be run in parallel.

Which in turn could result in our tests failing randomly. And that's bad.

#### Container Traits

The latest addition to Factory leverages the power of `@TaskLocal` and Test Scoping Traits to resolve this problem.

By using our Factory defined `.container` trait inside our `@Test` macro, we can make sure that each of our unit tests runs in its own isolated context, and each has their own container.

```swift
import Testing
import FactoryTesting

struct AppTests {
  @Test(.container) 
  func testA() async {
    Container.shared.someService.register { ErrorService() }
    let service = Container.shared.someService()
    #expect(service.error == "Oops")
  }

  @Test(.container, arguments: Parameters.allCases) 
  func testB(parameter: Parameters) async {
    Container.shared.someService.register { MockService(parameter: parameter) }
    let service = Container.shared.someService()
    #expect(service.parameter == parameter)
  }
}
```
Not only does each test get its own freshly initialized container, but `Container.shared` is different for each test as well!

TaskLocal solves our problem of code that accesses `Container.shared` directly, as well as any code that does so *indirectly* using our injection property wrappers.
```swift
class MyClass {
   @Injected(\.myService) var service // accesses Container.shared internally
   ...
}
```

Brilliant!

*While we're here, I'd like to thank Ákos Grabecz for spearheading the development of this solution.*

#### FactoryTesting

Before we move on, you might notice the import of the `FactoryTesting` module which contains support for container traits. 
```swift
import Testing
import FactoryTesting
```
To import FactoryTesting you'll need to add that dependency to your project and test target.
```
.testTarget(name: "MyAppTests", dependencies: [
  "MyApp", 
  "FactoryTesting"
])
```
> Warning: Do not import `FactoryKit` into the Test target. That can lead to duplicate factories and indeterminate behavior.

#### Suite Trait

You can go one step further (or higher if you will) by adding the trait to your `@Suite` macro as below.

```swift
// define container trait for entire suite of tests
@Suite(.container)
struct AppTests {
  // test inherits .container trait from suite  
  @Test() 
  func testA() async {
    ...
  }

  // test inherits container trait from suite  
  @Test(arguments: Parameters.allCases) 
  func testB(parameter: Parameters) async {
    ...
  }
}
```

One thing to remember with the suite-based approach is that its [isRecursive](https://developer.apple.com/documentation/testing/suitetrait/isrecursive) property is always `true`, which means that all of your child suites and test functions inherit the trait. 

```swift
// define container trait for entire suite of tests
@Suite(.container)
struct AppTests {
  // test gets container trait from suite
  @Test() 
  func testA(parameter: Parameters) async {
    ...
  }

  @Suite
  struct AppChildTests {
    // test still gets container trait from outermost suite 
    @Test 
    func testA() async { 
        ...
    }
  }
}
```

#### Custom Containers

If you work with your own custom containers you can still use the Factory provided `ContainerTrait` since its generic parameter is constrained to the `SharedContainer` protocol. 

You have to do just two things:

1. Attach the `@TaskLocal` macro to the `shared` instance of your own custom container.
```swift
public final class CustomContainer: SharedContainer {
  @TaskLocal public static var shared = CustomContainer()
  public let manager = ContainerManager()
}
```
2. Add the following code to your test project to define your own custom trait:
```swift
extension Trait where Self == ContainerTrait<CustomContainer> {
    static var customContainer: ContainerTrait<CustomContainer> {
        .init(shared: CustomContainer.$shared, container: .init())
    }
}
```
3. Then just use your custom container trait as you would any other.
```swift
struct AppTests {
  @Test(.customContainer) 
  func testA() async {
    ...
  }
}
```

See <doc:Containers> for more information about creating custom containers.

#### Multiple Containers

If for some reason a given piece of code is dependent upon multiple containers, then note that Factory has you covered there too. Just specify both traits.

```swift
struct AppTests {
  @Test(.container, .customContainer) 
  func testA() async {
    let sut1 = Container.shared.service()
    let sut2 = CustomContainer.shared.service()
    ...
  }
}
```
It should go without saying, but you can use as many traits as needed.

### Transforming Sugar

Seeing the previous examples you might have noticed that unit tests which involve some Factory maintained dependency tend to start by registering new dependencies.

Factory provides a way to put these registrations right next to the `ContainerTrait` with a trailing closure so your dependency registrations are in a more prominent position and separate from your test code.

```swift
struct AppTests {
  @Test(.container {
    $0.someService.register { ErrorService() }
    $0.someOtherService.register { OtherErrorService() }
  }) 
  func testA() async {
    let service = Container.shared.someService()
    let otherService = Container.shared.someOtherService()
    #expect(service.error == "Oops")
    #expect(otherService.error == "OtherOops")
  }
}
```

#### Actor Isolated Factory's

You might run across one limitation with the transforming sugar if you're accessing actor isolated Factory's in Swift 6. Consider the following:

```swift
extension Container {
  @MainActor
  var mainActorType: Factory<MainActorType> {
      self { SomeMainActorType() }
  }
}

struct SomeSuite {
  @Test(.container {
    // ERROR: Call to main actor-isolated initializer 'init()' in a synchronous nonisolated context
    $0.mainActorType.register { MockActorType() }
  })
  func foo() {
    ...
  }
```
The solution is simple since our transforming closure is async. Just use await to bridge the gap.
```swift
struct SomeSuite {
  @Test(.container {
    await $0.mainActorType.register { MockActorType() }
  })
  func foo() {
    ...
  }
```

## Container Injection

There is another way to achieve parallel testing without using `ContainerTrait`. 

If you inject a specific container instance into your view models or services, then you can build and inject a separate container for each set of tests so that parallel testing works.

```swift
class ContentViewModel {
    let service2: MyServiceType
    init(container: Container) {
        service2 = container.service()
    }
}

@Suite struct AppTests {
  @Test(arguments: Parameters.allCases) func testA(parameter: Parameters) {
    let container = Container()
    container.someService.register { MockService(parameter: parameter) }
    let model = ContentViewModel(container: container)
    #expect(model.parameter == parameter)
  }

  @Test func testB() async throws {
    let container = Container()
    container.someService.register { ErrorService() }
    let model = ContentViewModel(container: container)
    #expect(model.error == "Oops")
  }
}
```

Here, every instance of ContentViewModel gets its own dedicated container and as such parallel testing should work as expected.

Note, however, if any dependencies use singletons then you need to go back to using traits as the standard implementation wraps both the shared container and the singleton cache.

Did I mention before that singletons can be problematic?

## Xcode UITesting

UITesting can be more challenging, in that we're now to dealing with an active, running application. We have our existing tools, of course, but the issue is often complicated by the fact that we may want to change the application's behavior *before* it gets to RunLoop.main and starts idling.

How?

One solution is passed parameters.

The test case is fairly straightforward.

```swift
import XCTest

final class FactoryDemoUITests: XCTestCase {
    func testExample() throws {
        let app = XCUIApplication()
        app.launchArguments.append("mock1") // passed parameter
        app.launch()

        let welcome = app.staticTexts["Mock Number 1! for Michael"]
        XCTAssert(welcome.exists)
    }
}   
```
And then in our application we use Factory's auto registration feature to check the launch arguments to see what registrations we might want to change.
```swift
import Foundation
import Factory

extension Container: AutoRegistering {
    public func autoRegister() {
        #if DEBUG
        if ProcessInfo().arguments.contains("mock1") {
            myServiceType.register { MockServiceN(1) }
        }
        #endif
    }
}
```
Or you can simplify things with an `arg` context that accomplishes the same thing.
```swift
import Foundation
import Factory

extension Container: AutoRegistering {
    public func autoRegister() {
        #if DEBUG
        myServiceType.onArg("mock1") { MockServiceN(1) }
        #endif
    }
}
```
There are many contexts for testing, previews, and even UITesting. See <doc:Contexts> for more.

Obviously, one can add as many different test cases and registrations as needed.
