# Resolution Cycle

What's a resolution cycle, and why should we care?

## Overview

A resolution cycle is kicked off the instant you ask a Factory to resolve its dependency and return an instance of the desired object. 

You ask for a dependency, and in the process it asks for it's dependencies, and so on, until everyone has what it needs to do its job.

```swift
let demo = Container.shared.cycleDemo()
```
So w asked, and Factory was more than happy to make a demo object for us. But let's consider what happened under the hood.

## The Players

Consider the following set of classes and protocols:
```swift
class CycleDemo {
    @Injected(\.aService) var aService: AServiceType
    @Injected(\.bService) var bService: BServiceType
}

public protocol AServiceType: AnyObject {
    var id: UUID { get }
}

public protocol BServiceType: AnyObject {
    var text: String
}

class ImplementsAB: AServiceType, BServiceType {
    @Injected(\.networkService) var networkService
    var id: UUID = UUID()
    var text: String = "AB"
}

class NetworkService {
    @LazyInjected(\.preferences) var preferences
}

class Preferences {
    // some code
}
```
CycleDemo is a class that depends on two protocols, both of which are implemented in ImplementsAB. That class, in turn, requires a NetworkService. And that service wants a preferences object.

## The Registrations

So let's look next at the Factory registrations.
```swift
extension Container {
    var cycleDemo: Factory<CycleDemo> {
        self { CycleDemo() }
    }
    var aService: Factory<AServiceType> {
        self { self.implementsAB() }
    }
    var bService: Factory<BServiceType> {
        self { self.implementsAB() }
    }
    var networkService: Factory<NetworkService> {
        self { NetworkService() }
    }
    var preferences: Factory<Preferences> {
        self { Preferences() }
    }
    private var implementsAB: Factory<AServiceType&BServiceType> {
        self { ImplementsAB() }.graph
    }
}
```

So when we ask Factory to make an instance of CycleDemo it calls the factory closure and asks Swift to make an instance of the object. But in order for that object to complete initialization it first needs resolve the two injected property wrappers, starting with aService.

So Factory is called again to make an aService. But that Factory punts and calls *another* Factory to get an instance of implementsAB.

That Factory, in turn, asks Swift to make ImplementsAB, but again, *that* object needs to initialize with a NetworkService. Another call through Factory.

## Tracing the Resolution Cycle

Let's see what we'd get if we put print statements inside each of our Factory's.
```
Container.cycleDemo
Container.aService
Container.implementsAB
Container.networkService
Container.bService
Container.implementsAB
```
Again, cycleDemo wants an aService from implementsAB, which wants a networkService. That's returned, and so an initialized ImplementsAB is returned, and finally aService is returned. Now cycleDemo wants an bService from implementsAB. 

But implementsAB was cached in the graph scope, and so the same instance is returned (and which is why we don't see networkService resolved again).

And now, finally, Swift can return a fully initialized isntance of CycleDemo.

That's a resolution cycle.

You ask for a dependency, and in the process it asks for it's dependencies, and so on, until everyone has what it needs to do its job.

When the initial result is returned that resolution cycle is over.

Until next time.
