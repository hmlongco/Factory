# Contexts

Changing injection results under special circumstances.

## Overview

This is some information on contexts.

## AutoRegister

From time to time you may find that you need to register or change some instances prior to application initialization. If so you can do the following.
```swift
extension Container: AutoRegistering {
    func autoRegister() {
        
    }
}
```
Just make `Container` conform to ``AutoRegistering`` and provide the `autoRegister` function. This function will be called *once* prior to the very first Factory service resolution on that container.

Note that this can come in handy when you want to register instances of objects obtained across different modules.
