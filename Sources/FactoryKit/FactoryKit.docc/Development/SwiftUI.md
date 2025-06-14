# SwiftUI

Defining and using dependencies in SwiftUI.

## Overview

Factory can make SwiftUI easier to use when we're using view models or services and those entities depend on internal dependencies. Let's take a look.

## StateObjects

Factory can be used to assign a fully constructed dependency to a `StateObject` or `ObservedObject`.

```swift
// the view model
class ContentViewModel: ObservableObject {
    @Injected(\.myService) private var service
    @Published var results: Results
    func load() async {
        results = await service.load()
    }
}

// the factory
extension Container {
    var contentViewModel: Factory<ContentViewModel> {
        self { ContentViewModel() }
    }
}

// the view
struct ContentView: View {
    @StateObject var viewModel = Container.shared.contentViewModel()
    var body: some View {
        ...
    }
}
```
Keep in mind that if you assign to an `ObservedObject` your Factory is responsible for managing the object's lifecycle (see the section on Scopes).

## InjectedObject

Then again, if your view model is coming from Factory, we can bypass the shared container code and just use the `InjectedObject` property wrapper.

```swift
// the view
struct ContentView: View {
    @InjectedObject(\.contentViewModel) private var viewModel
    var body: some View {
        ...
    }
}
```
InjectedObject uses `StateObject` under the hood, so ownership is implied.

## ViewModel Dependencies

Note that our view model used the ``Injected`` property wrapper to obtain its dependency.

```swift
class ContentViewModel: ObservableObject {
    @Injected(\.myService) private var service
    ...
}
```
As such, there's no particular reason to obtain the view model from Factory since the view model knows what it needs and it's perfectly capable of managing things for itself.
```swift
struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    var body: some View {
        ...
    }
}
```

That would be different if, for example, our view model wanted its dependencies passed via an initializer.
```swift
class ContentViewModel: ObservableObject {
    private let service: MyServiceType
    init(service: MyServiceType)
        self.service = service
    }
    ...
}
```
In which case we might indeed want our container to provide a fully initialized object.
```swift
extension Container {
    var contentViewModel: Factory<ContentViewModel> {
        self { ContentViewModel(service: myService()) }
    }
    var myService: Factory<MyServiceType> {
        self { MyService() }
    }
}
```
And back to `InjectedObject` we go.

## Observation

Apple added support for a new framework to iOS 17--Observation. Observation promises better efficiency and fewer view updates when used across multiple views. So how do we use it?

Here's our previous example, updated for Observation.

```swift
@Observable
class ContentViewModel {
    @ObservationIgnored @Injected(\.myService) private var service
    var results: Results
    func load() async {
        results = await service.load()
    }
}
```
We replaced the `ObservableObject` protocol conformance with the `@Observable` macro and removed the `@Published` attribute from results.

Note, however, that we needed to add `@ObservationIgnored` to our `Injected` service property wrapper. It's a private value and doesn't need to be visible outside of our view model.

Here's the view.

```swift
struct ContentView: View {
    @InjectedObservable(\.contentViewModel) var viewModel
    var body: some View {
        ...
    }
}
```
Instead of `InjectedObject` we use `InjectedObservable`, a new property wrapper that understands how to work with the Observable protocol established by Observation.

InjectedObservable uses `State` under the hood and, like `InjectedObject`, owns the instance in question.

*One should also note that InjectedObject "thunks" its parameter and only one instance of the injected view model will be created for the lifetime of the view.*

## Coping With @MainActor

One last thing missing from our SwiftUI sample code is @MainActor, that Swift Concurrency attribute used to ensure all view updates occur on the main thread.

Let's update our view model and see what else needs to change.

```swift
// the view model
@MainActor
@Observable
class ContentViewModel {
    @ObservationIgnored @Injected(\.myService) private var service
    var results: Results
    func load() async {
        results = await service.load()
    }
}

// the factory
extension Container {
    @MainActor
    var contentViewModel: Factory<ContentViewModel> {
        self { ContentViewModel() }
    }
}

// the view
struct ContentView: View {
    @InjectedObservable(\.contentViewModel) var viewModel
    var body: some View {
        ...
    }
}
```
As you can see adding `@MainActor` to our view model also required us to annotate the Factory accordingly, adding it to both the definition *and* to the factory closure.

While we'd never do it in this case, adding actor isolation to the base factory also means that we'd need to do so again should we ever want to register a new factory.

```swift
Container.shared.contentViewModel.register { 
    ContentViewModel()
}

```
