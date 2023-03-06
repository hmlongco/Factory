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
Fatal error: circular dependency chain - CircularA > CircularB > CircularC > CircularA
```
With the above information in hand we should be able to find the problem and fix it.

We could fix things by changing CircularC's injection wrapper to `LazyInjected` or, better yet, `WeakLazyInjected` in order to avoid a retain cycle. 

But a better solution would probably entail finding and breaking out the functionality that `CircularA` and `CircularC` are depending upon into a *third* object they both could include.

Circular dependencies such as this are usually a violation of the Single Responsibility Principle, and should be avoided.

> Important: Due to the overhead involved, circular dependency detection only occurs when running the application in DEBUG mode. The code is stripped out of production builds for improved performance.

## Disabling CDC Detection

If needed circular dependency chain detectiong can be disabled by setting the detection limit to zero.
```swift
Container.shared.manager.dependencyChainTestMax = 0
```
The default value for `dependencyChainTestMax` is 10. That means the detector fires if the same class type appears during a single resolution cycle more than 10 times.

This value can be increased (or decreased) as needed.

