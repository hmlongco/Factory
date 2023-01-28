#  Getting Started

Defining a Factory, resolving it, and changing the default behavior.

## Overview

``Factory/Factory`` manages the dependency injection process for a specific object or service and produces an object of the desired type when required. 

### Defining a Factory

Most container-based dependency injection systems require you to define that a given dependency is available for injection and many require some sort of factory or mechanism that will provide a new instance of the service when needed.

Factory, as you may have guessed from the name, is no exception. Here's a simple registration that returns a `ServiceType` dependency. 

```swift
extension Container {
    var service: Factory<ServiceType> {
        Factory(self) { MyService() }
    }
}
```

To accomplish that we need to extend a Factory ``Container``. Within that container we define a new computed variable of type `Factory<ServiceType>`. This type must be explicity defined, and is usually a protocol to which the returned dependency conforms.

Inside the computed variable we construct our Factory, providing it with a refernce to its container (self) and also with a factory closure that's used tp create an instance of our object when needed. That Factory is then returned to the caller, usually to be evaluated (see ``Factory/callAsFunction()``). Every time we resolve resolve the returned factory we'll get a new, unique instance of our object.


Like SwftUI Views, Factory structs and modifiers are lightweight and transitory value types. Ther're created when needed and then immediately discarded once their purpose has been served.

Containers also provide a convenient shortcut that will do the factory creation and binding to `self` for us.

```swift
extension Container {
    var service: Factory<ServiceType> {
        self { MyService() }
    }
}
```

For more examples of Factory definitions that define scopes, use constructor injection, and do parameter passing, see: <doc:Registrations>.

### Resolving a Factory

To resolve a Factory and obtain an object or service of the desired type, one simply calls the Factory as s function. Here we use the `shared` container that's provided for each and every container type. 

```swift
let service = Container.shared.service()
```
The resolved instance may be brand new or Factory may return a cached value from the specified ``Scope``.

If you're passing an instance of a container around to your views or view models, just call it directly.

```swift
let service = container.service()
```
Finally, you can also use the @Injected property wrapper and specify a keyPaths to the desired dependency.

```swift
@Injected(\.service) var service: ServiceType
```
Unless otherwise specified, the @Injected property wrapper looks for dependencies in the standard shared container provided by Factory, so the above example is functionally identical to the `Container.shared.service()` example shown earlier. Here's one pointing to your own container.

```swift
@Injected(\MyCustomContainer.service) var service: ServiceType
```
### Registering a new Factory closure

What happens if we want to change the behavior of a Factory? What if the system requires changes during runtime, or what if we want our factory to provide mocks and testing doubles? 

It's easy. Just register a new closure with the Factory.

```swift
container.service.register {
    MockService()
}
```

This new factory closure overrides the original factory closure and clears the associated scope so that the next time this factory is resolved Factory will evaluate the new closure and return an instance of the newly registered object instead.

> Warning: Registration "overrides" and scope caches are stored in the associated container. If that container ever goes out of scope, so will all of its registrations and cached objects.