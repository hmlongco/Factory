# ``Factory``

A new approach to Container-Based Dependency Injection for Swift and SwiftUI.

## Overview

Factory is strongly influenced by SwiftUI, and in my opinion is highly suited for use in that environment. 

Factory is...

- **Adaptable**: Factory doesn't tie you down to a single dependency injection strategy or technique.
- **Powerful**: Factory supports containers, scopes, passed parameters, decorators, unit tests, SwiftUI Previews, and much, much more.
- **Performant**: Little to no setup time is needed for the vast majority of your services, resolutions are extremely fast, and no compile-time scripts or build phases are needed.
- **Safe**: Factory is compile-time safe; a factory for a given type must exist or the code simply will not compile.
- **Concise**: Defining a registration usually takes just a single line of code. Same for resolution.
- **Flexible**: Working with UIKIt or SwiftUI? iOS or macOS? Using MVVM? MVP? Clean? VIPER? No problem. Factory works with all of these and more.
- **Documented**: Factory 2.0 has extensive DocC documentation and examples covering its classes, methods, and use cases.
- **Lightweight**: With all of that Factory is slim and trim, just 428 lines of executable code and half the size of Resolver.
- **Tested**: Unit tests with 100% code coverage helps ensure correct operation of registrations, resolutions, and scopes.
- **Free**: Factory is free and open source under the MIT License.

Ready to get started?

## Topics

### The Basics

- <doc:GettingStarted>
- <doc:Containers>
- <doc:Scopes>

### Development and Testing

- <doc:Previews>
- <doc:Testing>
- <doc:Debugging>
- <doc:Chains>

### Advanced Topics

- <doc:Design>
- <doc:Modules>
- <doc:Cycle>
- <doc:Optionals>
- <doc:Functional>

### Addtional Topics

- <doc:Competition>
- <doc:Migration>
