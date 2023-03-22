# Modular Development

Using Factory in a project with multiple modules.

## Overview

When you want to use a dependency injection system like Factory with multiple modules you often run into a “Who’s on first” dilemma.

Let’s say that we have a ModuleP which specifies an abstract AccountLoading protocol.
```swift
public protocol AccountLoading {
    func load() -> [Account]
}
```
Next, we have an accounting module, ModuleA, that displays our accounts, but needs one of those loaders to load them.

Moving on, we have one last module, let’s call this one ModuleB, that knows how to build loaders of any type that we need.

And, finally, we have our application itself.

![Diagram of Application Architecture](MultiModule)

Note that ModuleA and ModuleB are independent. Neither one knows about the other one, but both have a direct dependency on ModuleP, our master of models and protocols.

This is a classic modular contractural pattern.

But we have an application to build. So how does ModuleA get an instance of an account loader, when it knows nothing about ModuleB?

Let's take a look.

## Implementation in same module as protocol

Before we answer the above question, let's look at a related, but simpler problem. 

Let's say we have a module called Networking that provides (surprise, surprise) a service that conforms to a Networking protocol. Let's also say that module *also* provides the implementation of that service.

![Diagram of Application Architecture](Networking)

In that case our implementation is quite simple. Inside Networking we define the public protocol *and* we publicly define the Factory to produce it.

```swift
// Public Protocol
public protocol Networking {
    func load<T>() async throws -> T
}

// Public Factory
extension Container {
    public var network: Factory<Networking> { self { Network() } }
}

// Private Implementation
private class Network: Networking {
    public func load<T>() async throws -> T {
        ...
    }
}
```
Note that our implementation is private and hidden from the rest of the world, which can only see and receive some instance that conforms to Networking.

Got it? Anything that can see our protocol can *also* see a source that provides an instance of it.

Okay, let's return to our originally scheduled program.

## Implementation in different module from protocol

To recap, we have a protocol that's defined in ModuleP and the concrete type AccountLoader exists in ModuleB … but ModuleA doesn’t know about it. It can’t know about.

But the code in ModuleA needs to be able to see a Factory in order to resolve it. And that Factory must have a definition, but it can't, because it can't see ModuleB.

Who’s on first?

It's a dilemma, but fortunately it's not a serious one. The solution is twofold. 

First, everyone imports Factory. From an architectural perspective, the dependency injection system is an invisible layer that lives above and wraps around everything else.

Next, we implement part of the "same module" solution shown above, but with a twist, adding the following Factory definition to **ModuleP**.

```swift
// Public Factory
extension Container {
    public var accountLoading: Factory<AccountLoading?> { self { nil } }
}
```

Now, as with our earlier solution, anyone who imports ModuleP can see the protocol and can also see a Factory that promises to provide one. 

That Factory, however, doesn't know how to construct one, so we make its definition optional and code it's factory closure to return a nil.

Now we're cooking. But where does our missing ingredient come from?

## Wiring Things Together

Since our application is the only piece of the puzzle that can see ModuleP, ModuleA, and ModuleB, it's up to the application to wire everything together.

So let's go into our main application and create a spot where we can cross-wire all of the pieces together.

The key to the puzzle is `AutoRegistering`, a protocol which defines a function that's guaranteed to be called before any Factory is resolved.

```swift
import ModuleP
import ModuleA
import ModuleB

extension Container: AutoRegistering {
    func autoRegister {
        accountLoader.register { AccountLoader() }
        ...
    }
}
```
Since this file can see all of the modules, it's tasked with registering a new factory closure for `accountLoader` that provides the actual instance of `AccountLoader` from ModuleB.

And … that's it. Prior to the first resolution Factory will call `autoRegister` in order to setup everything needed for the application to run.

## Optionals

Note that our code will need to account for the optional service in actual use.

