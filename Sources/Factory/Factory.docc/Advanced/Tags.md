# Tags

Obtaining a list of dependencies of a given type.

## Overview

Some dependency injection systems offer functionality known as tagging. Once tagged, you can ask the system for a list of all registered dependencies that conform to that tag.

```swift
let processors = container.resolve(tagged: "processor")
```
Sometimes the tag is explicitly defined during the registration process, like .tag("processors"). In other systems, you might ask the system for everything registered that conforms to a specific type.
```swift
let processors = container.resolve(Processing.self)
```
Doing this sort of thing in Factory is somewhat problematic, in that in most cases for most instances there *isn't* a registration phase. Factory's are lazy creatures, and they're not evaluated until the Factory is requested. 

So what can we do?

## Simple Solution

Consider the following Factory registrations.
```swift
extension SharedContainer {
    var processor1: Factory<Processor> { self { Processor1() } }
    var processor2: Factory<Processor> { self { Processor2() } }
}
```
And now the following container extension added to our main application.
```swift
extension Container {
    public static var processors: [KeyPath<Container, Factory<Processor>>] = [
        \.processor1,
        \.processor2,
    ]
}
```
Here we build a simple list of keyPaths that defines all known processors. As discussed in multiple module support, the root application should know what systems are available to it.

Once that's done, accomplishing the lookup and getting the list of actual processors is a piece of cake.
```swift
extension Container {
    public func processors() -> [Processor] {
        Container.processors.map { self[keyPath: $0]() }
    }
}
```
And since the keyPath definition guarantees the type of the object, the array will also be type safe, something that can be difficult to accomplish with simple string-based tagging systems.

But we can do more.

## Appending New Processors

First, note that anything could be added to the array at any point in time. 
```swift
extension Container: AutoRegistering {
    func autoRegister() {
        Container.processors.append(\.processor3)
    }
    var processor3: Factory<Processor> { self { Processor3() } }
}
```

## Multiple Modules and Anonymous Processors
Above we mentioned that that main app should know what processors are available to it. That said, sometime you may not.

In that case you could ask a set of modules for their own, anonymous contributions.
```swift
extension Container: AutoRegistering {
    func autoRegister() {
        Container.processors += ModuleA.availableProcessors()
        Container.processors += ModuleB.availableProcessors()
        Container.processors += ModuleC.availableProcessors()
    }
}
```

## Priority

The basic solution can obviously be expanded as needed, perhaps by creating a struct that allows for tag priority.

```swift
struct Tag<T> {
    let path: KeyPath<Container, Factory<T>>
    let priority: Int
}

extension Container {
    static var processors: [Tag<Processor>] = [
        Tag(path: \.processor1, priority: 20),
        Tag(path: \.processor2, priority: 10),
    ]
    func processors() -> [Processor] {
        Container.processors
            .sorted(by: { $0.priority < $1.priority })
            .map { self[keyPath: $0.path]() }
    }
}
```
While Factory doesn't currently support tags out of the box, there are a lot of ways to roll your own solutions using the tools Factory provides. 
