# Per-Scene Containers

Giving every window its own container instead of sharing one global.

## Overview

`Container.shared` is not scene aware. It never was.

On an iPhone with a single window you will never notice. On iPad with Split View or Stage Manager, or on the Mac, one process hosts several scenes at once. Every one of them resolves through the same `Container.shared`, with the same registrations and the same scope caches.

That's the problem in one sentence. Here's what it looks like in practice.

```swift
extension Container {
    var session: Factory<Session> { self { Session() }.cached }
}
```

Two windows, two accounts. Both windows ask `Container.shared` for a session, and both get the same cached instance. Sign in on the left and the right window is suddenly looking at someone else's data. Register a mock in one window and you've registered it in all of them.

## Why not just swap the shared container?

Because you can't. `Container.shared` is a `@TaskLocal`, and a task local is get-only. The only way to change what it returns is `Container.$shared.withValue(_:)`, and the new value lasts for that closure and the child tasks created inside it.

There are other issues as well, but basically we need to stop trying to replace the global and figure out a way to give each scene its own container and let the views find it.

Fortunately, Apple gave us a solution. With a catch, of course.

Let's dive in.

## One container per scene

Start by creating the container at the root of the scene and publishing it in the environment using `.withContainer`.

```swift
@main
struct DemoApp: App {
    var body: some Scene {
        WindowGroup {
            SceneRoot()
        }
    }
}

struct SceneRoot: View {
    @State private var sceneContainer = Container()
    var body: some View {
        ContentView()
            .withContainer(sceneContainer)
    }
}
```

Put it in the scene root, not the app root. `WindowGroup` instantiates `SceneRoot` once per window, so each window gets its own `@State` and its own `Container`. Put it in `App` and you've built another global with extra steps.

The container lives exactly as long as the scene. When the window goes away, `@State` releases the container, and its registrations and cached objects go with it.

The default value of the environment variable is `Container.shared`. Any view that isn't inside a scene root behaves exactly as it always did.

## Accessing the container

So now we have our container. How do we access it? Well, in some cases we can simply access the environment variable.

```swift
// Directly
struct ContentView: View {
    @Environment(\.container) var container
    ...
}
```

The environment only knows about the default container, though. ``InjectedContainer`` does the same job and also works with custom containers.

```swift
struct ContentView: View {
    // The default Container
    @InjectedContainer var container   
    // A custom container
    @InjectedContainer(MyContainer.self) var myContainer 
    ...
}
```

It's read-only. It returns the container installed for the scene, and falls back to the shared container if there isn't one.

But there's a problem here. The Environment isn't available on View initialization, and that's where we usually need to construct our view models or setup access to our repositories or other services.

```swift
struct ContentView: View {
    @Environment(\.container) var container
    @State var model: ContentViewModel
    init() {
        model = .init(container: container) // FAILS! Container not available!
    }
    var body: some View {
        Text(model.text)
    }
}
```
`InjectedContainer` has the same limitation. Read it in `init` and you'll quietly receive the shared container.

Fortunately, Factory has long had a solution to this problem. All you need to do is let Factory construct your view model for you.

## InjectedObject and InjectedObservable

``InjectedObservable`` and ``InjectedObject`` both read `\.container` and resolve their dependencies from whatever container they find there.

```swift
struct ContentView: View {
    @InjectedObservable(\.contentViewModel) var model
    var body: some View {
        Text(model.text)
    }
}
```

Use ``InjectedObject`` the same way when your view model is an `ObservableObject`.

There's one behavioral detail worth knowing. A property wrapper can't read the environment in its initializer, because the environment isn't installed yet. So these wrappers resolve on first access instead, once, and keep the result in `State` or `StateObject` for the lifetime of the view. The view model is still created exactly once per view.

## Pass the container down

Resolving the view model from the scene container is only half the job. The view model has dependencies of its own, and those need to come from the same place.

The factory already knows which container is resolving it. It's `self`. Hand it to the view model. So do this...

```swift
extension Container {
    @MainActor var contentViewModel: Factory<ContentViewModel> {
        self { ContentViewModel(container: self) }
    }
}

@MainActor @Observable
final class ContentViewModel {
    private let service: MyServiceType
    init(container: Container) {
        // Resolved from the scene container.
        self.service = container.myServiceType()
    }
}
```

And don't do this.

```swift
@MainActor @Observable
final class ContentViewModel {
    // Always resolves from Container.shared, no matter which scene created the view model.
    @Injected(\.myServiceType) private var badDependency
}
```

The same goes inside factory definitions. Use `self.network()`, not `Container.shared.network()`. The second one jumps straight back to the global container.

It may be that some dependencies can be shared across windows (analytics, for example). In that case you'd probably want them in the `.singleton` cache that's shared across containers.

## What does not follow the scene container

The environment only reaches the two aforementioned SwiftUI wrappers.

``Injected``, ``LazyInjected``, ``WeakLazyInjected``, ``DynamicInjected`` and a bare `Container.shared.myService()` always use `Container.shared`. 

**They have no way to see the environment.**

## Custom containers

The custom container form, `@InjectedObservable(\MyContainer.service)`, works the same way. It resolves from the container of that type installed for the scene, and falls back to `MyContainer.shared` when there isn't one.

Install one with `withContainer`. It's the custom container counterpart of `.environment(\.container, sceneContainer)`.

```swift
struct SceneRoot: View {
    @State private var sceneContainer = MyContainer()
    var body: some View {
        ContentView()
            .withContainer(sceneContainer)
    }
}
```

