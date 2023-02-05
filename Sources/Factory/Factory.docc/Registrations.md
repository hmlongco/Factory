# Sample Registrations

## Examples

There are many ways to register dependencies with Factory. Here are a few examples.

### Basic
Example of a full, formal dependency registration in a Factory 2.0 container.

```swift
extension Container {
    var service: Factory<MyServiceType> {
        Factory(self) { MyService() }
    }
}
```

### Convenience
Example of a basic factory registration using `makes` convenience function.

```swift
extension Container {
    var convenientService: Factory<MyServiceType> {
        makes { MyService() }
    }
}
```

### Scopes
Examples of scoped services in a Factory 2.0 container.

```swift
extension Container {
    var standardService: Factory<MyServiceType> {
        makes { MyService() } // unique
    }
    var cachedService: Factory<MyServiceType> {
        makes { MyService() }.cached
    }
    var singletonService: Factory<SimpleService> {
        makes { SimpleService() }.singleton
    }
    var sharedService: Factory<MyServiceType> {
        makes { MyService() }
            .decorator { print("DECORATING \($0.id)") }
            .shared
    }
}
```

### Constructor Injection
Example of service with constructor injection that requires another service as a parameter. To obtain that dependency we simply ask the Factory dedicated to that service to provide one for us.

```swift
extension Container {
    var constructedService: Factory<MyConstructedService> {
        makes {
            MyConstructedService(service: self.cachedService())
        }
    }
}
```

### Parameters
Example of parameterized functional registration in a Factory 2.0 container.

```swift
extension Container {
    func parameterized(_ n: Int) -> Factory<ParameterService> {
        makes { ParameterService(count: n) }
    }
}
```

### Same Types
Example of correctly handling multiple instances of the same type.

```swift
extension Container {
    var string1: Factory<String> {
        makes { "String 1" }
    }
    var string2: Factory<String> {
        makes { "String 2" }
    }
    var string3: Factory<String> {
        makes { "String 3" }
    }
    var string4: Factory<String> {
        makes { "String 4" }
    }
}
```

