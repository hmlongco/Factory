# SwiftUI Previews

Mocking dependencies for SwiftUI Previews.

## Overview

Factory can make SwiftUI Previews easier when we're using View Models and those view models depend on internal dependencies. Let's take a look.

## SwiftUI Integrations

Factory can be used in SwiftUI to assign a dependency to a `StateObject` or `ObservedObject`.

```swift
class ContentView: ObservableObject {
    @StateObject private var viewModel = Container.shared.contentViewModel()
    var body: some View {
        ...
    }
}
```
Keep in mind that if you assign to an `ObservedObject` your Factory is responsible for managing the object's lifecycle (see the section on Scopes above).

## SwiftUI Previews

Here's an example of updating a view model's service dependency in order to setup a particular state for  preview.

```swift
class ContentView: ObservableObject {
    @StateObject var viewModel = ContentViewModel()
    var body: some View {
        ...
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let _ = Container.myService.register { MockServiceN(4) }
        ContentView()
    }
}
```
If we can control where the view model gets its data then we can put the view model into pretty much any state we choose.

## Multiple Previews

If we want to do multiple previews at once, each with different data, we simply need to instantiate our view models and pass them into the view as parameters.

Given the ContentView we used above...

```swift
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            let _ = Container.shared.myService.register { MockServiceN(4) }
            let vm1 = ContentViewModel()
            ContentView(viewModel: vm1)
            
            let _ = Container.shared.myService.register { MockServiceN(8) }
            let vm2 = ContentViewModel()
            ContentView(viewModel: vm2)
        }
    }
}
```

## InjectedObject

Should you prefer, you can also use ``InjectedObject``, an immediate injection property wrapper for SwiftUI ObservableObjects.

This wrapper is meant for use in SwiftUI Views and exposes bindable objects similar to that of SwiftUI @StateObject
and @EnvironmentObject.

Like the other Injected property wrappers, InjectedObject wraps obtains the dependency from the Factory keypath
and provides it to a wrapped instance of StateObject. 
```swift
struct ContentView: View {
    @InjectedObject(\.contentViewModel) var model
    var body: some View {
        ...
    }
}
```
ContentViewModel must, of course, be of type ObservableObject and is registered like any other service
or dependency.
```swift
extension Container {
    var contentViewModel: Factory<ContentViewModel> {
        self { ContentViewModel() }
    }
}
```
As with StateObject and ObservedObject, updating the object's state will trigger a view update.

InjectedObject is also handy when...

1. You have a service that could be consumed from a view or a view model.
2. You have view model dependencies that depend on the Graph scope and you need the view model to be the graph's root. See <doc:Scopes> for more details on graph.

## InjectedObject Previews

Single previews work exactly the same.
```swift
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let _ = Container.shared.myService.register { MockServiceN(4) }
        ContentView()
    }
}
```
But due a bug in how Swift manages property wrappers with built in initializers, doing multiple previews is just a little different than shown earlier.
```swift
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            let _ = Container.shared.myServiceType.register { MockServiceN(44) }
            let model1 = ContentViewModel()
            ContentView(model: InjectedObject(model1))
            
            let _ = Container.shared.myServiceType.register { MockServiceN(88) }
            let model2 = ContentViewModel()
            ContentView(model: InjectedObject(model2))
        }
    }
}
```
Instead of passing the model to the view directly, we need to create the entire `InjectedObject(model1)` pair and pass that.

## Common Setup

If we have several mocks that we use all of the time in our previews or unit tests, we can also add a setup function to a given container to make this easier.

```swift
extension Container {
    func setupMocks() {
        myService.register { MockServiceN(4) }
        sharedService.register { MockService2() }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let _ = Container.shared.setupMocks()
        ContentView()
    }
}
```
