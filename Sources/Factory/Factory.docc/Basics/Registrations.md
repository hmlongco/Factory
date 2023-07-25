# Sample Registrations

There are many ways to register dependencies with Factory. Here are a few examples.

### Basic
Example of a basic dependency registration in a Factory 2.0 container.

```swift
extension Container {
    var service: Factory<MyServiceType> {
        self { MyService() }
    }
}
```
This registered dependency returns a new, unique version of `MyServiceType` whenever it's asked to do so.

You can also go ahead and use the full, formal definition, constructing the Factory yourself and passing it a reference to its enclosing container.
```swift
extension Container {
    var service: Factory<MyServiceType> {
        Factory(self) { MyService() }
    }
}
```
We prefer the more concise version, and that's what we'll use going forward.

> Note: The container helper functions are `@inlinable` and as such there's no performance penalty incurred when calling them.

### Scopes
Examples of defining scoped services in a Factory 2.0 container. 

```swift
extension Container {
    var standardService: Factory<MyServiceType> {
        self { MyService() }
    }
    var cachedService: Factory<MyServiceType> {
        self { MyService() }
            .cached
    }
    var singletonService: Factory<SimpleService> {
        self { SimpleService() }
            .singleton
    }
    var sharedService: Factory<MyServiceType> {
        self { MyService() }
            .shared
            .decorator { print("DECORATING \($0.id)") }
    }
    var customScopedService: Factory<SimpleService> {
        self { SimpleService() }
            .scope(.session)
    }
}
```

### Constructor Injection
Example of service with constructor injection that requires another service as a parameter. To obtain that dependency we simply ask the Factory dedicated to that service to provide one for us.

```swift
extension Container {
    var constructedService: Factory<MyConstructedService> {
        self { MyConstructedService(service: self.cachedService()) }
    }
    var cachedService: Factory<MyServiceType> {
        self { MyService() }.cached
    }
}
```

### Parameters
Like it or not, some services require one or more parameters to be passed to them in order to be initialized correctly. In that case use ``ParameterFactory``.
```swift
extension Container {
    var parameterService: ParameterFactory<Int, ParameterService> {
        self { ParameterService(value: $0) }
    }
}
```
Note that we also needed to specify the type of our parameter.

### Same Types
Example of correctly handling multiple instances of the same type.

```swift
extension Container {
    var string1: Factory<String> {
        self { "String 1" }
    }
    var string2: Factory<String> {
        self { "String 2" }
    }
    var string3: Factory<String> {
        self { "String 3" }
    }
    var string4: Factory<String> {
        self { "String 4" }
    }
}
```

### Inside Custom Containers
You've seen factory registrations done within container *extensions*, but it should also be noted that we can also create them within our own custom containers.
```swift
final class ServiceContainer: SharedContainer {
    // CONFORMANCE
    static var shared = ServiceContainer()
    var manager = ContainerManager()
    
    // DEFINE FACTORY
    var service1: Factory<MyServiceType> {
        self { MyService() }
    }

    // DON'T DO THIS
    lazy var service2: Factory<MyServiceType> = self {
        MyService()
    }
}
```
Note the last "lazy" definition of `service2`. This may seem like a reasonable equivalent, but it hides a fatal flaw. Factories are designed to be transient. They're lightweight structs created to do a job and then they're discarded.

In order to accomplish this task, each Factory that's created needs to maintain a strong reference to its enclosing container. And now you should be able to see the problem.

> Warning: Creating a "lazy" Factory and assigning it to it's enclosing class will create a reference cycle.

Should you attempt to release such a container it will never go away, and you'll have a memory leak on your hands.

### Static Factories
Example of a static Factory 2.0 registration container.

```swift
extension Container {
    static var oldSchool: Factory<School> {
        Factory(shared) { School() }
    }
}

let school = Container.oldSchool
```
Note that we referenced the class "shared" container. That container will manage the registrations and scopes for our Factory.

While you *can* create static Factory's in this manner, such usage should be considered to be deprecated. Static factories are also no longer compatible with the various ``Injected`` property wrappers due to the lack of keyPaths.

Better to simply define the Factory as a standard computed variable within a Container, and then access the "shared" version.

```swift
extension Container {
    var newSchool: Factory<School> {
        self { School() }
    }
}

let school = Container.shared.newSchool
```
