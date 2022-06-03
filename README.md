![](https://github.com/hmlongco/Factory/blob/main/Logo.png?raw=true)

A new approach to Container-Based Dependency Injection for Swift and SwiftUI.

## Why do something new?

[Resolver](https://github.com/hmlongco/Resolver) was my first Dependency Injection system. While quite powerful and still in use in many of my applications, it suffers from a few drawbacks.

1. Resolver requires pre-registration of all service factories up front. 
2. Resolver uses type inference to dynamically find and return registered services in a container.

While the first issue could lead to a performance hit on application launch, in practice the registration process is usually quick and not normally noticable. No, it's the second item that's somewhat more problematic. 

 Failure to find a matching type *could* lead to an application crash if we attempt to resolve a given type and if a matching registration is not found. In real life that isn't really a problem as such a thing tends to be noticed and fixed rather quickly the very first time you run a unit test or when you run the application to see if your newest feature works.
 
 But... could we do better? That question lead me on a quest for compile-time type safety. Several other systems have attempted to solve this, but I didn't want to have to add a source code scanning and generation step to my build process, nor did I want to give up a lot of the control and flexibility inherent in a run-time-based system.
 
 Could I have my cake and eat it too?
 
 ## Features
 
 Factory is strongly influenced by SwiftUI, and in my opinion is highly suited for use in that environment. Factory is...
 
 * **Safe:** Factory is compile-time safe; a factory for a given type *must* exist or the code simply will not compile.
 * **Flexible:** It's easy to override dependencies at runtime and for use in SwiftUI Previews. And, like Resolver, Factory supports application, cached, shared, and custom scopes, customer containers, arguments, decorators, and more.
 * **Lightweight:** With all of that Factory is slim and trim, coming in at about 200 lines of code.
 * **Performant:** Little to no setup time is needed for the vast majority of your services, resolutions are extremely fast, and no compile-time scripts or build phases are needed.
 * **Concise:** Defining a registration usually takes just a single line of code.
 
 Sound too good to be true? Let's take a look.
 
 ## A simple example
 
 Most container-based dependency injection systems require you to define in some way that a given service type is available for injection and many reqire some sort of factory or mechanism that will provide a new instance of the service when needed.
 
 Factory is no exception. Here's a simple dependency registraion.
 
```swift
extension Container {
    static let myService = Factory<MyServiceType> { MyService() }
}
```
Unlike Resolver which often requires defining a plethora of registration functions, or SwiftUI, where defining a new environment variable requires creating a new EnvironmentKey and adding additional getters and setters, here we simply add a new `Factory` to the default container. When called, the factory closure is evaluated and returns an instance of our dependency. That's it.

Injecting and using the service where needed is equally straightforward. Here's one way to do it.

```swift
class ContentViewModel: ObservableObject {
    @Injected(Container.myService) private var myService
    ...
}
```
Here our view model uses an `@Injected` property wrapper to request the desired dependency. Similar to `@EnvironmentObject` in SwiftUI, we provide the property wrapper with a reference to a factory of the desired type and it handles the rest.

And that's the core mechanism. In order to use the property wrapper you *must* define a factory. That factory that *must* return the desired type. Fail to do either one and the code will simply not compile. As such, Factory is compile-time safe.

## Factory

A `Factory` is a lightweight struct that manages a given dependency. And due to the lazy nature of static variables, a factory isn't instantiated until it's referenced for the first time.

When a factory is evaluated it provides an instance of the desired dependency. As such, it's also possible to bypass the property wrapper and call the factory directly.

```swift
class ContentViewModel: ObservableObject {
    private let myService = Container.myService()
    ...
}
```

## Mocking and Testing

Examining the above code, one might wonder why we've gone to all of this trouble? Why not simply say `let myService = MyService()` and be done with it?

Well, the primary benefit one gains from using a container-based dependency injection system is that we're able to change the behavior of the system as needed. Consider the following code:

```swift
struct ContentView: View {
    @StateObject var model = ContentViewModel1()
    var body: some View {
        Text(model.text())
            .padding()
    }
}
```

Our ContentView uses our view model, which is assigned to a StateObject. Great. But now we want to preview our code. How do we change the behavior of `ContentViewModel` so that we're not making live API calls during development? It's easy.

```swift
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let _ = Container.myServiceType.register { MockService2() }
        ContentView()
    }
}
```

Note the line in our preview code where we're gone back to our container and registered a new factory closure. One that provides a mock service that also conforms to `MyServiceType`.

Now when our preview is displayed `ContentView` creates a `ContentViewModel` which in turn depends on `myService` using the Injected property wrapper. But when the factory is asked for an instance of `MyServiceType` it now returns a `MockService2` instance instead of the `MyService` instance originally defined.

This is a powerful concept that let's us reach deep into a chain of dependencies and alter the behavior of a system as needed.

But Factory has a few more tricks up it's sleeve.

## Scope

