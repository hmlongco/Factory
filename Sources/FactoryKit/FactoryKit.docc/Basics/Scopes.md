# Scopes

Not everything wants to be a Singleton. Learn the power of Scopes.

## Overview

If you've used Resolver or some other dependency injection system before then you've probably experienced the benefits and power of scopes.

And if not, the concept is easy to understand: Just how long should an instance of an object live?

You've no doubt stuffed an instance of a class into a static variable and created a singleton at some point in your career. This is an example of a scope. A single instance is created and then used and shared by all of the methods and functions in the app.

This is easily done in Factory.

## Singleton

Just specify a singleton factory.

```swift
extension Container {
    var myService: Factory<MyServiceType> { 
        self { MyService() }
            .singleton
    }
}
```
Now whenever someone requests an instance of `myService` they'll get the same instance of the object as everyone else.

```swift
let a = container.myService()
let b = container.myService()
```
When we do this, both `a` and `b` refer to the same instance.

Singletons are easy to create, but they should be used with care. Like static singletons you might create in your own code, using singleton scopes can become problematic when testing your code and often require special handling. See <doc:Testing> for more information on how to handle this.

Another issue to keep in mind is that singletons are global, meaning that they're *not* managed or cached by any specific container. If we create two instances of the above container and resolve `myService` from both, we'll get the *same* instance from both.

Then again, that's kind of the idea, isn't it?

Just keep in mind with Factory you have other options. Only use define a scope as singleton when there's an overriding need for there to be one *and only one* instance of an object.

So what do we do if we need our object to be cached?

Just say so.

## Cached

Cached items are persisted until the cache is reset or the container is deallocated. Consider the following Factory registration.

```swift
extension Container {
    var cachedService: Factory<MyServiceType> { 
        self { MyService() }.cached
    }
}
```
Now let's resolve it.
```swift
let a = container.cachedService()
let b = container.cachedService()
```
When we do this we see that both `a` and `b` reference the same instance, just as we saw with the singleton example above.

Cached scopes are Factory's workhorses. They make unit testing a lot easier and should be your first choice when you're looking for a caching solution.

## Shared

Shared items exist just as long as someone holds a strong reference to them. When the last reference goes away, the weakly held shared reference also goes away.

```swift
extension Container {
    var sharedService: Factory<MyServiceType> { 
        self { MyService() }.shared
    }
}
```
Now let's resolve it.
```swift
// resolution
var a = container.sharedService()
var b = container.sharedService()
// zap all strong references
a = nil
b = nil
// resolve it again
var c = container.sharedService()
```
When `a` was resolved it was cached in the shared cache. When `b` is resolved it's pulled from the cache as we might expect. But when the last strong external reference to `a` and `b` is released (set to nil in the example), the weak reference maintained by the shared cache is also released.

So when we resolve `c` we're going to get a new instance, and the cycle proceeds anew.

## Custom Scopes

You can also add your own special purpose caches to the mix. Try this.

```swift
extension Scope {
    static let session = Cached()
}

extension Container {
    var authenticatedUser: Factory<AuthenticatedUser> { 
        self { AuthenticatedUser() }
            .scope(.session)
    }
    var profileImageCache: Factory<ProfileImageCache> { 
        self { ProfileImageCache() } 
            .scope(.session)
    }
}
```
Once created, a single instance of `AuthenticatedUser` and `ProfileImageCache` will be provided to anyone that needs one... up until the point where the session scope is reset, perhaps by a user logging out.

```swift
func logout() {
    Container.shared.manager.reset(scope: .session)
        ...
    }
```
One note: Like shared variables in custom containers, don't forget to define the new scope as a 'let' variable, not 'var'. Defining it as a 'static var' will cause Swift to issue concurrency warnings in the future whenever that variable is accessed.

Custom scopes are powerful tools to have in your arsenal. Use them.

## Graph Scope

There's one additional scope, called `graph`. This scope will reuse any factory instances resolved during a given resolution cycle. This can come in handy when a single class implements multiple protocols. Consider the following...
```swift
class ProtocolConsumer {
    @Injected(\.idProvider) var ids
    @Injected(\.valueProvider) var values
    init() {}
}
```
The `ProtocolConsumer` wants two different protocols. But it doesn't know that a single class provides both services. (Nor should it care.) Take a look at the referenced factories.
```swift
extension Container {
    // the root
    var consumer: Factory<ProtocolConsumer> { self { ProtocolConsumer() } }
    // the interfaces
    var idProvider: Factory<IDProviding> { self { commonProviding() } }
    var valueProvider: Factory<ValueProviding> { self { commonProviding() } }
    // the common implementation
    private var commonProviding: Factory<MyService> { self { MyService() }.graph }
}
```
Both provider factories reference the same factory. When Factory is asked for an instance of `consumer`, both providers will receive the same instance of `MyService`.

