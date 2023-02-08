# Containers

Containers are the cornerstone of Factory 2.0. What are they and how do we use them?

## Overview

Containers are used by Factory to manage object creation, object resolution, and object lifecycles in general.

Factory's are defined within container extensions, and must be provided with a reference to that container on initialization.
```swift
extension Container {
    var service: Factory<ServiceType> {
        Factory(self) { MyService() }
    }
}
```
 Registrations and scope caches will persist as long as the associated container remains in scope.

## Passing Containers

Containers can be passed along from object to object.

Here's an example of passing an instance of a container to a view model and initializing a service from that container.
```swift
class ContentViewModel: ObservableObject {
    let service2: MyServiceType
    init(container: Container) {
        service2 = container.service()
    }
}
```
Addtional examples and methods can be seen on the <doc:Resolutions> page.

## The Default Container

Factory ships with a single ``Container`` already constructed for your convenience.
```swift
public final class Container: SharedContainer {
    public static var shared = MyContainer()
    public var manager = ContainerManager()
}
```
You've seen it used in many of the examples shown thus far. Just extend it to add your own Factory's.
```swift
extension Container {
    var service: Factory<ServiceType> {
        makes { MyService() }
    }
}
```

## Custom Containers
If you'd like to define your own container, use the following as a template. 

A contaimer must derive from ``SharedContainer``, have its own ``ContainerManager`` and implement a static `shared` instance.
```swift
public final class MyContainer: SharedContainer {
     public static var shared = MyContainer()
     public var manager = ContainerManager()
}

extension MyContainer {
    var someService: Factory<ServiceType> {
        makes { MyService() }
    }
}
```
Property wrappers like @Injected always reference the `shared` container for that class type.
```swift
class ContentViewModel: ObservableObject {
    @Injected(\MyContainer.anotherService) var anotherService
}
```

## SharedContainer

``SharedContainer`` implements the protocol to which all containers must conform. It also provides a bit of default functionality for each container.

Note that you can extend SharedContainer with your own Factory definitions. T

```swift
extension SharedContainer {
    var commonSerice: Factory<ServiceType> {
        makes { MyService() }
    }
}
```
Those Factory's will be available on every container created. 
```swift
let common1 = Container.shared.commonService()
let common2 = MyContainer.shared.commonService()
```
> Important: Registrations and scopes will be managed by the container on which the dependency was created.

## Topics

### <!--@START_MENU_TOKEN@-->Group<!--@END_MENU_TOKEN@-->

- <!--@START_MENU_TOKEN@-->``Symbol``<!--@END_MENU_TOKEN@-->
