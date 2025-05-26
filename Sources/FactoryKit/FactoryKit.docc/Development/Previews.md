# SwiftUI Previews

Mocking dependencies for SwiftUI Previews.

## Overview

Factory can make SwiftUI Previews easier when we're using View Models and those view models depend on internal dependencies. Let's take a look.

## SwiftUI Previews

Here's an example of updating a view model's service dependency in order to setup a particular state for  preview.

```swift
// the view model
class ContentViewModel: ObservableObject {
    @Injected(\.myService) private var service
    ...
    func load() async {
        let results = await service.load()
        ...
    }
}

// the view
struct ContentView: View {
    @StateObject var viewModel = ContentViewModel()
    var body: some View {
        ...
    }
}

// the preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let _ = Container.shared.myService.register { MockServiceN(4) }
        ContentView()
    }
}
```
If we can control where and how the view model gets its data then we can put the view model into pretty much any state we choose.

## SwiftUI #Previews

The same can be done using the new macro-based #Preview option added to Xcode 15.

```swift
#Preview {
    let _ = Container.shared.myService.register { MockServiceN(4) }
    ContentView()
}
```
In fact, this `let _ = Container.shared.xxx.register` syntax happens so frequently that Factory 2.5 added some sugar to make it a bit easier.

```swift
#Preview {
    Container.shared.myService.preview { MockServiceN(4) }
    ContentView()
}
```
The `preview` modifier wraps `register` and also returns an EmptyView, satisfying SwiftUI's ViewBuilder and eliminating the need for `let _ =`.

## Multiple Registrations

There's also a variant for Containers if you need to do multiple registrations.
```swift
#Preview {
    Container.preview {
        $0.myService.register { MockServiceN(4) }
        $0.anotherService.register { MockAnotherService() }
    }
    ContentView()
}
```

## Multiple Previews

If we want to do multiple previews at once, each with different data, we simply need to instantiate our view models and pass them into the view as parameters.

Prior to Xcode 15 and given the ContentView we used above, we'd need to do:

```swift
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            let _ = Container.shared.myService.register { MockServiceN(4) }
            let vm1 = ContentViewModel()
            ContentView(viewModel: vm1)
            
            let _ = Container.shared.myService.register { MockServiceN(8) }
            let vm2 = ContentViewModel()
            ContentView(viewModel: vm2)
        }
    }
}
```
Of course, it's even easier with #Preview as each one runs in its own context..
```swift
#Preview {
    Container.shared.myService.preview { MockServiceN(4) }
    ContentView()
}
#Preview {
    Container.shared.myService.preview { MockServiceN(0) }
    ContentView()
}
```
Since the #Preview macro has been back-ported to iOS 13, there's really no need to use the old syntax.

## Common Setup

If we have several mocks that we use all of the time in our previews or unit tests, we can also add a setup function to a given container to make this easier.

```swift
extension Container {
    func setupMocks() {
        myService.register { MockServiceN(4) }
        sharedService.register { MockService2() }
    }
}

#Preview {
    let _ = Container.shared.setupMocks()
    ContentView()
}
```
Or if you want to roll with the cool kids and continue with the preview syntax...
```swift
extension Container {
    func setupMocks() -> EmptyView {
        myService.register { MockServiceN(4) }
        sharedService.register { MockService2() }
        return EmptyView()
    }
}

#Preview {
    Container.shared.setupMocks()
    ContentView()
}
```

