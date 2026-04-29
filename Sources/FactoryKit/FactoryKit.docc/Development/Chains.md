# Circular Dependency Chains

Detecting and solving Circular Dependency Chains.

## Circular Dependency Chain Detection

What's a circular dependency? Let's say that A needs B to be constructed, and B needs a C. But what happens if C needs an A? 

Examine the following class definitions.
```swift
class CircularA {
    @Injected(\.circularB) var circularB
}

class CircularB {
    @Injected(\.circularC) var circularC
}

class CircularC {
    @Injected(\.circularA) var circularA
}
```

Attempting make an instance of `CircularA` is going to result in an infinite loop. 

Why? Well, A's injected property wrapper needs a B in to construct an A. Okay, fine. Let's make one. But B's wrapper needs a C, which can't be made without injecting an A, which once more needs a B... and so on. Ad infinitum.

This is a circular dependency chain.

## Resolution

Unfortunately, by the time this code is compiled and run it's too late to break the cycle. We've effectively coded an infinite loop into our program. 

All Factory can do in this case is die gracefully and in the process dump the dependency chain that indicates where the problem lies.
```
2022-12-23 14:57:23.512032-0600 FactoryDemo[47546:6946786] Factory/Factory.swift:393: 
FACTORY: Circular dependency on Container.recursiveA
```
With the above information in hand we could start walking recursiveA's dependency tree to find the problem... but Factory provides an easier way. Just turn on trace prior to creating recursiveA.
```swift
Container.shared.manager.trace.toggle()
let a = Container.shared.recursiveA()
```
With the trace log in hand, the cycle becomes obvious.
```
0: FactoryKit.Container.circularA<FactoryDemo.CircularA>
1:     FactoryKit.Container.circularB<FactoryDemo.CircularB>
2:         FactoryKit.Container.circularC<FactoryDemo.CircularC>
3:             FactoryKit.Container.circularA<FactoryDemo.CircularA>
```
CircularC is attempting to inject an instance of CircularA, and we can see that in the code.
```swift
class RecursiveC {
    @Injected(\.recursiveA) var a: RecursiveA?
    init() {}
}
```
We could fix things by changing CircularC's injection wrapper to `LazyInjected` or, better yet, `WeakLazyInjected` in order to avoid a retain cycle. 

But a better solution would probably entail breaking out some of the functionality from RecursiveA and creating a *third* object that RecursiveA *and* RecursiveC could both include.

Circular dependencies such as this are usually a violation of the Single Responsibility Principle, and should be avoided.

> Important: Due to the overhead involved, circular dependency detection only occurs when running the application in DEBUG mode. The code is stripped out of production builds for improved performance.

## Disabling CDC Detection

Circular dependency chain detection can be disabled if desired.
```swift
Container.shared.manager.circularDependencyTestingEnabled = false
```
This value is global to all containers.

