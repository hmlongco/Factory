# Sample Registrations

```swift
// Example of basic registration in a Factory 2.0 container
extension Container {
    var service: Factory<MyServiceType> {
        Factory(self) { MyService() }
    }
}

// Example of basic factory registration using convenience function
extension Container {
    var convenientService: Factory<MyServiceType> {
        factory { MyService() }
    }
}

// Examples of scoped services in a Factory 2.0 container
extension Container {
    var standardService: Factory<MyServiceType> {
        factory { MyService() } // unique
    }
    var cachedService: Factory<MyServiceType> {
        factory { MyService() }.cached
    }
    var singletonService: Factory<SimpleService> {
        factory { SimpleService() }.singleton
    }
    var sharedService: Factory<MyServiceType> {
        factory { MyService() }
            .decorator { print("DECORATING \($0.id)") }
            .shared
    }
}

// Example of service with constructor injection that requires another services
extension Container {
    var constructedService: Factory<MyConstructedService> {
        factory {
            MyConstructedService(service: self.cachedService())
        }
    }
}

// Example of parameterized functional registration in a Factory 2.0 container
extension Container {
    func parameterized(_ n: Int) -> Factory<ParameterService> {
        factory { ParameterService(count: n) }
    }
}

// Example of correctly handling multiple instances of the same type
extension Container {
    var string1: Factory<String> {
        factory { "String 1" }
    }
    var string2: Factory<String> {
        factory { "String 2" }
    }
    var string3: Factory<String> {
        factory { "String 3" }
    }
    var string4: Factory<String> {
        factory { "String 4" }
    }
}
```

