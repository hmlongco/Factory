# Competiton

How Factory stacks up against the competition.

## Overview

There are quite a few dependency injection libraries and systems available for Swift. In fact, there are so many that I'm begining to think that writing your own is considered to be some sort of rite of passage for an iOS developer.

## Considerations

While choosing any dependency injection system can be a subjective choice, I think a few objective considerations are also in order:

1. Is it safe?
2. Is it easy to use?
3. Is it flexible, or does it force the application into using a specific dependency injection style or pattern?
4. Are there any performance penalties to consider?

## The Competition

Here are a few of the major competitors out there, along with my thoughts on some of the pros and cons associated with each. I'm also rating each of them on the above categories on a score from 1 (low) to 5 (high).

Library | Safe | Easy | Flex | Perf
--- | --- | --- | --- | --- 
Cleanse | - | - | - | -
Dependencies | 4 | 3 | 1 | 4
Needle | - | - | - | -
Resolver | - | - | - | -
Swinject | - | - | - | -

So let's talk about them. Note that I'm splitting these out into several distinct categories based on how each one works internally.


## Type-Lookup Libraries

Most Type-Lookup libraries work by registering a set of types that can be resolved at a later point in time. These systems, while quite powerful and still in use in many applications, suffer from a couple of drawbacks.

1. They typically require pre-registration of all services up front.
2. They use type inference or specification to dynamically find and return registered services from a container.

The first drawback is relatively minor. While preregistration could lead to a performance hit on application launch, in practice the process is usually quick and not normally noticeable.

The second issue, however, is more problematic since failure to find a matching registration for that type during runtime can lead to an application crash. 

And that's why, in fact, why I created Factory.

### Cleanse

Yet to be added.

### Resolver

Yet to be added.

### Swinject

Yet to be added.


## SwiftUI Environment-Style Libraries

There are several SwiftUI Environment-Style libraries out there, all based on the pattern used by SwiftUI when creating new Environment Keys.

### Dependencies

[Dependencies](https://github.com/pointfreeco/swift-dependencies) is a small dependency injection library that uses "DependencyKeys" in a manner similar to that of SwiftUI EnvironmentKeys. This means, unfortunately, that each and every injection definition looks like the following:
```swift
private enum APIClientKey: DependencyKey {
    static let liveValue = APIClient.live
}
extension DependencyValues {
    var apiClient: APIClient {
        get { self[APIClientKey.self] }
        set { self[APIClientKey.self] = newValue }
    }
}
```
That's a lot of boilerplate for a single dependency registration.

Resolving the dependency typically occurs using a property wrapper similar to Factory's ``Injected``'.
```swift
final class FeatureModel: ObservableObject {
    @Dependency(\.apiClient) var api
}
```
Dependencies' test and mocking capabilities are somewhat limited.
```swift
func testAdd() async throws {
    let model = withDependencies {
        $0.api = MockAPI()
    } operation: {
        FeatureModel()
    }
    // test the model
}
```
As shown, one can use this and other strategies to update the dependencies on `FeatureModel`. It doesn't, however, let you reach deeper into the dependency tree and change a dependency inside of a dependency inside of a dependency like you can with Factory.

Further, note that in order to mutate the `FeatureModel` the api parameter can not be private. It must be expeosed to the outside world.

## Compile-Time Libraries

### Needle

Yet to be added.
