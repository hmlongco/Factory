# Optionals and Dynamic Registration

With Factory registrations can be performed at any time. 

## Overview

Optional Factory definitions have several uses, including:

1.  Dynamic Registration - Providing Factory's based on application state.
2.  Multiple-Module Registration - Registering Factory's across modules to avoid cross-cutting concerns. 

Let's take a look.

## Dynamic Registration

Consider the following optional factory.

```swift
extension Container {
    let userProviding = Factory<UserProviding?> { self { nil } }
}
```
Looks strange, right? I mean, of what use is a Factory that returns nothing? 

Now let's take a look at a dynamic registration in action.
```swift
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
The injected provider is optional by default since the Factory was defined that way. 


## Explicitly Unwrapped Optionals

Note that you *could* explicitly unwrap the optional...
```swift
@Injected(\.userProviding) private let provider: UserProviding!
```

But doing so violates the core premise on which Factory was built in the first place: *Your code is guaranteed to be safe.* 

I'd advise against it.

A few other things here. First, note that we used `@Injected` to supply an optional type. We don't need a `@OptionalInjected` property wrapper to do this as we did in Resolver. Same for `@LazyInjected`.

And also note that calling register also *removes any cached dependency from its associated scope.* This ensures that any new dependency injection request performed from that point on will always get the most recently defined instance of an object.

## Optionals and Multiple Modules

This technique can also be handy when doing registrations in a project with multiple modules. It's a bit complex, so there's an entire page devoted to it.

See <doc:Modules> for more.

