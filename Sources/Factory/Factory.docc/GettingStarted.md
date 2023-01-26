#  Getting Started

Defining a Factory, resolving it, and changing the default behavior.

## Overview

A ``Factory/Factory`` manages the dependency injection process for a specific object or service and produces an object of the desired type
when required. This may be a brand new instance or Factory may return a previously cached value from the specified scope.

### Defining a Factory

Let's define a new Factory that returns an instance of a `ServiceType` protocol. 

To do that we need to extend a Factory ``Container`` and within that container we define a new computed variable of type `Factory<ServiceType>`. The type must be explicity defined, and, as mentioned, is usually a protocol to which the returned dependency conforms.

```swift
extension Container {
    var service: Factory<ServiceType> {
        Factory(self) { MyService() }
    }
}
```

Inside the computed variable we build our Factory, providing it with a refernce to its container (self) and also with a factory closure that creates an instance of our object when needed. 

That Factory is then returned to the caller, usually to be evaluated (see ``Factory/callAsFunction()``). Every time we resolve this particular factory we'll get a new, unique instance of our object.

For convenience, containers also provide a `factory` function that will create the factory and do the binding for us.

```swift
extension Container {
    var service: Factory<ServiceType> {
        factory { MyService() }
    }
}
```

Like SwftUI Views, Factory structs and modifiers are lightweight and transitory. Ther're created when needed
and then immediately discared once their purpose has been served.

### Resolving a Factory

To resolve a Factory and obtain an object or service of the desired type, one simply calls the Factory as s function. 

```swift
let service = container.service()
```

The resolved instance may be brand new or Factory may eturn a cached value from the specified scope.

### Registering a new Factory closure

What happens if we want to change the behavior of a Factory? What if we need to change the nature of the system at runtime, or we want to provide mocks and testing doubles? 

It's easy. Just register a new closure with the Factory.

```swift
container.service.register {
    MockService()
}
```

This new factory closure overrides the original factory closure and clears the associated scope so that the next time this factory is resolved Factory will evaluate the new closure and return an instance of the newly registered object instead.

> Warning: Registration "overrides" are stored in the associated container. If the container ever goes our of scope, so
will all of its registrations.