There are a few caveats and considerations for using graph. The first is that anyone who wants to participate in the graph needs to explicitly state as such using the graph scope. Note the scope parameter for `commonProviding`.

The second is that there needs to be a "root" to the graph. 

In the above example, the `consumer` object is the root. Factory is asked for a consumer, which in turn requires two providers. 

If you were to instantiate an instance of `ProtocolConsumer` yourself, each one of ProtocolConsumer's Injected property wrappers would initialize sequentially on the same thread, resulting in two separate and distinct resolution cycles.

See: <doc:Cycle> for more on this.

## Unique

The last scope we're going to discuss is `unique`. When unique is specified a new instance of the service will be instantiated and returned each and every time one is requested from the factory.

Everyone gets a new, unique instance.

Unique.

The default scope for any given Factory is `unique`. That said...

## Default Scope

Factory's can have their scopes defined in two different ways:

1. We can use a scope modifier, as we've shown above.
2. We don't specify a scope at all, in which case the scope *usually* defaults to `unique`.

The key word here is *usually*, because Factory lets you control the default scope on a per-container basis.

```swift
extension Container: AutoRegistering {
    func autoRegister() {
        manager.defaultScope = .cached
        ...
    }
}
```
Now any Factory registration resolved on that container that *doesn't specify a scope of its own* will use the `cached` scope by default.

## Lifecycles

Scope caches for all types except singletons are maintained by the Factory's container.

If I create an instance of `Container` and use it to resolve `cachedService` three times, I'll get the same instance of the object each time.

```swift
let a = container.cachedService()
let b = container.cachedService()
let c = container.cachedService()
```
In this example, a, b, and c are identical.

But if we create two instances of the above container and resolve `cachedService` from both, we'll get two different instances of the service.
```swift
let a = container1.cachedService()
let b = container2.cachedService()
```
Scope is managed by the container.

> Warning: If a container ever goes out of scope, so will all of its registrations and cached objects.

See the "Releasing a Container" discussion in <doc:Containers> for more information.

## TimeToLive

Factory provides a "time to live" option for scoped dependencies. 

```swift
extension Container {
    var authenticatedUser: Factory<AuthenticatedUser> { 
        self { AuthenticatedUser() }
            .scope(.session)
            .timeToLive(60 * 20) // (60 seconds * 20) = 20 minutes
    }
}
```

As shown above, set a time to live for 20 minutes and any new request for that dependency that occurs *after* that period will discard the previously cached item, caching and returning a new instance instead.

Requesting a cached item before the timeout period ends returns the currently cached item and effectively restarts the clock for that item.

Like registrations, setting a time to live on a dependency only affects the *next* resolution for that item. Anything already resolved and referenced stays resolved and referenced.

## Reset

As mentioned earlier in the discussion on custom scopes, individual scope caches on a container can be reset (cleared) if needed.
```swift
// clear the default cached scope
Container.shared.manager.reset(scope: .cached)
// clear everything cached by the custom session scope
Container.shared.manager.reset(scope: .session)
```
You can reset the cache for *all* of the scopes managed by that container.
```swift
Container.shared.manager.reset(options: .scope)
```
As mentioned earlier, Singletons are global and they're *not* managed by any particular container. If needed, the singleton scope can be reset directly.
```swift
Scope.singleton.reset()
```
> Important: Resetting a container or scope has no effect whatsoever on anything that's already been resolved by Factory. It only ensures that the *next* time a Factory on that container is asked to resolve a dependency that dependency will be a new instance.

## ParameterFactory Scopes

By default, ParameterFactory scopes will cache the first requested value and then return that value, even if other values are passed on future requests.

The behavior can be changed with the `.scopeOnParameters` modifier.
```swift
var parameterService: ParameterFactory<Int, ParameterService> {
     self { ParameterService(value: $0) }.scopeOnParameters.cached
}
```
The passed parameter must be Hashable for this modifier to appear and for the per-parameter caching functionality to occur.

## Topics

### Scope Class Definitions

- ``Scope``
- ``Scope/Cached-swift.class``
- ``Scope/Graph-swift.class``
- ``Scope/Shared-swift.class``
- ``Scope/Singleton-swift.class``
