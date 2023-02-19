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

### Scopes
Examples of defining scoped services in a Factory 2.0 container. 

```swift
extension Container {
    var standardService: Factory<MyServiceType> {
        self { MyService() } // unique
    }
    var cachedService: Factory<MyServiceType> {
        self { MyService() }.cached
    }
    var singletonService: Factory<SimpleService> {
        self { SimpleService() }.singleton
    }
    var sharedService: Factory<MyServiceType> {
        self { MyService() }
            .decorator { print("DECORATING \($0.id)") }
            .shared
    }
}
```
A Factory's scope is unique unless defined otherwise.

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
Example of parameterized registration in a Factory 2.0 container.
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

### Static Factories
Example of static Factory 2.0 registration container.

```swift
extension Container {
    static var oldSchool: Factory<School> {
        Self.shared { School() }
    }
}

let school = Container.oldSchool
```
Note that we had to give the Factory a reference to the class "shared" container. That container will manage the registrations and scopes for any such Factory.

While you *can* create static Factory's', such usage should be considered to be deprecated. Static factories are also no longer compatible with the various ``Injected`` property wrappers due to the lack of keyPaths.

Better to simply define the Factory as a standard computed variable within a Container, and then access the "shared" version.

```swift
extension Container {
    var newSchool: Factory<School> {
        Factory(shared) { School() }
    }
}

let school = Container.shared.newSchool
```
