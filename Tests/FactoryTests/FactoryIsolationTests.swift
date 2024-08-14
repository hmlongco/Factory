import XCTest
@testable import Factory

private struct SomeSendableType: Sendable {}

extension Container {
  @MainActor
  fileprivate var instance: Factory<SomeSendableType> {
    self { .init() }
  }
}

final class FactoryIsolationTests: XCTestCase {

  override func setUp() {
    super.setUp()
    Container.shared.reset()
  }

  func testInjectMainActorDependency() async {
    let _: SomeSendableType = await Container.shared.instance()
  }

}
