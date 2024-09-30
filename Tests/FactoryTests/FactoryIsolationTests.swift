import XCTest
@testable import Factory

private struct SomeSendableType: Sendable {}

@MainActor
private final class SomeMainActorType: Sendable {
  init() {}
}

extension Container {
  fileprivate var sendable: Factory<SomeSendableType> {
    self { .init() }
  }

  fileprivate var mainActor: MainActorFactory<SomeMainActorType> {
    self {
      SomeMainActorType()
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
    let _: SomeMainActorType = await Container.shared.mainActor().factory()
  }

}
