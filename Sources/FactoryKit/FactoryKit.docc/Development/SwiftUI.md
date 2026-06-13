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

### Resolving Actor-Isolated Factory's

Here's the catch that the compiler won't warn you about. When you annotate the Factory property with `@MainActor`, the registration closure inherits that isolation. But Factory's resolution path is synchronous and `nonisolated`. The Factory is returned on the actor, but `callAsFunction()` runs the closure on whatever executor the *caller* happens to be on, and if that isn't the main actor Swift's dynamic isolation check on the closure traps.

```swift
Task.detached {
    // The property getter is @MainActor, so this access needs await.
    let factory = await Container.shared.contentViewModel
    // callAsFunction() is nonisolated, so no await here. It runs the
    // @MainActor closure on this background executor and crashes:
    // EXC_BREAKPOINT, dispatch_assert_queue_fail, _swift_task_checkIsolatedSwift.
    let viewModel = factory()
}
```

Notice that adding `await` to the property access does *not* save you. The `await` belongs to the property getter, not to `callAsFunction()`. The getter builds the lightweight `Factory` struct on the main actor and hands it back; the actual resolution still happens wherever the caller is running. Synchronous resolution has no suspension point at which Swift can hop actors, so there's nowhere for it to cross back to the main actor.

This isn't unique to `@MainActor`. *Any* actor-isolated factory, including one bound to a custom global actor, will trap the same way when it's resolved from a mismatched executor.

The fix is simpl and lives on the calling side: resolve the factory from the isolation its closure requires. For a `@MainActor` factory, hop onto the main actor first and resolve there.

```swift
Task.detached {
    let viewModel = await MainActor.run {
        Container.shared.contentViewModel()
    }
}
```

`MainActor.run` runs both the property access *and* `callAsFunction()` on the main actor, so the closure's isolation check passes. The resolved instance then crosses back to the caller as a normal `Sendable` value.

In practice you rarely hit this, because most resolution of a `@MainActor` dependency already happens from main-actor-isolated code. The `@Injected` property wrapper inside a `@MainActor` view model, for example, resolves on the main actor by construction. The crash shows up when you reach for a `@MainActor` factory from a background `Task`, a `Task.detached`, or a `nonisolated` function.
