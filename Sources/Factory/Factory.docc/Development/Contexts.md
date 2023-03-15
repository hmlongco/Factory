# Contexts

Changing injection results under special circumstances.

## Overview

Developers often use Factory to mock data for previews and unit tests. Now Factory 2.1 extends these capabilities by allowing them to specify dependencies based on the application's current _context_.

What if, for example, you **never** want your application's analytics library to be called when running unit tests? 

Piece of cake. Just register a new override for that particular context.

```swift
extension Container: AutoRegistering {
    public func autoRegister() {
        #if DEBUG
        container.analytics
            .context(.test) { MockAnalyticsEngine() }
        #endif
    }
}
```
Factory makes it easy.

## Contexts

Factory 2.1 provides quite a few predefined contexts for your use. They are:

* **arg(String)** - application is launched with a particular argument.
* **preview** - application is running in Xcode Preview mode
* **test** - application is running in Xcode Unit Test mode
* **debug** - application is running in Xcode DEBUG mode
* **simulator** - application is running within an Xcode simulator
* **device** - application is running on an actual device

Let's dive in.

## Some Examples

### • onTest

As mentioned, the Factory closure associated with this context is used whenever your application or library is running unit tests using XCTest. And, as with most Factory modifiers, there's also a shortcut version:

```swift
// test context modifier
container.analytics.context(.test) { MockAnalyticsEngine() }
// test shortcut
container.analytics.onTest { MockAnalyticsEngine() }
```
Having contexts built into Factory saves you from having to go to StackOverflow in an attempt to figure out how to do the same thing for yourself.
```swift
if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
    container.analytics.register { MockAnalyticsEngine() }
}
```
Plus it's a lot easier to remember...

### • onPreview

This specifies a dependency that will be used whenever your app or module is running SwiftUI Previews.

```swift
container.myServiceType.onPreview { MockService() }
```
Which obviously makes your preview code itself much simpler.
```swift
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
```
You can, of course, still use the mechanisms shown in <doc:Previews>.
### • onDebug

Triggered whenever your application is running in debug mode in simulators, on a device, or when running unit tests.

> Note: that there's no `release` context. Just use the standard `register` syntax in that case.

### •  onSimulator / onDevice

Pretty apparent. What may not be so apparent, however, is that unlike all of the above these two contexts are also available in release builds. 

### • onArg(String)

The `arg` context is a powerful tool to have when you want to UITest your application and you want to change it's behavior.

As shown in the <doc:Testing> section the test case itself is pretty standard.

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
The shortcut comes in the application itself when we want to check the launch arguments to see what registrations we might want to change.
```swift
import Foundation
import Factory

extension Container: AutoRegistering {
    public func autoRegister() {
        #if DEBUG
        myServiceType
            .onArg("mock0") { EmptyService() }
            .onArg("mock1") { MockServiceN(1) }
            .onArg("error") { MockError(404) }
        #endif
    }
}
```

## Multiple Contexts

As you may have noticed above in the `arg` example, multple contexts work just as you'd expect and are specfied using Factory's modifier syntax.

```swift
container.myServiceType
    .onPreview { MockService() }
    .onTest { UnitTestMockService() }
```
Which brings us to...

## Context Precedence

Registering multiple contexts could lead one to wonder just which one will be used in a situation where multiple contexts apply. Here's the order of evaluation.

* **arg(...)**
* **preview** *
* **test** *
* **simulator**
* **device**
* **debug** *
* **registered factory** (if any)
* **original factory**

Note that any context maked with an asterisk (*) is only available in a DEBUG build. The executable functionality is stripped from release builds.