Inside the scene, views can read that container with `@InjectedContainer(MyContainer.self) var container`.

The registration forms take the container type, or a key path rooted in it.

```swift
#Preview {
    ContentView()
        .withContainer(MyContainer.self) { $0.myServiceType.register { MockService() } }
        .withContainer(MyContainer())
}

#Preview {
    ContentView()
        .withContainer(\MyContainer.myServiceType) { MockService() }
        .withContainer(MyContainer())
}
```

The same placement rule applies. Apply the registrations inside the view that installs the container, or they register on `MyContainer.shared`.


Scopes behave the way you'd expect once you remember where they live. `.cached` and `.shared` are stored on the container, so they're per scene. `.singleton` is global and independent of any container, so it's shared by every scene. If a dependency must not be shared across windows, don't make it a singleton.

## Previews and withContainer

A preview has no scene root, so `\.container` is the global container. You'll usually want to register a mock for the preview, and `withContainer` does that without leaving the view hierarchy.

It works for views that get their dependencies from ``InjectedObservable`` or ``InjectedObject``. If your view uses ``Injected`` or builds its view model in `init`, read "When withContainer is too late" below first.

Register one factory with the key path form.

```swift
#Preview {
    ContentView()
        .withContainer(\.myServiceType) { MockService() }
}
```

Or use the closure form when there's more to set up.

```swift
#Preview {
    ContentView()
        .withContainer {
            $0.myServiceType.register { MockService() }
            $0.analytics.register { MockAnalytics() }
        }
}
```

Remember what the default container is, though. In both previews above `withContainer` finds `Container.shared` and registers on it. That's fine for a quick preview, but the registration can leak into other previews running in the same process.

If you want the preview isolated, give it its own container.

```swift
#Preview {
    ContentView()
        .withContainer { $0.myServiceType.register { MockService() } }
        .environment(\.container, Container())
}
```

Now the registration lands on a container that exists only for this preview.

The order of those two modifiers is not cosmetic. `withContainer` changes the container it finds in the environment, so it has to sit inside the view that sets `\.container`. Flip them and `withContainer` runs first, finds `Container.shared`, and registers there. Your isolated container is created and never used, and nothing complains.

```swift
// Wrong. The registration goes to Container.shared.
ContentView()
    .environment(\.container, Container())
    .withContainer { $0.myServiceType.register { MockService() } }
```

The same rule applies in a real scene root. To give one scene its own registrations, apply `withContainer` inside the view that publishes the scene container.

## When withContainer is too late

`withContainer` is a view modifier, and a modifier can only wrap a view that already exists. Look at the order things happen in.

```swift
ContentView()                  // 1. init runs, and so does everything resolved in it
    .withContainer { ... }     // 2. the modifier is attached
                               // 3. later, when SwiftUI renders, the registrations run
```

Swift evaluates `ContentView()` before it ever looks at `.withContainer`. The registrations happen after the view has been built. No modifier can reach back and change that.

For some views that doesn't matter. ``InjectedObservable`` and ``InjectedObject`` resolve on first use, which is when the body is evaluated. By then the modifier has run, so the registrations are in place.

```swift
struct ContentView: View {
    @InjectedObservable(\.contentViewModel) var model   // resolved in body. Sees the mock.
    var body: some View { Text(model.text) }
}

#Preview {
    ContentView()
        .withContainer(\.myServiceType) { MockService() }
}
```

For others it matters a lot. ``Injected`` resolves in the view's `init`, from `Container.shared`. So does any view model you create there, along with every `@Injected` property inside that view model.

```swift
struct ContentView: View {
    @Injected(\.myServiceType) var service          // resolved in init
    @State private var model = ContentViewModel()   // created in init, and so are its dependencies
    ...
}

#Preview {
    ContentView()
        .withContainer(\.myServiceType) { MockService() }   // Too late. Both already have the live service.
}
```

Nothing complains. The preview just quietly talks to the real thing.

### The old-style fallbacks

Until you can move those views over to ``InjectedObservable`` or ``InjectedObject``, make sure the registration happens *before* the view is created.

The simplest way is to register in the preview itself. The `let _ =` keeps the statement legal inside the preview's view builder.

```swift
#Preview {
    let _ = Container.shared.myServiceType.register { MockService() }
    ContentView()
}
```

That's the global container again, so the same warning about leaking registrations into other previews applies. If you want isolation, build your own container and install it as well. Views that use the SwiftUI wrappers will find it in the environment.

```swift
#Preview {
    let container = Container()
    let _ = container.myServiceType.register { MockService() }
    ContentView()
        .withContainer(container)
}
```

That still leaves ``Injected``, which has no way to see the environment. For that, `Container.shared` is a `@TaskLocal`, and you can scope it while the view is being built.

```swift
#Preview {
    let container = Container()
    let _ = container.myServiceType.register { MockService() }
    Container.$shared.withValue(container) {
        ContentView()
            .withContainer(container)
    }
}
```

Inside that closure `init` runs with `container` as `Container.shared`, so `@Injected` and any view model created in `init` resolve from it. Only the construction is scoped, though. Anything that touches `Container.shared` later, like a ``LazyInjected`` property or a button action, goes back to the real global.

Finally, there's the option that works everywhere, and it's the one recommended above. Stop reaching for the global in your view models. Give them the container and resolve from it.

```swift
@MainActor @Observable
final class ContentViewModel {
    private let service: MyServiceType
    init(container: Container) {
        self.service = container.myServiceType()
    }
}
```

These are stopgaps. A way to defer building the view until the registrations have run is planned, but it isn't part of `withContainer` today.
