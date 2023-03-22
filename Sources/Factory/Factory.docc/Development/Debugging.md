# Debugging

Additional support for debugging resolution cycles, dependency chains and other issue.

## Tracing the Resolution Cycle

When running in DEBUG mode Factory allows you to trace the injection process and see every object created or returned during a given <doc:Cycle>.
```
0: Factory.Container.cycleDemo = CycleDemo N:105553131389696
1:     Factory.Container.aService = AServiceType N:105553119821680
2:         Factory.Container.implementsAB = AServiceType & BServiceType N:105553119821680
3:             Factory.Container.networkService = NetworkService N:105553119770688
1:     Factory.Container.bService = BServiceType N:105553119821680
2:         Factory.Container.implementsAB = AServiceType & BServiceType C:105553119821680
```
Each line in the trace shows the depth (with 0 as the root), the factory called, the type of the service created, and the id/address of the object itself. 

Each address has a prefix indicating whether or not a new object was created (N:) or if an existing object was returned from a scope cache (C:).

Just toggle the trace flag to enable/disable logging.
```swift
Container.shared.manager.trace.toggle()
```
Turning on a trace can be helpful in testing when you want to get an idea of an object's dependency tree. 

Note that enabling trace logging enables it for *all* containers.

One final consideration is that logging the construction of an object will show everything initialized as part of that resolution cycle. Anything created lazily after the fact may not appear in the trace.

## Logging

Trace logs are usually just printed to the system log, but you can change that behavior if needed.
```swift
Container.shared.manager.logger = {
    MyLogger.debug("Factory: \($0)")
}
```
Note this changes the logging behavior for *all* containers.

## Circular Dependency Chain Detection

What's a circular dependency? Let's say that A needs B to be constructed, and B needs a C. But what happens if C was defined such that it needs an A? 

That's a Circular Dependency Chain.

Factory can detect such things and warn you about them during the development process. 

The subject's a bit involved, so there's an entire page devoted to it.

See <doc:Chains>.
