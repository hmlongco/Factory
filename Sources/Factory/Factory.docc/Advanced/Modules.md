# Protocols and Modular Development

Using Factory in a project with multiple modules.

## Overview

When you want to use a dependency injection system like Factory with multiple modules you often run into a “Who’s on first” dilemma.

Let’s say that we have a ModuleP which specifies an abstract AccountLoading protocol.
```swift
public protocol AccountLoading {
    func load() -> [Account]
}
```
Moving on, we have an accounting module, ModuleA, that displays our accounts, but needs one of those loaders to load them.

Finally, we have one more module, let’s call this one ModuleB, that knows how to build loaders of any type that we need.

Note that ModuleA and ModuleB are independent. Neither one knows about the other one, but both have a direct dependency on ModuleP, our master of models and protocols.

This is a classic modular contractural pattern.

But we have an application to build. So how does ModuleA get an instance of an account loader, when it knows nothing about ModuleB?

Let's take a look.

## Implementation in same module as protocol

Before we answer the above question, let's look at a related, but simpler problem. 

Let's say we have a module called Networking that provides (suprise, suprise) a service that conforms to a Networking prototol. Let's also say that module *also* provides the implementation of that service.

In that case our implementation is simple. We define the public protocol *and* we also publicaly define the Factory that provides it.

```swift
public protocol Networking {
    func load<T>() async throws -> T
}

extension Container {
    public var network: Factory<Networking> { self { Network() } }
}

private class Network: Networking {
    public func load<T>() async throws -> T {
        ...
    }
}
```
Note that our implementation is private and hidden to the rest of the world, which only sees and receives some instance that conforms to our Networking protocol.

Got it? Anything which can see our protocol can also see a source that provides that protocol.

Okay, let's return to our orginally scheduled program.

## Implementation in different module from protocol

To recap, we have a protocol that's defined in ModuleP. The concrete type AccountLoader exists in ModuleB… but ModuleA doesn’t know about it. It can’t know about.

But the code in ModuleA needs to be able to see a Factory in order to resolve it. And that Factory must have a definition, but it can't, because it can't see ModuleB.

Who’s on first?

It's a dilemma, but fortunately it's not a serious one. The solution is twofold. 

First, we implement part of the "same module" solution show above, but with a twist, adding the following Factory defintion to ModuleP.

```swift
extension Container {
    public var accountLoading: Factory<AccountLoading?> { self { nil } }
}
```

Now, as with our earlier solution, anyone who imports ModuleP can see the protocol and can also see a Factory that promises to provide one. 

That Factory, however, doesn't know how to construct one, and so we make its defintion optional. As such, we also prrovide it with a Factory closure that also returns nothing.

Next we go into our main application and create a spot where we can cross-wire all of the pieces of our application together.

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
This file can see all of the modules, and as such is tasked with registering a new factory closure with `accountLoader` that provides an actual instance of `AccountLoader` from ModuleB.

And... that's it. Prior to the first resolution Factory will call `autoRegister` in order to setup everything needed for the application to run.

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
But that's the price we pay for compile-time safety. Should we fail to cross-wire a module dependency, our application isn't going to crash. It may not run correctly, but it isn't going to crash.

The `AutomaticRegistration.swift` file in the demo application illustrates a few examples of the cross-module registration technique. Check it out.

## Explicitly Unwrapped Factories
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
We could... but let's not do that, shall we? Explicitly unwrapping the optional works if we've wired everything together, but could crash if we haven't.

Which sort of defeats Factory's primary goal in life.

Safety.

## Resolver

My earlier dependency injection library, Resolver, was a bit simpler in handling these cases. You simply asked Resolver for the desired type... and that was it.

But the flip side of that equation is that once again, if we'd slipped up somewhere and failed to register a needed dependency... then application went boom.
