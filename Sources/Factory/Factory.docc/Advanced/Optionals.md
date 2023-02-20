# Optionals and Dynamic Registration

With Factory registrations can be performed at any time. 

## Overview

Consider the following optional factory.

```swift
extension Container {
    let userProviding = Factory<UserProviding?> { unique { nil } }
}

func authenticated(with user: User) {
    ...
    Container.shared.userProviding.register { UserProvider(user: user) }
    ...
}

func logout() {
    ...
    Container.shared.userProviding.reset()
    ...
}
```
Now any view model or service that needs an instance of an authenticated user will receive one (or nothing if no user is authenticated). 

Here's an example:
```swift
class SomeViewModel: ObservableObject {
    @Injected(\.userProviding) private let provider
    func update(email: String) {
        provider?.updateEmailAddress(email)
    }
}
```
The injected provider is optional by default since the Factory was defined that way. You *could* explicitly unwrap the optional...
```swift
@Injected(\.userProviding) private let provider: UserProviding!
```

But doing so violates the core premise on which Factory was built in the first place: *Your code is guaranteed to be safe.* 

I'd advise against it.

A few other things here. First, note that we used `@Injected` to supply an optional type. We don't need a `@OptionalInjected` property wrapper to do this as we did in Resolver. Same for `@LazyInjected`.

Next, note that Factory is *thread-safe.* Registrations and resolutions lock and unlock the containers and caches as needed.

And finally, note that calling register also *removes any cached dependency from its associated scope.* This ensures that any new dependency injection request performed from that point on will always get the most recently defined instance of an object.

This technique can also be handy when doing registrations in a project with multiple modules. See: [Factory: Multiple Module Registration](https://betterprogramming.pub/factory-multiple-module-registration-f9d19721a31d?sk=a03d78484d8c351762306ff00a8be67c)

