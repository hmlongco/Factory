# ``Factory``

A lightweight container-based dependency injection system for Swift.

## Overview

Factory is strongly influenced by SwiftUI, and in my opinion is highly suited for use in that environment. 

Factory is...

- **Safe**: Factory is compile-time safe; a factory for a given type must exist or the code simply will not compile.
- **Flexible**: It's easy to override dependencies at runtime and for use in SwiftUI Previews.
- **Powerful**: Like Resolver, Factory supports application, cached, shared, and custom scopes, custom containers, arguments, decorators, and more.
- **Lightweight**: With all of that Factory is slim and trim, just 500 lines of actual code and half the size of Resolver.
- **Performant**: Little to no setup time is needed for the vast majority of your services, resolutions are extremely fast, and no compile-time scripts or build phases are needed.
- **Concise**: Defining a registration usually takes just a single line of code. Same for resolution.
- **Tested**: Unit tests with 100% code coverage helps ensure correct operation of registrations, resolutions, and scopes.
- **Free**: Factory is free and open source under the MIT License.

Ready to get started?

## Topics

### The Basics

- <doc:GettingStarted>

### Advanced Topics

- <doc:GettingStarted>
