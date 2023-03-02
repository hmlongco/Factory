# Sample Resolutions

There are many ways to use Factory to resolve dependencies. Here are a few examples.

### Shared Class Container
Here we instantiate our dependency from a shared class container. 
```swift
class ContentViewModel: ObservableObject {
    let service = Container.shared.constructedService()
}
```
This is the classic Service Locator pattern updated for Factory 2.0.

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
    private lazy var service6: MyServiceType = container.sharedService()

    init(container: Container) {
        self.container = container
    }

}
```

### Injected Proprty Wrappers
Using the `@Injected` and `@LazyInjecter` property wrappers to obtain dependencies using an Annotation pattern similar to that used by `EnvironmentObject` in SwiftUI.
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
See ``Injected``, ``LazyInjected``, ``WeakLazyInjected``, and ``InjectedObject`` for more.

### Parameterized Initialization from Passed Container
Passing a required parameter to a factory for resolution.
```swift
class ContentViewModel: ObservableObject {

    let parameterService: ParameterService

    init(container: Container, value: Int) {
        service2 = container.parameterService(value)
    }

}
```
See ``ParameterFactory`` for more details.

### Classic Factory from Static Class Member
Initializing dependency from class. This is classic Service Locator pattern but this pattern should be consider deprecated.
```swift
class ContentViewModel: ObservableObject {
    let newSchool = Container.newSchool()
}
```
This was discussed in greater detail in <doc:Registrations>

### Composition Root

If you want to use a Composition Root pattern, just use the container to provide the required dependencies to a constructor.

```swift
extension Container {
    var constructedService: Factory<MyConstructedService> {
        self { MyConstructedService(service: self.cachedService()) }.singleton
    }
    var cachedService: Factory<MyServiceType> {
        self { MyService() }.cached
    }
}

@main
struct FactoryDemoApp: App {
    let viewModel = MyViewModel(service: Container.shared.constructedService())
    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView(viewModel: viewModel)
            }
        }
    }
}ß
```
