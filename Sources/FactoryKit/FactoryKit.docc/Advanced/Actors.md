# Actors and Actor Isolation

Registering and resolving actors and actor-isolated dependencies.

## Overview

Factory resolution is synchronous. You ask for a dependency and you get one back, right now, with no `await` in sight. That model is simple and fast, but it bumps up against Swift Concurrency the moment a dependency needs to be built on a specific actor.

This page walks through the cases in order, from the one that just works to the one that needs a little help. The simplest case is a plain actor. Then a main actor-isolated type. Then a custom global actor. 

And finally what to do when you need to resolve one of those isolated types from a detached task that's non-isolated and not on any actor.

## Plain Actors

An ordinary actor is the easy case. Define it and register it like anything else.

```swift
actor OrdinaryActor {
    private var count = 0
    func increment() -> Int {
        count += 1
        return count
    }
}

extension Container {
    var ordinaryActor: Factory<OrdinaryActor> {
        self { OrdinaryActor() }
    }
}
```

Resolution needs nothing special, because an actor's initializer is *nonisolated*. It runs synchronously on whatever thread asks for it, so Factory can build one from any context.

```swift
let actor = Container.shared.ordinaryActor()
```

The isolation only matters once you touch the actor's state, and the compiler already handles that for you by requiring `await` on the call.

```swift
let count = await actor.increment()
```

So for a plain old everyday actor there's no annotation, no special resolution function, and nothing to remember. Register it, resolve it, await its methods.

Done.

## Main Actor Isolation

Now consider a type that is isolated to the main actor. View models are the common example.

```swift
@MainActor
class ContentViewModel {
    init() {
        // initializer is @MainActor-isolated
    }
    func load() async { ... }
}
```

Because the initializer is `@MainActor`-isolated, the factory closure that calls it has to be `@MainActor`-isolated too. You get there by annotating the computed property.

```swift
extension Container {
    @MainActor
    var contentViewModel: Factory<ContentViewModel> {
        self { ContentViewModel() }
    }
}
```

The annotation is the whole trick. It requires the Factory request to be on the main actor so the initializer runs on the MainActor as well.

Most of the time you never think about this because you resolve a main actor type from main actor code. A `@MainActor` view model resolved by `@Injected` inside another `@MainActor` type, or referenced from a SwiftUI view, is already on the main actor when the Factory is requested and resolution occurs.

```swift
@MainActor
class CoordinatorViewModel {
    @Injected(\.contentViewModel) var content
}
```

See <doc:SwiftUI> for more on main actor types and the SwiftUI property wrappers.

> Warning: If you attempt to resolve a `@MainActor`-isolated Factory when you're NOT on the MainActor, problems can occur. See the Detached Tasks section below.

## Global Actors

A custom global actor works exactly like the main actor, because the main actor *is* a global actor. Declare the actor, mark it `@globalActor`, and give it a `shared` instance.

```swift
@globalActor
actor BackgroundActor {
    static let shared = BackgroundActor()
}
```

Then isolate your dependency to it and annotate the factory the same way.

```swift
@BackgroundActor
final class DataManager {
    init() {
        // initializer is @BackgroundActor-isolated
    }
    func fetch() -> Data { ... }
}

extension Container {
    @BackgroundActor
    var dataManager: Factory<DataManager> {
        self { DataManager() }
    }
}
```

One thing worth calling out. A `@globalActor`-isolated *class* has its initializer isolated to that global actor, which is what makes this pattern work. A plain `actor` is different, since its own initializer is nonisolated. 

That difference is exactly why the plain actor case above needed no annotation and this one does. 

So reach for a global actor when you want a type isolated to a single shared executor, and reach for a plain actor when you want an isolated instance you talk to with `await`.

## Detached Tasks and Task Hopping

Here's where the synchronous resolution model gets tricky.

When you annotate a factory with `@MainActor` or a global actor, the registration closure inherits that isolation. But `callAsFunction()` method on that Factory is nonisolated and synchronous, so it runs the closure on whatever executor the *caller* happens to be on. 

Resolve it from the matching actor and everything is fine. Resolve from somewhere else and the closure's isolation check traps before your initializer even runs.

```swift
Task.detached {
    // Remember that this...
    let firstVM =  await Container.shared.contentViewModel()
    
    // Is actually this. The property returning the Factory is @MainActor, so the first access requires the await. 
    let factory = await Container.shared.contentViewModel
    
    // But the callAsFunction() is nonisolated, so Swift doesn't require an await there.... 
    let viewModel = factory() // BOOM
}
```

Adding `await` to the property access does not save you. That `await` belongs to the property getter, not to `callAsFunction()`. The getter builds the lightweight `Factory` struct on the main actor and hands it back, and the actual resolution still happens on the thread on which the caller is running. 

Synchronous resolution has no suspension point at which Swift can hop actors.

The fix is to resolve from the isolation the closure requires. Factory gives you two functions for exactly this.

For a main actor type, use ``Factory/resolveOnMainActor()``. It is itself `@MainActor`, so awaiting it from a background context performs the hop before resolution runs.

```swift
Task.detached {
    let viewModel = await Container.shared.contentViewModel.resolveOnMainActor()
    await viewModel.load()
}
```

For any other global actor, use ``Factory/resolveOnGlobalActor(_:)`` and pass the actor's `shared` instance. Its `isolated` parameter makes the call run on that actor.

```swift
Task.detached {
    let manager = await Container.shared.dataManager.resolveOnGlobalActor(BackgroundActor.shared)
    let data = manager.fetch()
}
```

`ParameterFactory` has the same two functions, with the runtime parameter threaded through.

```swift
Task.detached {
    let viewModel = await Container.shared.editorViewModel.resolveOnMainActor(documentID)
    let manager = await Container.shared.importer.resolveOnGlobalActor(BackgroundActor.shared, parameters: url)
}
```

A word of caution on ``Factory/resolveOnGlobalActor(_:)``. You are responsible for passing the actor the registration is actually isolated to. The `Factory` type does not carry the closure's isolation, so the compiler cannot check that the actor you pass matches the actor the closure needs. Pass the wrong one and it hops to that actor, runs the closure in the wrong place, and traps just as before. ``Factory/resolveOnMainActor()`` has no such risk, since there is no actor to get wrong.

Unfortunately, Swift doesn't allow any way to automate this.

The shorter version of all this: if a factory is annotated for an actor, resolve it from that actor. Most code already does, by virtue of where it runs. 

When it doesn't, these two functions move the resolution to the right place.
