# Functional Injection

Factory can inject more than service classes and structs. 

## Overview 

Functional Injection is a powerful tool that can, in many cases, eliminate the need for defining protocols, implementations, and the various stubs and mocks one needs when doing traditional Protocol-Oriented-Programing.

## Example

Consider the following typealias and Factory.
```swift
typealias AccountProviding = () async throws -> [Account]

extension Container {
    var accountProvider: Factory<AccountProviding> {
        self {{ try await Network.get(path: "/accounts") }}
    }
}
```
Note the double braces. In this example our factory closure is returning a closure, not a class or struct.

Now, here's the view model that uses it.

```swift
class AccountViewModel: ObservableObject {
    @Injected(\.accountProvider) var accountProvider
    @Published var accounts: [Account] = []
    @MainActor func load() async {
        do {
            accounts = try await accountProvider()
        } catch {
            print(error)
        }
    }
}
```

## Testing

Now consider how easy it is to write a test with mock accounts...

```swift
func testAllAccounts() async {
    Container.shared.accountProvider.register {{ Account.mockAccounts }}
    do {
        let viewModel = AccountViewModel()
        try await viewModel.load()
        XCTAssert(viewModel.accounts.count == 5)
    } catch {
        XCTFail("Account load failed")
    }
}
```
Or test edge cases like no accounts found. 
```swift
func testEmptyAccounts() async {
    Container.shared.accountProvider.register {{ [] }}
    ...
}
```
Or test specific error cases.
```swift
func testErrorLoadingAccounts() async {
    Container.shared.accountProvider.register {{ throw APIError.network }}
    ...
}
```
Here's an article that goes into the technique in more detail: [Factory and Functional Dependency Injection](https://betterprogramming.pub/factory-and-functional-dependency-injection-2d0a38042d05)

