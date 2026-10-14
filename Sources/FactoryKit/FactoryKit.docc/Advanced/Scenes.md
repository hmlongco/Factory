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

SwiftUI doesn't build your views inside a closure you wrote. It creates and updates them on its own schedule, and by then your `withValue` has long since returned. Anything resolved lazily later quietly falls back to the global container, and nothing tells you.

So we need to stop trying to replace the global and figure out a way to give each scene its own container and let the views find it.

## One container per scene

Start by creating the container at the root of the scene and publish it in the environment under `\.container`.

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
            .environment(\.container, sceneContainer)
    }
}
```

Put it in the scene root, not the app root. `WindowGroup` instantiates `SceneRoot` once per window, so each window gets its own `@State` and its own `Container`. Put it in `App` and you've built another global with extra steps.

The container lives exactly as long as the scene. When the window goes away, `@State` releases the container, and its registrations and cached objects go with it.

The default value of `\.container` is `Container.shared`. Any view that isn't inside a scene root behaves exactly as it always did.

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

The environment only reaches the two aforementioned SwiftUI wrappers, and only when you use the default container's key path.

``Injected``, ``LazyInjected``, ``WeakLazyInjected``, ``DynamicInjected`` and a bare `Container.shared.myService()` always use `Container.shared`. 

**They have no way to see the environment.**

The custom container form, `@InjectedObservable(\MyContainer.service)`, resolves from `MyContainer.shared` as well. If you need per-scene behavior, use the default `Container` or explicitly pass your own container in the environment.

Scopes behave the way you'd expect once you remember where they live. `.cached` and `.shared` are stored on the container, so they're per scene. `.singleton` is global and independent of any container, so it's shared by every scene. If a dependency must not be shared across windows, don't make it a singleton.

## Previews and withContainer

A preview has no scene root, so `\.container` is the global container. You'll usually want to register a mock for the preview, and `withContainer` does that without leaving the view hierarchy.

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
