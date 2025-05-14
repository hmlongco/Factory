# Resolution Cycles

What's a resolution cycle, and why should we care?

## Overview

A resolution cycle is kicked off the instant you ask a Factory to resolve its dependency and return an instance of the desired object. 

You ask for a dependency, and in the process it asks for it's dependencies, and so on, until everyone has what it needs to do its job.

```swift
let demo = Container.shared.cycleDemo()
```
So we asked, and Factory was more than happy to make a demo object for us. But let's consider what happened under the hood.

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
    // just a demo class
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
    private var implementsAB: Factory<AServiceType&BServiceType> {
        self { ImplementsAB() }
            .graph
    }
    var networkService: Factory<NetworkService> {
        self { NetworkService() }
    }
    var preferences: Factory<Preferences> {
        self { Preferences() }
    }
}
```

So when we ask Factory to make an instance of CycleDemo it calls the factory closure and asks Swift to make an instance of the object. But in order for that object to complete initialization it first needs resolve the two injected property wrappers, starting with aService.

So Factory is called again to make an aService. But that Factory punts and calls *another* Factory to get an instance of implementsAB.

That Factory, in turn, asks Swift to make ImplementsAB, but again, *that* object needs to initialize with a NetworkService. Another call through Factory.

## Tracing the Resolution Cycle

Let's turn on Factory's trace function and see what we get. (Trace was edited for clarity.)
```
0: Container.cycleDemo<CycleDemo> = N:105553131389696
1:     Container.aService<AServiceType> = N:105553119821680
2:         Container.implementsAB<AServiceType & BServiceType> = N:105553119821680
3:             Container.networkService<NetworkService> = N:105553119770688
1:     Container.bService<BServiceType> = N:105553119821680
2:         Container.implementsAB<AServiceType & BServiceType> = C:105553119821680
```
Again, cycleDemo wants an aService from implementsAB, which wants a networkService. That's created and returned, and now cycleDemo wants an bService from implementsAB. 

But implementsAB was cached in the graph scope, and so the same instance (105553119821680) is returned (and which is why we don't see networkService resolved again).

And with that Swift provides us with a fully initialized instance of CycleDemo and its dependencies.

That's a resolution cycle.

You ask for a dependency, and in the process it asks for its dependencies, and so on, until everyone has what it needs to do its job.

When the initial result is returned that resolution cycle is over.

Until next time.

## Missing Preferences

You might be wondering why the Preferences object used by NetworkService didn't appear. That's because it's using a LazyInjected property wrapper, and as such the Preferences object won't be created until it's accessed for the first time.

Kicking off its own resolution cycle.

## The Missing Graph

Just for fun, let's consider what we'd see if we did:
```swift
let demo = CycleDemo()
```
Here's the trace.
```
0: Container.aService<AServiceType> = N:105553119775792
1:     Container.implementsAB<AServiceType & BServiceType> = N:105553119775792
2:         Container.networkService<NetworkService> = N:105553119821280
0: Container.bService<BServiceType> = N:105553119821360
1:     Container.implementsAB<AServiceType & BServiceType> = N:105553119821360
2:         Container.networkService<NetworkService> = N:105553119821600
```
Since we didn't ask Factory to make CycleDemo for us we're not going to see it on the trace. But what we do see are **two** instances of networkService being resolved and two distinct instances of implementsAB. What gives?

That's because aService and bService are two distinct property wrappers, and each one is going to be initialized separately. (Note the "0:" prefix which indicates the start of a new resolution cycle.)

Why? Let's look at the class again.
```swift
class CycleDemo {
    @Injected(\.aService) var aService: AServiceType
    @Injected(\.bService) var bService: BServiceType
}
```
When we ask Swift to make an instance of CycleDemo that object needs to initialize its properties. So Swift first asks the aService property wrapper to initialize and it does. But this is the first time Factory was involved, so a resolution cycle starts... and ends.

And then Swift asks the bService property wrapper to initialize and it does. And so a second resolution cycle starts... and ends.

Since a graph scope only caches object for the length of a single resolution cycle, a new instance of ImplementsAB is created for each cycle, which means that a new network service was created for each one as well.

Swap out implementsAB's graph scope for, say, singleton, and you'd see the following:
```
0: Container.aService<AServiceType> = N:105553118258000
1:     Container.implementsAB<AServiceType & BServiceType> = N:105553118258000
2:         Container.networkService<NetworkService> = N:105553118258480
0: Container.bService<BServiceType> = N:105553118258000
1:     Container.implementsAB<AServiceType & BServiceType> = C:105553118258000
```
Which is what we'd expect.  (Note that now aService and bService are the same instance.)

Our initial example worked because we asked Factory to make CycleDemo for us, and so everything after the fact occurred within a single resolution cycle launched from a single Factory.

Graph scopes are powerful tools, and well-suited to a specific type of problem. That said, they're also tricky to get right. Use them with caution.
