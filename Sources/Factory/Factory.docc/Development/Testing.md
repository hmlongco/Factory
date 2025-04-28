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

## Changing, Not Rebuilding

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

## Pushing and Popping State

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

## Diving Deeper

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

## Rebuilding The Container

In your unit test setUp function you can also just reset the container and start over from scratch. No teardown needed.

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

## Passed Containers

You can also pass the container into the view model itself.

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

## Common Setup

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

So what to do about it? Well, there are two approaches. Scoping and resetting.

### Scoping Singletons

Factory delivers the global singleton scope with the `@TaskLocal` macro being attached to it. With this simple trick we can scope our tests to run in their own isolated task context.

```swift
Scope.$singleton.withValue(Scope.singleton.clone()) {
    // We're inside the context of the current Task. Meaning that we can re-register our singletons here without affecting other tests that use the same singletons with different states.
    Container.shared.someSingletonFactory.register { MyNewMock() }
}
```

Doing this in every unit test might lead to a lot of repetition and a pattern in your XCTestCases. To make it simpler you can override the `invokeTest()` function as below:

```swift
override func invokeTest() {
    Scope.$singleton.withValue(Scope.singleton.clone()) {
        Container.shared.someSingletonFactory.register { MyNewMock() } // You might not add it here. See reasoning below.
        super.invokeTest()
    }
}
```

But remember that by doing the above you will scope **every** unit test function inside the given XCTestCase to their own scope where `MyNewMock` is registered. 
If you need different types being registered in your different unit tests, then you might want to just call `super.invokeTest()` inside the `withValue`'s trailing closure and setup your registrations one-by-one in your unit tests.

*Jump to the end for information on using Factory for singleton testing with Swift Testing in Xcode 16.*

### Resetting Singletons

While it is suggested to use the above detailed `@TaskLocal` approach, if needed we can reset *every* cached singleton with just a single method call. Just call reset on that particular scope.

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

So all that said, we can deal with them. But as a general rule, singletons can complicate your life, your code, and your tests, and as such they should be avoided and only be used when there's an overriding need for there to be one and only one instance of an object.

Got that, Highlander?

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

## Xcode 16 and Swift Testing

The challenge that Swift Testing brought to our lives is that it defaults to parallel test runs. While this can speed up test runs significantly it's not that straightforward. How should we eanble our dependencies to act differently for different test cases?

