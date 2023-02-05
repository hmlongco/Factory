# Sample Resolutions

## Examples

There are many ways to use Factory to resolve dependencies. Here are a few examples.

```swift
class ContentViewModel: ObservableObject {

    // New static Service Locator
    let newSchool = Container.newSchool()
    
    // New shared Service Locator
    let service = Container.shared.constructedService()
    
    // Constructor initialized from container
    let service2: MyServiceType
    
    // Lazy initialized from passed container
    private let container: Container
    private lazy var service3: MyConstructedService = container.constructedService()
    private lazy var service4: MyServiceType = container.cachedService()
    private lazy var service5: SimpleService = container.singletonService()
    private lazy var service6A: MyServiceType = container.sharedService()
    private lazy var service6B: MyServiceType = container.sharedService()
    
    // Injected property from default container
    @Injected(\.constructedService) var constructed
    
    // Injected property from custom container
    @Injected(\MyContainer.anotherService) var anotherService

    // LazyInjected property from custom container
    @LazyInjected(\MyContainer.myLazyService) var myLazyService
    
    // Constructor
    init(container: Container) {
        // construct from container
        service2 = container.service()
        
        // save container reference for lazy resolution
        self.container = container
    }

}
```
