![](https://github.com/hmlongco/Factory/blob/main/Logo.png?raw=true)

A new approach to Container-Based Dependency Injection for Swift and SwiftUI.

## Why Something New?

The first dependency injection system I wrote was [Resolver](https://github.com/hmlongco/Resolver). That open source project, while quite powerful and still in use in many applications, suffered from a few drawbacks.

1. Resolver required pre-registration of all services up front. 
2. Resolver uses type inference to dynamically find and return registered services from a container.

The first drawback is relatively minor. While preregistration could lead to a performance hit on application launch, in practice the process is usually quick and not normally noticeable.

The second issue, however, is more problematic since failure to find a matching registration for that type can lead to an application crash. In real life that isn’t usually a problem as such a thing tends to be noticed and fixed the first time you run a unit test or the second you run the application to see if your newest feature works.
 
 But still... could we do better? That question lead me on a quest for compile-time type safety. Several other systems have attempted to solve this, but I didn't want to have to add a source code scanning and generation step to my build process, nor did I want to give up a lot of the control and flexibility inherent in a run-time-based system.
 
 I also wanted something simple, fast, clean, and easy to use.
 
 Could I have my cake and eat it too?
 
 ## Features
 
 Factory is strongly influenced by SwiftUI, and in my opinion is highly suited for use in that environment. Factory is...
 
 * **Safe:** Factory is compile-time safe; a factory for a given type *must* exist or the code simply will not compile.
 * **Flexible:** It's easy to override dependencies at runtime and for use in SwiftUI Previews.
 * **Powerful:** Like Resolver, Factory supports application, cached, shared, and custom scopes, custom containers, arguments, decorators, and more.
 * **Lightweight:** With all of that Factory is slim and trim, just 500 lines of code and half the size of Resolver.
 * **Performant:** Little to no setup time is needed for the vast majority of your services, resolutions are extremely fast, and no compile-time scripts or build phases are needed.
 * **Concise:** Defining a registration usually takes just a single line of code. Same for resolution.
 * **Tested:** Unit tests with 100% code coverage helps ensure correct operation of registrations, resolutions, and scopes.
 * **Free:** Factory is free and open source under the MIT License.
 
 Sound too good to be true? Let's take a look.
  
 ## A Simple Example
 
Most container-based dependency injection systems require you to define in some way that a given service type is available for injection and many require some sort of factory or mechanism that will provide a new instance of the service when needed.
 
 Factory is no exception. Here's a simple dependency registration.
 
```swift
extension Container {
    static let myService = Factory { MyService() as MyServiceType }
}
```
Unlike Resolver which often requires defining a plethora of nested registration functions, or SwiftUI, where defining a new environment variable requires creating a new EnvironmentKey and adding additional getters and setters, here we simply add a new `Factory` to the default container. When called, the factory closure is evaluated and returns an instance of our dependency. That's it.

Injecting and using the service where needed is equally straightforward. Here's one way to do it.

```swift
class ContentViewModel: ObservableObject {
    @Injected(Container.myService) private var myService
    ...
}
```
Here our view model uses one of Factory's `@Injected` property wrappers to request the desired dependency. Similar to `@Environment` in SwiftUI, we provide the property wrapper with a reference to a factory of the desired type and it resolves that type the moment `ContentViewModel` is created.

And that's the core mechanism. In order to use the property wrapper you *must* define a factory. That factory *must* return the desired type when asked. Fail to do either one and the code will simply not compile. As such, Factory is compile-time safe.

 ## Factory

Similar to a `View` in SwiftUI, a `Factory` is a lightweight struct that exists to define and manage a specific dependency. Just provide it with a closure that constructs and returns an instance of your dependency or service, and Factory will handle the rest.

```swift
static let myService = Factory { MyService() as MyServiceType }
```

The type of a factory is inferred from the return type of the closure. Here's we're casting `MyService` to the protocol it implements, so any dependency returned by this factory will always conform to `MyServiceType`. 

We can also get the same result by explicitly specializing the generic Factory as shown below. Both the specialization and the cast are equivalent and provide the same result.

```swift
static let myService = Factory<MyServiceType> { MyService() }
```

Do neither one and the factory type will always be the returned type. Here it's `MyService`.

```swift
static let myService = Factory { MyService() }
```

Due to the lazy nature of static variables, no factory is instantiated until it's referenced for the first time. Contrast this with Resolver, which forced us to run code to register *everything* prior to resolving anything.

Finally, note that it's possible to bypass the property wrapper and talk to the factory yourself in a *Service Locator* pattern.

```swift
class ContentViewModel: ObservableObject {
    // dependencies
    private let myService = Container.myService()
    private let eventLogger = Container.eventLogger()
    ...
}
```
Just call the desired specific factory as a function and you'll get an instance of its managed dependency. It's that simple.

*You can access the factory directly or the property wrapper if you prefer, but either way for clarity I'd suggest grouping all of a given object's dependencies in a single place near the top of the class and marking them as private.*

But we're not done yet. 

## Constructor Injection

At times we might prefer (or need) to use a technique known as *constructor injection* where dependencies are provided to an object upon initialization. 

That's easy to do in Factory. Here we have a service that needs an instance of `MyServiceType`.

```swift
extension Container {
    static let constructedService = Factory { ConstructedService(service: myService()) }
}
```
All of the factories in a container are visible to the other factories in that container. Just call the needed factory as a function and the dependency will be provided.


## Lazy and Weak Injections
Factory also has `LazyInjected` and `WeakLazyInjected` property wrappers. Use `LazyInjected` when you want to defer construction of some class until it's actually needed. Here the child `service` won't be instantiated until the `test` function is called.
```swift
class ServicesP {
    @LazyInjected(Container.servicesC) var service
    let name = "Parent"
    init() {}
    func test() -> String? {
        service.name
    }
}
```
And `WeakLazyInjected` is useful when building parent/child relationships and you want to avoid retain cycles back to the parent class. It's also lazy since otherwise you'd have a cyclic dependency between the parent and the child. (P needs C which needs P which needs C which...)'
```swift
class ServicesC {
    @WeakLazyInjected(Container.servicesP) var service: ServicesP?
    init() {}
    let name = "Child"
    func test() -> String? {
        service?.name
    }
}
```
And the factories. Note the shared scopes so references can be kept and maintained for the parent/child relationships.
```swift
extension Container {
    static var servicesP = Factory(scope: .shared) { ServicesP() }
    static var servicesC = Factory(scope: .shared) { ServicesC() }
}
```
Note that if you use `WeakLazyInjected` then that class must have been instantiated previously and a strong reference to the class must be maintained elsewhere. If not then the class will be released as soon as it's created. Think of it like...
```swift
weak var gone: MyClass? = MyClass()
```
`WeakLazyInjected` can also come in handy when you need to break circular dependencies. See below.

Property wrapper resolution may also be triggered manually if needed.
```swift
$service.resolve() // resolves instance from factory (may be cached by scope)
$service.resolve(reset: .scope) // clears cache, then resolves instance from factory
```

