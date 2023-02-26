# Designing Factory

Rationale behind the design decisions made in Factory 1.0 and 2.0

## Factory 1.0

The first dependency injection system I wrote was [Resolver](https://github.com/hmlongco/Resolver). That open source project, while quite powerful and still in use in many applications, suffered from a few drawbacks.

1. Resolver required pre-registration of all services up front. 
2. Resolver uses type inference to dynamically find and return registered services from a container.

The first drawback is relatively minor. While preregistration could lead to a performance hit on application launch, in practice the process is usually quick and not normally noticeable.

The second issue, however, is more problematic since failure to find a matching registration for that type can lead to an application crash. In real life that isn’t usually a problem as such a thing tends to be noticed and fixed the first time you run a unit test or the second you run the application to see if your newest feature works.

But still... could we do better? That question lead me on a quest for compile-time type safety. Several other systems have attempted to solve this, but I didn't want to have to add a source code scanning and generation step to my build process, nor did I want to give up a lot of the control and flexibility inherent in a run-time-based system.

I also wanted something simple, fast, clean, and easy to use.

Could I have my cake and eat it too?

Turns out I could.

## A Simple Example

Most container-based dependency injection systems require you to define in some way that a given service type is available for injection and many require some sort of factory or mechanism that will provide a new instance of the service when needed.

Factory is no exception. Here's a simple dependency registration as defined for Factory 1.0.

```swift
extension Container {
    static let myService = Factory<MyServiceType> { 
        MyService()
    }
}
```
Unlike Resolver which often requires defining a plethora of nested registration functions, or SwiftUI, where defining a new environment variable requires creating a new EnvironmentKey and adding additional getters and setters, here we simply add a new `Factory` to the default container. When called, the factory closure is evaluated and returns an instance of our dependency. That's it.

Injecting and using the service where needed is equally straightforward. Here's one way to do it.

```swift
class ContentViewModel: ObservableObject {
    @Injected(Container.myService) private var myService
    ...
}
```
Here our view model uses one of Factory 1.0's `@Injected` property wrappers to request the desired dependency. Similar to `@Environment` in SwiftUI, we provide the property wrapper with a reference to a factory of the desired type and it resolves that type the moment `ContentViewModel` is created.

And that's the core mechanism. In order to use the property wrapper you *must* define a factory. That factory *must* return the desired type when asked. Fail to do either one and the code will simply not compile. 

As such, Factory is compile-time safe.

But there was still a problem...

## Service Locator

Containers in Factory 1.X were essentially namespaces, and not actual object instances that could be passed around. That made the overall syntax a lot cleaner, but that tradeoff resulted in a lack of functionality and the static class definitions prevented Factory from being used in anything other than a Service Locator role.

```swift
class ContentViewModel: ObservableObject {
    var myService = Container.myService()
    ...
}
```
While that sufficed for many projects, it prevented Factory from being used or considered in projects that wanted or needed a true container-based Dependency Injection system.

So that changed in Factory 2.0. Instead of defining Factory's as static variables on a class, they're now defined and returned as computed variables on the container itself. And instances of a given container can be created, shared, and passed around as needed.

Let's take a look.

## Factory 2.0

Here's our earlier example, rebuilt for Factory 2.0.
```swift
extension Container {
    var myService: Factory<MyServiceType> {
        Factory(self) { 
            MyService()
        }
    }
}
```
Instead of a static on the container class, this Factory is a computed variable on the container iteself. Inside we define and return a Factory that matches the value promised by the computed variable.

This double-definition mechanism is required primarily because Swift doesn't allow extensions to define new variables on an existing objects. As such, a computed variable was really the only choice.

Note that when we create the actual Factory we pass it a reference to the enclosing container.

Unlike Factory 1.0 which maintained a global store, each Factory 2.0 container stores its own registrations and manages its own scope caches. This means that we can create multiple instances of the same container type, each with their own distinct registrations and caches.

## Convenience

While the formal definition does the trick, most of the time it's easier to use some syntactic sugar and just ask the container to make our Factory for us.

```swift
extension Container {
    var myService: Factory<MyServiceType> {
        self { MyService() }
    }
}
```

## Scopes
Factory scopes work just as they did before, only now they're defined using a SwiftUI-like modifier syntax. 
```swift
extension Container {
    var myService: Factory<MyServiceType> {
        self { MyService() }
            .singleton
    }
}
```

## Container.shared

Each container class defined has a statically allocated `shared` instance associated with it.

This instance can be referenced directly if you still want to use a Service Locator-style pattern.

```swift
let service = Container.shared.service()
```
Or you can use the "shared" container as an application root container and pass it along to whereever it's needed. Let's take a look.

## Passing Containers

Here's an example of passing an instance of a container to a view model and then initializing a service from that container. Doing this sort of thing is the primary rationale behind the changes to Factory for 2.0.
```swift
class ContentViewModel {
    let myService: MyServiceType
    init(container: Container) {
        myService = container.myService()
    }
}
```
Addtional examples and methods can be seen on the <doc:Resolutions> page.

## Injected Property Wrappers

Property wrappers like @Injected and @LazyInjected always reference the `shared` container for that class type. 

```swift
class ContentViewModel: ObservableObject {
    @Injected(\.myService) var myService
}
```
Factory 2.0 also updates the syntax to use keyPaths, much like SwiftUI environment variables.

See ``Injected``, ``LazyInjected``, ``WeakLazyInjected``, and ``InjectedObject`` for more.

## Breaking Changes

Unfortunately, supporting true container-based DI required some major surgery on Factory 1.0's syntax across the board. That's why it's version 2.0.

But under the hood Factory 2.0 still gives you the same feature set provided by 1.0, while adding and supporting new functionality and use cases.

I think it's worth it.