Luckily there is an answer: [Test Scoping Traits](https://developer.apple.com/documentation/testing/trait), with which we can make our tests local to their task.

### Scoping

Consider the following.

```swift
import Testing

struct AppTests {
  @Test(arguments: Parameters.allCases) func testA(parameter: Parameters) {
    Container.shared.someService.register { MockService(parameter: parameter) }
    let service = Container.shared.someService()
    #expect(service.parameter == parameter)
  }

  @Test func testB() async throws {
    Container.shared.someService.register { ErrorService() }
    let service = Container.shared.someService()
    #expect(service.error == "Oops")
  }
}
```

Examine the code and you'll see that the two tests both register different values for `someService` on the same shared container. 

Which means that these tests could suffer from race conditions should they be run in parallel.

Which in turn would result in tests failing randomly. And that's bad.

Factory is leveraging the power of Test Scoping Traits and @TaskLocals in the form of `ContainerTrait` to resolve this problem.

#### Test Trait

By using it inside your `@Test` macro, you can make sure that your unit test runs in their own isolated contexts.

```swift
import Testing

struct AppTests {
  @Test(.container, arguments: Parameters.allCases) func testA(parameter: Parameters) {
    Container.shared.someService.register { MockService(parameter: parameter) }
    let service = Container.shared.someService()
    #expect(service.parameter == parameter)
  }

  @Test(.container) func testB() async throws {
    Container.shared.someService.register { ErrorService() }
    let service = Container.shared.someService()
    #expect(service.error == "Oops")
  }
}
```

#### Suite Trait

You can go one step further (or higher if you will) by adding it to your `@Suite` macro as below.

```swift
import Testing

@Suite(.container)
struct AppTests {
  @Test(arguments: Parameters.allCases) func testA(parameter: Parameters) {
    Container.shared.someService.register { MockService(parameter: parameter) }
    let service = Container.shared.someService()
    #expect(service.parameter == parameter)
  }

  @Test func testB() async throws {
    Container.shared.someService.register { ErrorService() }
    let service = Container.shared.someService()
    #expect(service.error == "Oops")
  }
}
```

One thing to remember with the suite-based approach is that its [isRecursive](https://developer.apple.com/documentation/testing/suitetrait/isrecursive) property is always `true`, which means that all of your child suites and test functions inherit the trait. 

See:

```swift
import Testing

@Suite(.container) // container trait is defined here in the parent suite
struct AppTests {
  @Test(arguments: Parameters.allCases) func testA(parameter: Parameters) {
    Container.shared.someService.register { MockService(parameter: parameter) }
    let service = Container.shared.someService()
    #expect(service.parameter == parameter)
  }

  @Suite // gets .container trait from parent suite implicitly
  struct AppChildTests {
    @Test func testB() async throws { // gets .container trait from parent suite implicitly
        Container.shared.someService.register { ErrorService() }
        let service = Container.shared.someService()
        #expect(service.error == "Oops")
    }
  }
}
```

### Custom Containers

If you work with your own custom container, you can still use the Factory provided `ContainerTrait` since its generic parameter is constrained to the `SharedContainer` protocol. You have to do just two things:

1. Attach the `@TaskLocal` macro the `shared` instance of your custom container.
2. Add the below code to your project:

```swift
extension Trait where Self == ContainerTrait<CustomContainer> {
    static var customContainer: ContainerTrait<CustomContainer> {
        .init(shared: CustomContainer.$shared, container: .init())
    }
}
```

See <doc:Containers>

### Transforming Sugar

Seeing the previous examples you might have noticed that unit tests which involve some Factory maintained dependency tend to start with some re-registration.

Factory provides a way to put these registrations right next to the `ContainerTrait` with a trailing closure, so your dependency registrations are in a more prominent place.

```swift
struct AppTests {
  @Test(
    .container {
      $0.someService.register { ErrorService() }
      $0.someOtherService.register { OtherErrorService() }
    }
  ) 
  func testB() {
    let service = Container.shared.someService()
    let otherService = Container.shared.someOtherService()
    #expect(service.error == "Oops")
    #expect(otherService.error == "OtherOops")
  }
}
```

#### Limitations With The Transforming Sugar

The transforming sugar has one limitation with isolated registrations in Swift 6. Consider the following:

```swift
extension Container {
    @MainActor
    var isolatedDependency: Factory<IsolatedProtocol> {
        self { IsolatedImplementation() }
    }
}

struct SomeSuite {
  @Test(.container {
      $0.isolatedDependency.register { IsolatedImplementation() } // Main actor-isolated property 'isolatedDependency' can not be referenced from a Sendable closure

  })
  func foo() {...}
}
```

As our registration is isolated to the MainActor our transforming closure cannot access it without risking data race.

There are multiple approaches to consider as the solution for this problem:
1. If you can, you should move the global actor isolation to your protocol (`IsolatedProtocol`) or type (`IsolatedImplementation`) declaration site.
2. You could create your own `ContainerTrait` which accepts a transforming closure that is isolated to the MainActor.

### Don't Be Too DRY

You might want to move your dependencies to your test suite level for a DRY-er code as below:

```swift
struct Flaky: Sendable {
    let container = Container()
    let foo = Foo()

    @Test
    func example() async throws {
        Container.$shared.withValue(self.container) { // Problem 1#
            Container.shared.fooBarBaz.register { self.foo } // Problem 2#
            // some #expect here about fooBarBaz
        }
    }
}
```

Do **NOT** do that as it leads to flaky tests. Inside the trailing closure of the `withValue` function you should not refer to any objects which are external to the task local's context. That's just how `@TaskLocal` works.

If you really want to go to that direaction, then what you can do is to change your external property to a function:

```swift
func foo() -> Foo { Foo() }
```

However the suggested way for test scoping is as below:

```swift
struct Stable {
    @Test(.container {
        $0.fooBarBaz.register { Foo() }
    })
    func example() async throws {
        // some #expect here about fooBarBaz
    }
}
```

### Container Injection

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
