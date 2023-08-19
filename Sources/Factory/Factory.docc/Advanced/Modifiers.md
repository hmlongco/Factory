# Factory Modifiers

Considerations when defining and redefining a Factory's behavior.

## Overview

When Factory was redesigned for Factory 2.0 the decision was made to provide many of Factory's configuration options using a modifier syntax similar to that of SwiftUI.

Modifiers make it easy to define a Factory's options in the Factory registration...

```swift
extension Container {
    public func myService: Factory<MyServiceType>() {
        self { MyService() }
            .singleton
            .onTest { MockAnalyticsEngine() }
    }
}
```
After the fact, when the application runs...

```swift
extension Container: AutoRegistering {
    public func autoRegister() {
        #if DEBUG
        myService
            .onArg("mock0") { EmptyService() }
            .onArg("mock1") { MockServiceN(1) }
            .onArg("error") { MockError(404) }
        #endif
    }
}
```
Or even under direct program control...
```swift
func logout() {
    ...
    Container.shared.userProviding.register { nil }
    ...
}
```

## Modifiers

Factory provides quite a few modifiers for your use, but they basically break down into a few different categories:

* Scopes: Defines just how long a particular dependency persists.
* Registrations: Updating or changing the dependency to be provided.
* Contexts: Defines Factory overrides that should occur when the app is running is a specific context.
* Decorators: Defines code to be run whenever a dependency is resolved.
* Resets: Reseting a Factory's registrations or scope cache.

Plus a few more, but that covers most of them.

## Resolving a Factory

As mentioned in <doc:GettingStarted>, there are many ways to resolve a Factory. Here's a simple example that resolves the `myService` Factory we defined above.
```swift
let myService = Container.shared.myService()
```
This code asks `Container.shared.myService` for a Factory, and then asks the Factory to resolve itself using its `callAsFunction` resolution shortcut.

But consider the original definition.
```swift
extension Container {
    public func myService: Factory<MyServiceType>() {
        self { MyService() }
            .singleton
            .onTest { MockAnalyticsEngine() }
    }
}
```
The `myService` variable is a computed function. 

When it's 'called, the `self { MyService() }` code asks the parent container to build a Factory with the passed closure. That Factory is modified with a scope option, and then again with an `onTest` context modifier.

That fully configure Factory is what's returned to the caller, either to be modified further, or resolved as we've done here.

That may seem like a lot of overhead, but it actually isn't. As we've mentioned elsewhere, Factory's are like SwiftUI Views. Its structs and modifiers are lightweight and transitory value types, created when needed and then immediately discarded once their purpose has been served.

There are, however, several things we need to consider.

## The Factory Wins

Let's say, for example, that we run the following code to change the factory context during a unit test.
```swift
Container.shared.myService.onTest { NullAnalyticsEngine() }
```
And then a bit further down we resolve our service.
```swift
let myService = Container.shared.myService()
```
Now the question is: Do we now have an instance of `NullAnalyticsEngine`, or `MockAnalyticsEngine`?

As may be apparent from the section title, we actually have an instance of `MockAnalyticsEngine`. But why? Didn't we just change it?

We did. But there are a couple of things going on here. 

First is that we told Factory to cache the instance in the singleton scope. So it's entirely possible that we could be seeing the cached value.

Second is that when we resolved `myService` we called `Container.shared.myService` again, which built a new Factory, which defined a scope, **and which once more defined `onTest`**.

And so Factory went with its most recent definition.

## SwiftUI
Similar behavior can be seen in SwiftUI itself.
```swift
struct innerView: View {
    var body: some View {
        Text("Hello")
            .foregroundColor(.red)
    }
}
struct outerView: View {
    var body: some View {
        innerView()
            .foregroundColor(.green)
    }
}
```
Here the color of the "Hello" text is red, despite our attempt to override it. The innermost bound property wins.

So what can we do?

## External Setup

One solution is to be careful what we put inside our factory definition.

```swift
extension Container {
    public func myService: Factory<MyServiceType>() {
        self { MyService() }
            .singleton
    }
}
```
And then we add anything we might want to change later as an externally defined option.

```swift
extension Container: AutoRegistering {
    public func autoRegister() {
        #if DEBUG
        myService
            .onTest { MockAnalyticsEngine() }
        #endif
    }
}
```
## Reset

Keep in mind that if  we want to change a Factory's 'context but that Factory defines a scope, then we're also going to need to manually clear the scope cache for that object. 
```swift
Container.shared.myService
    .onTest { NullAnalyticsEngine() }
    .reset(.scope)
```
> Warning: With `reset` make sure you specify that you only want to clear the scope. Calling `reset` without a parameter clears everything, including contexts like the one you just set! 

## Chaining

Another solution that might work in some circumstances is chaining.

```swift
let myService = Container.shared.myService
    .onTest { NullAnalyticsEngine() }
    .()
```
This way the internal definitions are applied, then onTest is updated, and then we immediately resolve the service using the latest definition.

Or we can use a new modifier added to Factory 2.1.

## Once

The `once` modifier basically tells the system that anything that occurs before it should only be done **once**
```swift
extension Container {
    public func myService: Factory<MyServiceType>() {
        self { MyService() }
            .singleton
            .onTest { MockAnalyticsEngine() }
            .once()
    }
}
```
So when we do:
```swift
Container.shared.myService.onTest { NullAnalyticsEngine() }
```
Our Factory is constructed, the singleton is applied, the internal onTest is applied, and then the new onTest is applied.

And then later, when we resolve our service.
```swift
let myService = Container.shared.myService()
```
Our Factory is constructed, but the internal singleton modifier has already occurred once, so it's ignored, keeping the current value. Similarly, the internal onTest has already occurred once, so it too is ignored, again maintaining the current value.

Which means that we get our `NullAnalyticsEngine`, just like we wanted.

Once is a useful tool to have around, but in reality it's probably best simply to be careful in regard to what goes into our basic Factory definition.
