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

Unlike Resolver, Factory doesn't have an @InjectedObject property wrapper. There are [a few reasons for this](https://github.com/hmlongco/Factory/issues/15), but for now doing your own assignment to `StateObject` or `ObservedObject` is the preferred approach. 

That said, at this point in time I feel that we should probably avoid using Factory to create the view model in the first place.  It's usually unnecessary, [you really can't use protocols with view models anyway](https://betterprogramming.pub/swiftui-view-models-are-not-protocols-8c415c0325b1), and for the most part Factory's really designed to provide the VM and other services with the dependencies that *they* need. 

Especially since those services have no access to the environment.

## SwiftUI Previews

With that in mind, here's an example of updating a view model's service dependency in order to setup a particular state for  preview.

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
