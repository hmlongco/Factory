import XCTest
@testable import Factory

private struct SomeSendableType: Sendable {}

private struct AsyncInitWrapper<T>: Sendable {
  let wrapped: @Sendable () async -> T
}

@MainActor
private final class SomeMainActorType: Sendable {
  init() {}
}

extension Container {
  fileprivate var sendable: Factory<SomeSendableType> {
    self { .init() }
  }

  @MainActor
  fileprivate var mainActor: Factory<AsyncInitWrapper<SomeMainActorType>> {
    self {
      .init {
        await SomeMainActorType()
      }
    }
  }
}

final class FactoryIsolationTests: XCTestCase {

  override func setUp() {
    super.setUp()
    Container.shared.reset()
  }

  func testInjectSendableDependency() {
    let _: SomeSendableType = Container.shared.sendable()
  }

  func testInjectMainActorDependency() async {
    let _: SomeMainActorType = await Container.shared.mainActor().wrapped()
  }

}