```swift
class ViewModel: ObservableObject {
    @Injected(\.accountLoader) var loader
    @Published var accounts: [Account] = []
    func load() {
        guard let loader else { return }
        accounts = loader.load()
    }
}
```

But that one line is the price we pay for compile-time safety. Should we fail to cross-wire a module dependency, our application isn't going to crash. It may not run correctly, but it isn't going to crash.

The `AutomaticRegistration.swift` file in the demo application illustrates a few examples of the cross-module registration technique. Check it out.

## Explicitly Unwrapped Optionals

We could, of course, do the following.
```swift
class ViewModel: ObservableObject {
    @Injected(\.accountLoader) var loader: AccountLoading!
    @Published var accounts: [Account] = []
    func load() {
        accounts = loader.load()
    }
}
```
We could … but let's not do that, shall we? Explicitly unwrapping the optional works if we've wired everything together, but could crash if we haven't.

Which sort of defeats Factory's primary goal in life - Safety.

## Promises

Some might worry that an developer might slip up and forget to provide a needed registration. While that's certainly possible, the probability is that you'd tend to notice such a thing the first time you tried to test a new feature.

One *could* also do something like the following …
```swift
extension Container {
    public var accountLoading: Factory<AccountLoading?> { self { fatalError() } }
}
```
Which provides the factory closure with `fatalError` that will cause the application to crash the very first time an unregistered Factory is accessed. And some people actually prefer this "fail fast" approach.

But the problem of course, is what happens if the application is shipped and the registration was never provided? Or was accidentally removed? In either case the end user goes to screen X, the view model for that screen tries to get an accountLoader … and the application crashes.

Not a good look. Fortunately, Factory 2.1 provides a solution.

```swift
extension Container {
    public var accountLoading: Factory<AccountLoading?> { promised() }
}
```
When run in debug mode and the application attempts to resolve an unregistered accountLoader, `promised()` will trigger a fatalError to inform you of the mistake. But in a released application, `promised()` simply returns nil and your application can continue on.

The feature still won't work of course, but at least the application won't blow up and crash, possibly taking some of your user's data with it.

Promised also cleans up Factory registrations, a nice win that eliminates the rather odd looking `self { nil }` requirement.

## Separating Dependencies

There could well be some cases where ModuleP wants to be truely independent and simply *can't* depend on Factory.

In those cases, we're going to need a level of indirection.

![Diagram of Application Architecture](Services)

Everyone sees what they saw before, plus everyone who's dependent on ModuleP can also see a new module called `Services` which is a new cross-module framework where our empty registrations are defined. `Services` in turn, can only see ModuleP in order to get the model and protocol definitions it needs to create its Factory's.

Our original `accountLoading` Factory, which lived in ModuleP in the original example, now lives in Services.

```swift
// Public Factory
extension Container {
    public var accountLoading: Factory<AccountLoading?> { self { nil } }
}
```
And the application, which can see everything, cross wires the various service registrations provided by `Services` together, just as it did before.

ModuleP is now completely independent.

## Adaptors

There's one last case, that of using some third party library.

In that case, we're often better off implementing an adaptor protocol to wrap the library and provide an agnostic, independent interface to its functionality.

![Diagram of Application Architecture](Adaptor)

This is a good approach to take when faced with third-party analytics libraries or feature managers like LaunchDarkly. 
```swift
// Public Protocol
public protocol Analytics {
    func event(location: String, name: String)
}

// Public Factory
extension Container {
    public var analytics: Factory<Analytics> { self { AnalyticsAdaptor() } }
}

// Private Implementation
private class AnalyticsAdaptor: Analytics {
    public func event(location: String, name: String) {
        // talk to analytics library
    }
}
```

## Mix and Match

In a real world application where multiple modules provide varying sets of features and services, one would probably use all of the techniques mentioned here.

Some modules benefit from the cross-module wiring approach, while other service modules and adaptors can simply provide the public protocols and internal implementations as shown above in the first and last examples.
