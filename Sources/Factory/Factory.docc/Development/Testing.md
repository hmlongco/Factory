# Testing

Using Factory for Unit and UI Testing.

## Overview

Factory has a few additional provisions added to make unit testing easier. Let's take a look.

## Pushing and Popping State

In your unit test setUp function you can *push* the current state of the registration system and then register and test anything you want.

Then in the teardown you can *pop* the stack, eliminating all of your changes and restoring the container to its original state before the push.

This lets each set of tests start from the same state, irregardless of what the prior tests had changed.

The following example assumes we're using the shared container.

```swift
final class FactoryCoreTests: XCTestCase {

    override func setUp() {
        super.setUp()
        Container.shared.manager.push()
        Container.shared.setupMocks()
    }
    
    override func tearDown() {
        super.tearDown()
        Container.shared.manager.pop()
    }
    
    func testSomething() throws {
        Container.shared.myServiceType.register(factory: { MockService() })
        let model = Container.shared.someViewModel()
        model.load()
        XCTAssertTrue(model.isLoaded)
    }

    func testError() throws {
        Container.shared.myServiceType.register(factory: { MockErrorService() })
        let model = Container.shared.someViewModel()
        model.load()
        XCTAssertTrue(model.isError)
    }
}
```
## Rebuilding The Container

In your unit test setUp function you can also just create a new container and start over from scratch. No teardown needed.

```swift
final class FactoryCoreTests: XCTestCase {

    override func setUp() {
        super.setUp()
        Container.shared = Container()
        Container.shared.setupMocks()
    }
    
    func testSomething() throws {
        Container.shared.myServiceType.register(factory: { MockService() })
        let model = Container.shared.someViewModel()
        model.load()
        XCTAssertTrue(model.isLoaded)
    }
}
```

## Passed Containers

Or you can pass the container into the view model itself.

```swift
final class FactoryCoreTests: XCTestCase {

    var container: Container!

    override func setUp() {
        super.setUp()
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

## Xcode UI Testing

We can use the autoregistration feature mentioned earlier to help us out when running UI Tests. The test case is fairly straightforward.

```swift
import XCTest

final class FactoryDemoUITests: XCTestCase {
    func testExample() throws {
        let app = XCUIApplication()
        app.launchArguments.append("mock1")
        app.launch()

        let welcome = app.staticTexts["Mock Number 1! for Michael"]
        XCTAssert(welcome.exists)
    }
}   
```
And then in the application we check the launch arguments to see what registrations we might want to change.
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
        myServiceType.onArg("mock1") { 
            MockServiceN(1)
        }
        #endif
    }
}
```
There are many contexts for testing, previews, and even UITesting. See <doc:Contexts> for more.

Obviously, one can add as many different test cases and registrations as needed.

## Common Setup

As shown above, if we have several mocks that we use all of the time in our previews or unit tests, we can also add a setup function to a given container to make this easier.

```swift
extension Container {
    func setupMocks() {
        myService.register { MockServiceN(4) }
        sharedService.register { MockService2() }
    }
}
```
Or again, if we always want the same result whenver we're previewing any screen, just set it up once in the autoRegister function using a `preview` context:

```swift
extension Container: AutoRegistering {
    public func autoRegister() {
        #if DEBUG
        myService.onPreview { MockServiceN(4)MockServiceN(1) }
        sharedService.onPreview { MockService2() }
        #endif
    }
}
```
