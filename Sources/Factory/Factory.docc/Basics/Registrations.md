# Sample Registrations

There are many ways to register dependencies with Factory. Here are a few examples.

### Basic
Example of a basic dependency registration in a Factory 2.0 container.

```swift
extension Container {
    var service: Factory<MyServiceType> {
        unique { MyService() }
    }
}
```

### Scopes
Examples of defining scoped services in a Factory 2.0 container. 

```swift
extension Container {
    var standardService: Factory<MyServiceType> {
        unique { MyService() }
    }
    var cachedService: Factory<MyServiceType> {
        cached { MyService() }
    }
    var singletonService: Factory<SimpleService> {
        singleton { SimpleService() }
    }
    var sharedService: Factory<MyServiceType> {
        shared { MyService() }
            .decorator { print("DECORATING \($0.id)") }
    }
    var customScopedService: Factory<SimpleService> {
        scope(.session) { SimpleService() }
    }
}
```

### Constructor Injection
Example of service with constructor injection that requires another service as a parameter. To obtain that dependency we simply ask the Factory dedicated to that service to provide one for us.

```swift
extension Container {
    var constructedService: Factory<MyConstructedService> {
        unique { MyConstructedService(service: self.cachedService()) }
    }
    var cachedService: Factory<MyServiceType> {
        cached { MyService() }
    }
}
```

### Parameters
Example of parameterized registration in a Factory 2.0 container.
```swift
extension Container {
    var parameterService: ParameterFactory<Int, ParameterService> {
        unique { ParameterService(value: $0) }
    }
}
```
Note that we also needed to specify the type of our parameter.

### Same Types
Example of correctly handling multiple instances of the same type.

```swift
extension Container {
    var string1: Factory<String> {
        unique { "String 1" }
    }
    var string2: Factory<String> {
        unique { "String 2" }
    }
    var string3: Factory<String> {
        unique { "String 3" }
    }
    var string4: Factory<String> {
        unique { "String 4" }
    }
}
```
