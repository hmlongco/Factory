# Containers

Containers are the cornerstone of Factory 2.0. What are they and how do we use them?

## Overview

In Factory 1.0 a "Container" was just a namespace. In 2.0 Containers can be created, referenced, passed around, and deallocated as needed.

Containers are used by Factory to manage object creation, object resolution, and object lifecycles in general.

## Containers and Factory's

Factory's are defined within container extensions, and must be provided with a reference to that container on initialization.
```swift
extension Container {
    var service: Factory<ServiceType> {
        Factory(self) { MyService() }
    }
}
```
Containers also provides a set of "helper" functions that will make a properly bound Factory for us. 
```swift
extension Container {
    var convenientService: Factory<MyServiceType> {
        makes { MyService() }
    }
}
```
Once you've added a Factory to a container you can resolve it.

```swift
let service = Container.shared.service()
```

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

Containers can be passed along from object to object.

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

Each ``Container`` defined conforms to the ``SharedContainer`` protocol. That basically means that one must have its own ``ContainerManager`` and implement a static `shared` instance.

SharedContainer also defines some common functionality for each container, like the afrementioned `makes` convenience function.

Note that you can extend SharedContainer with your own Factory's.

```swift
extension SharedContainer {
    var commonSerice: Factory<ServiceType> {
        makes { MyService() }
    }
}
```
The `commonSerice` Factory will now be available on every container created. 
```swift
let common1 = Container.shared.commonService()
let common2 = MyContainer.shared.commonService()
```

## Custom Containers
If you'd like to define your own container class you can! Just use the following as a template. 

```swift
public final class MyContainer: SharedContainer {
     public static var shared = MyContainer()
     public var manager = ContainerManager()
}

extension MyContainer {
    var cachedService: Factory<ServiceType> {
        makes { MyService() }.cached
    }
}
```
A contaimer must derive from ``SharedContainer``, have its own ``ContainerManager``, implement a static `shared` instance, and be marked `final`.


## Injected Property Wrappers

Property wrappers like @Injected and @LazyInjected always reference the `shared` container for that class type. Let's get an instance of the `cachedService` object we defined above by providing a keypath to the desired class and service.

```swift
class ContentViewModel: ObservableObject {
    @Injected(\MyContainer.cachedService) var cachedService
}
```
We now have an instance of `cachedService` in our view model, as well as a reference to the same instance cached in `MyContainer.shared.manager`.

See ``Injected``, ``LazyInjected``, and ``WeakLazyInjected`` for more.

## Registration and Scope Management

As mentioned earlier, registrations and scopes are managed by the container on which the dependency was created. 

> Warning: If a container ever goes out of scope, so will all of its registrations and cached objects.

To demonstrate, let's see what happens when we create and assign a new container to `MyContainer.shared`. Doing so releases the provious container, along with any registrations or objects that container may have cached. We'll use the `cachedService` Factory we defined above.

```swift
// Creates a service.
let service1 = MyContainer.shared.cachedService()

// Now get it again, getting the same instance of our service from the cached scope.
let service2 = MyContainer.shared.cachedService()

// Replace the shared container
MyContainer.shared = MyContainer()

// Trying again gets a new instance since the old scope cache was released.
let service3 = MyContainer.shared.cachedService()

// Doing it one last time will give us the same cached instance we have in service3.
let service4 = MyContainer.shared.cachedService()
```
