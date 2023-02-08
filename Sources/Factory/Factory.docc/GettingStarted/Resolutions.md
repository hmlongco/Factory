# Sample Resolutions

There are many ways to use Factory to resolve dependencies. Here are a few examples.

### Classic Factory from Static Class Member
Initializing dependency from class. This is classic Service Locator pattern.
```swift
class ContentViewModel: ObservableObject {
    let newSchool = Container.newSchool()
}
```

### Modern Factory from Shared Class Container
Initializing dependency from shared class container. This is the classic Service Locator pattern updated for Factory 2.0.
```swift
class ContentViewModel: ObservableObject {
    let service = Container.shared.constructedService()
}
```

### Initialization from Passed Container
Passing an instance of a container to our view model and initializing service from that container.
```swift
class ContentViewModel: ObservableObject {

    let service2: MyServiceType

    init(container: Container) {
        service2 = container.service()
    }
    
}
```

### Lazy Initialization from Passed Container
Passing an instance of a container to our view model and saving it for later lazy initializers.
```swift
class ContentViewModel: ObservableObject {

    private let container: Container

    private lazy var service3: MyConstructedService = container.constructedService()
    private lazy var service4: MyServiceType = container.cachedService()
    private lazy var service5: SimpleService = container.singletonService()
    private lazy var service6A: MyServiceType = container.sharedService()
    private lazy var service6B: MyServiceType = container.sharedService()

    init(container: Container) {
        self.container = container
    }

}
```

### Injected Proprty Wrappers
Using the @Injected and @LazyInjecter property wrappers to obtain dependencies using an Annotation pattern similar to that used by EnvironmentObject in SwiftUI.
```swift
class ContentViewModel: ObservableObject {

    // Injected property from default container
    @Injected(\.constructedService) var constructed

    // Injected property from custom container
    @Injected(\MyContainer.anotherService) var anotherService

    // LazyInjected property from custom container
    @LazyInjected(\MyContainer.myLazyService) var myLazyService

}
```
