# Testing

Using Factory for Unit and UI Testing.

## Overview

Dependency injection exists to manage and decouple dependencies among objects; making the code more modular, maintainable, and testable. It says so right on the label.

As you've already seen, the main mechanism provided by Factory to accomplish this is registration. Going into the dependency system and registering a new type, typically a mock or stub or spy, in order for that type to be injected into the code under test.

```swift
Container.shared.accountLoading.register { MockNoAccounts() }
```
But Factory has other enhancements designed to make unit testing and user interface testing simpler and easier. 

Some, like <doc:Contexts> you may have already seen and used. Others, like pushing/popping container state, resetting, and so on, are discussed below.

Before we look at them, it's important to first understand Xcode's test process and environment, and consider what that means when writing your own unit tests using Factory.

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

So what to do about it? Well, if needed we can reset *every* cached singleton with just a single method call. Just call reset on that particular scope.

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
