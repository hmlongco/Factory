# Migration

Moving from 1.x to 2.0

## Overview

Factory 2.0 is planning for the future, and as such it needs to break from the past.

Containers in Factory 1.X were essentially namespaces, and not actual object instances that could be passed around. That made the overall syntax slightly cleaner, but the tradeoff resulted in a lack of functionality and the static class definitions prevented Factory from being used in anything other than a Service Locator role.

That wasn't good.

So that changed in Factory 2.0. Instead of defining Factory's as static variables on a class, they're now defined and returned as computed variables on the container itself. And instances of a given container can be created and shared as needed.

Let's take a look.

## Defining a Factory

Most container-based dependency injection systems require you to define that a given dependency is available for injection and many require some sort of factory or mechanism that will provide a new instance of the service when needed.

Factory, as you may have guessed from the name, is no exception. Here's a simple registration that returns a `ServiceType` dependency. 

```swift
extension Container {
    var service: Factory<ServiceType> {
        self { MyService() }
    }
}
```

We extended a Factory `Container` and within that container we defined a new computed variable of type `Factory<ServiceType>`. The type must be explicitly defined, and is usually a
protocol to which the returned dependency conforms.

So our computed variable needs to return a Factory. But Factory's are complex creatures. They need to communicate with their enclosing containers and they need to be provided with a closure that can be called to create an instance of our dependency when required. 

As such, a complete, formal Factory definition would look like this...
```swift
var service: Factory<ServiceType> {
    Factory(self, scope: .unique) { 
        MyService()
    }
}
```
But we can do better. Factory provides a bit of syntactic sugar that asks the enclosing container to make our factory for us.

```swift
var service: Factory<ServiceType> {
    self { MyService() }
}
```

That Factory is then returned to the caller, usually to be evaluated (see ``Factory/callAsFunction()``). Every time we resolve this factory we'll get a new, unique instance of our object.

Just for reference, here's are the Factory 1.x and 2.0 registration definitions side by side.

```swift
extension Container {
    // Factory 1.x
    static var service = Factory<ServiceType> { MyService() }
    
    // Factory 2.0
    var service: Factory<ServiceType> { self { MyService() } }
}
```

The new version is one character longer. Hey. I tried... ;)

Like SwiftUI Views, Factory structs and modifiers are lightweight and transitory. In Factory 2.0 they're created when needed and then immediately discarded once their purpose has been served.

See the <doc:Containers> page for a lot more on the subject.

## Resolving a Factory

To resolve a Factory and obtain an object or service of the desired type, one simply calls the Factory as a function. If you're passing an instance of a container around to your views or view models, just call it directly.

```swift
let service = container.service()
```
The resolved instance may be brand new or Factory may return a cached value from the specified ``Scope``.

We can also use the `shared` container that's provided for each and every container type.

```swift
let service = Container.shared.service()
```
Note that this is fundamentally the same as the Service Locator pattern used in Factory 1.0.

```swift
// Factory 1.0 resolution
let service = Container.service()
```

Finally, you can also use the @Injected property wrapper. That's changed too, and now uses keyPaths to indicate the desired dependency.

```swift
@Injected(\.service) var service: ServiceType
```
The @Injected property wrapper looks for dependencies in the shared container, so this example is functionally identical to the `Container.shared.service()` version shown above.

See ``Injected``, ``LazyInjected``, ``WeakLazyInjected``, and ``InjectedObject`` for more.

```swift
// Factory 1.0 version for reference
@Injected(Container.service) var service: ServiceType
```

## Registering a new Factory closure

What happens if we want to change the behavior of a Factory? What if the system changes during runtime, or what if we want our factory to provide mocks and testing doubles? 

It's easy, and works pretty much the same as it did before. Just register a new closure with the Factory from its container.

```swift
container.service.register {
    MockService()
}
```

This new factory closure overrides the original factory closure and clears the associated scope so that the next time this factory is resolved Factory will evaluate the new closure and return an instance of the newly registered object instead.


> **Warning**: Registration "overrides" and scope caches are stored in the associated container. If the container ever goes out of scope, so will all of its registrations.

Again, see the <doc:Containers> page for a lot more on the subject.

## Scopes
    
Scopes behave exactly as they did before, although they're now defined using a modifier syntax on the Factory. 

```swift
extension Container {
    var singletonService: Factory<ServiceType> {
        self { MyService() }.singleton
    }
    var decoratedSharedService: Factory<MyServiceType> {
        self { MyService() }
            .shared
            .decorator { print("DECORATING \($0.id)") }
    }
}
```
Factory 2.0 also provides additional modifiers for all of the known scopes, as well as a few more like the per-factory decorator shown above.

## Resetting

When doing tests and in other situations it was relatively common to reset factories and factory scopes and we can still do that today. Again, it's just the syntax that's a little different.

Just keep in mind that in Factory 1.0 registrations and scopes were global, whereas today we ask our container to do the job for us.
```swift
// Reset everything based in that container.
Container.shared.manager.reset()

// Reset all registrations, restoring original factories but leaving caches intact
Container.shared.manager.reset(options: .registration)

// Reset all scope caches, leaving registrations intact
Container.shared.manager.reset(options: .scope)
```
You can also reset a specific scope cache while leaving the others intact.
```swift
Container.shared.manager.reset(scope: .cached)
```
Resetting a container only affects that container.

## Creating Custom Containers and Scopes

Again, a bit different. Rather than duplicate the documentation for doing so, please checkout the appropriate section in the <doc:Containers> or <doc:Scopes> documentation.
