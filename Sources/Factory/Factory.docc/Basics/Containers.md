# Containers

Containers are the cornerstone of Factory 2.0. What are they and how do we use them?

## Overview

Containers are used by Factory to manage object creation, object resolution, and object lifecycles in general.

In Factory 1.0 with its statically defined Factory's a "container" was really just a convenient namespace. But in Factory 2.0 a container is a distinct object that can be referenced, passed around, and deallocated as needed. 

You can even create separate instances of the same container type, each with its own registrations and scope caches.

Factory 2.0 supports true container-based dependency injection.

## Containers and Factories

A Factory definition is a computed property defined within a container extension. Each Factory needs a reference to its container, a scope, and it also requires a factory closure that will produce our dependency when asked to do so.

That's a lot of code, so we usually just ask the enclosing container to make our Factory for us...
```swift
extension Container {
    var service: Factory<MyServiceType> {
        self { MyService() }
    }
}
```
This process is covered in greater detail in <doc:GettingStarted>.

## Resolving a Dependency

Once you've added a Factory to a container you can resolve it.

```swift
let service = Container.shared.service()
```
Bingo. You now have your dependency.

## The Default Container

Factory ships with a single ``Container`` already constructed for your convenience.
```swift
public final class Container: SharedContainer {
    public static var shared = MyContainer()
    public var manager = ContainerManager()
}
```
You've seen it used and extended in all of the examples we've seen thus far, and most projects can simply extend it and go.

## Container.shared

As the default Container definition shows, each container class defined has a statically allocated `shared` instance associated with it.

This instance can be referenced directly if you're using a Service Locator-style pattern.

```swift
let service = Container.shared.service()
```
Or you can use the "shared" container as an application root container and pass it along to whereever it's needed. Let's take a look.

## Passing Containers

Here's an example of passing an instance of a container to a view model and then initializing a service from that container.
```swift
class ContentViewModel {
    let service2: MyServiceType
    init(container: Container) {
        service2 = container.service()
    }
}
```
Addtional examples and methods can be seen on the <doc:Resolutions> page.

## SharedContainer

All containers conform to the ``SharedContainer`` protocol. That basically means that each one must have its own ``ContainerManager`` and implement a static `shared` instance.

SharedContainer also defines some common functionality for each container, like the `unique` convenience function we've seen used throughout.

Note that you can extend SharedContainer with your own Factories.

```swift
extension SharedContainer {
    var commonSerice: Factory<ServiceType> {
        self { MyService() }
    }
}
```
The `commonSerice` Factory will now be available on every container created. 
```swift
let common1 = Container.shared.commonService()
let common2 = MyContainer.shared.commonService()
```

## Custom Containers
In a large project you might want to segregate factories into additional, smaller containers. 

Defining your own container class is simple. Just use the following as a template. 

```swift
public final class MyContainer: SharedContainer {
     public static var shared = MyContainer()
     public var manager = ContainerManager()
}

extension MyContainer {
    var cachedService: Factory<ServiceType> {
        self { MyService() }.cached
    }
}
```
As mentioned, a customer must derive from ``SharedContainer``, have its own ``ContainerManager``, and implement a static `shared` instance. It also must be marked `final`.

Don't forget that if need be you can reach across containers simply by specifying the full `container.factory` path.

```swift
extension PaymentsContainer {
    let anotherService = Factory<AnotherService> { 
        self { AnotherService(using: Container.shared.optionalService()) }
    }
}
```

## Injected Property Wrappers

Property wrappers like `@Injected` and `@LazyInjected` always reference the `shared` container for that class type. Let's get an instance of the `cachedService` object we defined above by providing a keypath to the desired class and service.

```swift
class ContentViewModel: ObservableObject {
    @Injected(\MyContainer.cachedService) var cachedService
}
```
We now have an instance of `cachedService` in our view model, as well as a reference to the same instance cached in `MyContainer.shared.manager`.

See ``Injected``, ``LazyInjected``, ``WeakLazyInjected``, and ``InjectedObject`` for more.

## Registration and Scope Management

As mentioned earlier, factory registrations and scopes are managed by the container on which the dependency was created. Adding a registration or clearing a scope cache on one container has no effect on any other container.

```swift
let containerA = MyContainer()
containerA.register.cachedService { MockService() }

// Will have a MockService
let service1 = containerA.cachedService() 

// Will have a new or prevously cached instance of ServiceType
let service2 = MyContainer.shared.cachedService() 
```
## AutoRegister

From time to time you may find that you need to register or change some instances prior to application initialization. If so you can do the following.
```swift
extension Container: AutoRegistering {
    func autoRegister() {
        someService.register { ModuleB.SomeService() }
    }
}
```
Just make your container conform to ``AutoRegistering`` and provide the `autoRegister` function. This function will be called *once* prior to the very first Factory service resolution on that container.

Note that this can come in handy when you want to register instances of objects obtained across different modules, or change settings in the container manager.

## Resetting a Container

Using `register` on a factory lets us change the state of the system. But what if we need to revert back to the original behavior?

Simple. Just reset it to bring back the original factory closure. Or, if desired, you can reset *everything* back to square one with a single command.
```Swift
container.myService.reset() // resets this factory only
container.manager.reset() // clears all registrations and caches
```
We can also reset registrations and scope caches specifically, leaving the other intact.
```swift
// Reset all registrations, restoring original factories but leaving caches intact
Container.shared.manager.reset(options: .registration)

// Reset all scope caches, leaving registrations intact
Container.shared.manager.reset(options: .scope)
```
You can also reset a specific scope cache while leaving the others intact.
```swift
Container.shared.manager.reset(scope: .cached)
```
Note that resetting registrations also resets the container's auto registration flag.

> Important: Resetting a container or scope has no effect whatsoever on anything that's alreay been resolved by Factory. It only ensures that the *next* time a Factory is asked to resolve a dependency that dependency will be a new instance.

## Pushing and Popping State

As with Factory 1.0, the state of a container's registrations and scope caches can be saved (pushed), and then restored (popped).
```swift
// Save the current state
Container.shared.manager.push()

// Make a change
Container.shared.someService.register { MockService() }

// Pop the change and restore the manager's state to what it was before the registration.
Container.shared.manager.pop()

// Gets the original or previously registered service.
let service = Container.shared.someService()
```
This can be handy in an unit test environment. Keep in mind that push/pop uses a stack, so it's possible to push and pop as many times as are needed.

## Releasing a Container

> Warning: If a container ever goes out of scope, so will all of its registrations and cached objects.

To demonstrate, let's see what happens when we create and assign a new container to `MyContainer.shared`. Doing so releases the provious container, along with any registrations or objects that container may have cached. We'll use the `cachedService` Factory we defined above.

```swift
// Create an instance of our cached service.
let service1 = MyContainer.shared.cachedService()

// Repeat, which returns the same cached instance we obtained in service1.
let service2 = MyContainer.shared.cachedService()
assert(service1.id == service2.id)

// Replace the existing shared container with a new one.
MyContainer.shared = MyContainer()

// Trying again gets a new instance since the old container and cache was released.
let service3 = MyContainer.shared.cachedService()
assert(service1.id != service3.id)

// Repeat and receive the same cached instance we obtained in service3.
let service4 = MyContainer.shared.cachedService()
assert(service3.id == service4.id)
```
From a certain point of view, replacing a container with a new one is the ultimate reset mechanism.
