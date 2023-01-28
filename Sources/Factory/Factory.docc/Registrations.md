# Sample Registrations

### Basic
Example of basic registration in a Factory 2.0 container

```swift
extension Container {
    var service: Factory<MyServiceType> {
        Factory(self) { MyService() }
    }
}
```

### Convenience
Example of basic factory registration using convenience function

```swift
extension Container {
    var convenientService: Factory<MyServiceType> {
        make { MyService() }
    }
}
```

### Scopes
Examples of scoped services in a Factory 2.0 container

```swift
extension Container {
    var standardService: Factory<MyServiceType> {
        make { MyService() } // unique
    }
    var cachedService: Factory<MyServiceType> {
        make { MyService() }.cached
    }
    var singletonService: Factory<SimpleService> {
        make { SimpleService() }.singleton
    }
    var sharedService: Factory<MyServiceType> {
        make { MyService() }
            .decorator { print("DECORATING \($0.id)") }
            .shared
    }
}
```

### Constructor Injection
Example of service with constructor injection that requires another services

```swift
extension Container {
    var constructedService: Factory<MyConstructedService> {
        make {
            MyConstructedService(service: self.cachedService())
        }
    }
}
```

### Parameters
Example of parameterized functional registration in a Factory 2.0 container

```swift
extension Container {
    func parameterized(_ n: Int) -> Factory<ParameterService> {
        make { ParameterService(count: n) }
    }
}
```

### Same Types
Example of correctly handling multiple instances of the same type

```swift
extension Container {
    var string1: Factory<String> {
        make { "String 1" }
    }
    var string2: Factory<String> {
        make { "String 2" }
    }
    var string3: Factory<String> {
        make { "String 3" }
    }
    var string4: Factory<String> {
        make { "String 4" }
    }
}
```

