import Factory
import XCTest

/// Provides a unique Container to every unit test function in the class. Mimicking the behavior of `ContainerTrait` for `swift-testing`.
open class XCContainerTestCase: XCTestCase {

    /// The optional transformation to apply to the Container before invoking the test.
    /// Due to the nature of XCTest, this is not async and should be used for synchronous transformations only.
    open var transform: (@Sendable (Container) -> Void)?

    /// Scopes the unit test function to a unique Container instance transformed via the `transform` variable (if overridden to non-nil).
    public override func invokeTest() {
        FactoryTestingHelper.withContainer(
            super.invokeTest,
            transform: self.transform
        )
    }
}
