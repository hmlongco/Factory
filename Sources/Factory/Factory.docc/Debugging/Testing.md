# Testing

Using Factory for Unit and UI Testing.

## Overview

Factory has a few additional provisions added to make unit testing easier. Let's take a look.

## Pushing and Popping State

In your unit test setUp function you can *push* the current state of the registration system and then register and test anything you want.

The following example assumes we're using the shared container.

```swift
final class FactoryCoreTests: XCTestCase {

    override func setUp() {
        super.setUp()
        Container.shared.push()
        Container.shared.setupMocks()
    }
    
    override func tearDown() {
        super.tearDown()
        Container.shared.pop()
    }
    
    func testSomething() throws {
        Container.shared.myServiceType.register(factory: { MockService() })
        let model = Container.shared.someViewModel()
        model.load()
        XCTAssertTrue(model.isLoaded)
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
        app.launchArguments.append("-mock1")
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

#if DEBUG
extension Container: AutoRegistering {
    public func autoRegister() {
        if ProcessInfo().arguments.contains("-mock1") {
            myServiceType.register { MockServiceN(1) }
        }
    }
}
#endif
```
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
