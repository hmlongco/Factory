![](https://github.com/hmlongco/Factory/blob/main/Logo.png?raw=true)

A new approach to Container-Based Dependency Injection for Swift and SwiftUI.

## Factory 2.0

Welcome to the new version of Factory! Factory 2.0 offers true dependency injection container support as well as several other new features.

**This is a breaking change from 1.X.X.**

If you download this branch you'll find initial DocC Documentation for the project, as well as working unit tests and a working code sample.

The Factory source code is also fairly heavily documented.

## Migration

A migration document is in the works, but for now here's some information on Factory's new syntax to get stated.

## Containers

Containers in Factory 1.X were essentially namespaces, and not actual object instances that could be passed around. That made the overall syntax cleaner, but the tradeoff resulted in a lack of functionality and the static class definitions prevented Factory from being used in anything other than a Service Locator role.

That changed in Factory 2.0. Instead of defining Factory's as static variables on a class, they're now defined and returned as computed variables on the container itself. And instances of a given container can be created and shared as needed.

Let's take a look.

## Defining a Factory

Most container-based dependency injection systems require you to define that a given dependency is available for injection and many require some sort of factory or mechanism that will provide a new instance of the service when needed.

Factory, as you may have guessed from the name, is no exception. Here's a simple registration that returns a `ServiceType` dependency. 

```swift
extension Container {
    var service: Factory<ServiceType> {
        Factory(self) { MyService() }
    }
}
```

To accomplish that we needed to extend a Factory ``Container``. Fortunately, Factory provides one of those for us, so we'll use it.

Within that container we define a new computed variable of type `Factory<ServiceType>`. This type must be explicity defined, and is usually a protocol to which the returned dependency conforms.

Inside the computed variable we construct our Factory, providing it with a refernce to its container (self) and also with a factory closure that's used tp create an instance of our object when needed. That Factory is then returned to the caller, usually to be evaluated (see ``Factory/callAsFunction()``). Every time we resolve the returned factory we'll get a new, unique instance of our object.

Containers also provide a convenient shortcut to make our factory and do our binding for us.

```swift
extension Container {
    var service: Factory<ServiceType> {
        make { MyService() }
    }
}
```

Just for reference, here's the Factory 1.x version.

```swift
extension Container {
    static var service = Factory<ServiceType> {
        MyService()
    }
}
```

Like SwftUI Views, Factory structs and modifiers are lightweight and transitory. In Factory 2.0 they're created when needed and then immediately discarded once their purpose has been served.

## Resolving a Factory

To resolve a Factory and obtain an object or service of the desired type, one simply calls the Factory as s function. Here we use the `shared` container that's provided for each and every container type. 

```swift
let service = Container.shared.service()
```
The resolved instance may be brand new or Factory may return a cached value from the specified ``Scope``.

If you're passing an instance of a container around to your views or view models, just call it directly.

```swift
let service = container.service()
```
Finally, you can also use the @Injected property wrapper. It now uses keyPaths to indicate the desired dependency.

```swift
@Injected(\.service) var service: ServiceType
```
The @Injected property wrapper looks for dependencies in the shared container, so this example is functionally identical to the `Container.shared.service()` example above.

## Registering a new Factory closure

What happens if we want to change the behavior of a Factory? What if the system changes during runtime, or what if we want our factory to provide mocks and testing doubles? 

It's easy. Just register a new closure with the Factory.

```swift
container.service.register {
    MockService()
}
```

This new factory closure overrides the original factory closure and clears the associated scope so that the next time this factory is resolved Factory will evaluate the new closure and return an instance of the newly registered object instead.

> Warning: Registration "overrides" and scope caches are stored in the associated container. If the container ever goes out of scope, so will all of its registrations.

## Scopes

Scopes behave as they did before, although they're now defined using a modifier syntax on the Factory.

```swift
extension Container {
    var sharedService: Factory<ServiceType> {
        make { MyService() }.shared
    }
}
```

## Documentation

Current documentation can be found here: [Factory Documentation](https://hmlongco.github.io/Factory/documentation/factory).

There's more coming, but I can only write so fast, so stay tuned.

## License

Factory is available under the MIT license. See the LICENSE file for more info.

## Author

Factory is designed, implemented, documented, and maintained by [Michael Long](https://www.linkedin.com/in/hmlong/), a Lead iOS Software Engineer and a Top 1,000 Technology Writer on Medium.

* LinkedIn: [@hmlong](https://www.linkedin.com/in/hmlong/)
* Medium: [@michaellong](https://medium.com/@michaellong)
* Twitter: @hmlco

Michael was also one of Google's [Open Source Peer Reward](https://opensource.googleblog.com/2021/09/announcing-latest-open-source-peer-bonus-winners.html) winners in 2021 for his work on Resolver.

## Additional Resources

* [Factory and Functional Dependency Injection](https://betterprogramming.pub/factory-and-functional-dependency-injection-2d0a38042d05)
* [Factory: Multiple Module Registration](https://betterprogramming.pub/factory-multiple-module-registration-f9d19721a31d?sk=a03d78484d8c351762306ff00a8be67c)
* [Resolver: A Swift Dependency Injection System](https://github.com/hmlongco/Resolver)
* [Inversion of Control Design Pattern ~ Wikipedia](https://en.wikipedia.org/wiki/Inversion_of_control)
* [Inversion of Control Containers and the Dependency Injection pattern ~ Martin Fowler](https://martinfowler.com/articles/injection.html)
* [Nuts and Bolts of Dependency Injection in Swift](https://cocoacasts.com/nuts-and-bolts-of-dependency-injection-in-swift/)
* [Dependency Injection in Swift](https://cocoacasts.com/dependency-injection-in-swift)
* [Swift 5.1 Takes Dependency Injection to the Next Level](https://medium.com/better-programming/taking-swift-dependency-injection-to-the-next-level-b71114c6a9c6)
* [Builder: A Declarative UIKit Library (Uses Factory in Demo)](https://github.com/hmlongco/Builder)
