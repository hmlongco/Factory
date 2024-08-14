public protocol MainActorInitiazable<Value>: Sendable {
  associatedtype Value

  var factory: @MainActor () -> Value { get }
}

public struct MainActorWrapper<Value>: MainActorInitiazable, Sendable {
  public let factory: @MainActor () -> Value

  public init(factory: @escaping @MainActor () -> Value) {
    self.factory = factory
  }
}

public typealias MainActorFactory<Value> = Factory<MainActorWrapper<Value>>

extension ManagedContainer {
  @inlinable @inline(__always) public func callAsFunction<T>(
    key: StaticString = #function,
    _ factory: @escaping @MainActor () -> T
  ) -> MainActorFactory<T> {
    .init(self, key: key) {
      MainActorWrapper {
        factory()
      }
    }
  }
}

extension Factory where T: MainActorInitiazable {
  @MainActor
  public func resolve() -> T.Value {
    callAsFunction().factory()
  }
}
