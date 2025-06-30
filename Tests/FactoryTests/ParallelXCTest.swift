#if swift(>=5.5)

import XCTest
import FactoryTesting
@testable import FactoryKit

/// Illustrates using the regular `XCTestCase` with `FactoryTesting.withContainer` to enable parallel XCTests.
final class ParallelXCTestFoo: XCTestCase {
    func testFoo() {
        let fooExpectation = expectation(description: "foo")

        withContainer(
            shared: Container.$shared,
            container: Container()
        ) {
            let c = Container.shared
            c.fooBarBaz.register { Foo() }
            c.fooBarBazCached.register { Foo() }
            c.fooBarBazSingleton.register { Foo() }

            commonTests("foo")
            fooExpectation.fulfill()
        }

        wait(for: [fooExpectation], timeout: 60)
    }
}

final class ParallelXCTestBar: XCTestCase {
    func testBar() {
        let barExpectation = expectation(description: "bar")

        withContainer(
            shared: Container.$shared,
            container: Container()
        ) {
            let c = Container.shared
            c.fooBarBaz.register { Bar() }
            c.fooBarBazCached.register { Bar() }
            c.fooBarBazSingleton.register { Bar() }

            commonTests("bar")
            barExpectation.fulfill()
        }

        wait(for: [barExpectation], timeout: 60)
    }
}

final class ParallelXCTestBaz: XCTestCase {
    func testBaz() {
        let bazExpectation = expectation(description: "baz")

        withContainer(
            shared: Container.$shared,
            container: Container()
        ) {
            let c = Container.shared
            c.fooBarBaz.register { Baz() }
            c.fooBarBazCached.register { Baz() }
            c.fooBarBazSingleton.register { Baz() }

            commonTests("baz")
            bazExpectation.fulfill()
        }

        wait(for: [bazExpectation], timeout: 60)
    }
}

// Illustrates using the withContainer() helper with a synchronous transform closure
final class ParallelXCTestFooWithContainerAndTransform: XCTestCase {
    func testFooWithContainerSyncTransform() {
        let fooExpectation = expectation(description: "foo")

        withContainer(
            shared: Container.$shared,
            container: Container()
        ) {
            commonTests("foo")
            fooExpectation.fulfill()
        } transform: {
            $0.fooBarBaz.register { Foo() }
            $0.fooBarBazCached.register { Foo() }
            $0.fooBarBazSingleton.register { Foo() }
        }

        wait(for: [fooExpectation], timeout: 60)
    }
}

// Illustrates using the withContainer() helper with a synchronous transform closure
final class ParallelXCTestBarWithContainerAndTransform: XCTestCase {
    func testBarWithContainerSyncTransform() {
        let barExpectation = expectation(description: "bar")

        withContainer(
            shared: Container.$shared,
            container: Container()
        ) {
            commonTests("bar")
            barExpectation.fulfill()
        } transform: {
            $0.fooBarBaz.register { Bar() }
            $0.fooBarBazCached.register { Bar() }
            $0.fooBarBazSingleton.register { Bar() }
        }

        wait(for: [barExpectation], timeout: 60)
    }
}

// Illustrates using the withContainer() helper with a synchronous transform closure
final class ParallelXCTestBazWithContainerAndTransform: XCTestCase {
    func testBazWithContainerSyncTransform() {
        let bazExpectation = expectation(description: "baz")

        withContainer(
            shared: Container.$shared,
            container: Container()
        ) {
            commonTests("baz")
            bazExpectation.fulfill()
        } transform: {
            $0.fooBarBaz.register { Baz() }
            $0.fooBarBazCached.register { Baz() }
            $0.fooBarBazSingleton.register { Baz() }
        }

        wait(for: [bazExpectation], timeout: 60)
    }
}

// Illustrates using the withContainer() helper asynchronously
final class ParallelXCTestFooWithContainerAndAsyncTransform: XCTestCase {
    func testFooWithContainerAsync() async {
        let fooExpectation = expectation(description: "foo")

        await withContainer(
            shared: Container.$shared,
            container: Container()
        ) {
            Container.shared.fooBarBaz.register { Foo() }
            Container.shared.fooBarBazCached.register { Foo() }
            Container.shared.fooBarBazSingleton.register { Foo() }

            await Container.shared.isolatedToMainActor.register { @MainActor in MainActorFooBarBaz(value: "foo") }
            await Container.shared.isolatedToMainActorCached.register { @MainActor in MainActorFooBarBaz(value: "foo") }
            await Container.shared.isolatedToMainActorSingleton.register { @MainActor in MainActorFooBarBaz(value: "foo") }

            await Container.shared.isolatedToCustomGlobalActor.register { IsolatedFoo() }
            await Container.shared.isolatedToCustomGlobalActorCached.register { IsolatedFoo() }
            await Container.shared.isolatedToCustomGlobalActorSingleton.register { IsolatedFoo() }

            await isolatedAsyncTests("foo")
            fooExpectation.fulfill()
        }

        await fulfillment(of: [fooExpectation], timeout: 60)
    }
}

// Illustrates using the withContainer() helper with an asynchronous transform closure
final class ParallelXCTestBarWithContainerAndAsyncTransform: XCTestCase {
    func testBarWithContainerAsyncTransform() async {
        let barExpectation = expectation(description: "bar")

        await withContainer(
            shared: Container.$shared,
            container: Container()
        ) {
            await isolatedAsyncTests("bar")
            barExpectation.fulfill()
        } transform: {
            $0.fooBarBaz.register { Bar() }
            $0.fooBarBazCached.register { Bar() }
            $0.fooBarBazSingleton.register { Bar() }

            await $0.isolatedToMainActor.register { @MainActor in MainActorFooBarBaz(value: "bar") }
            await $0.isolatedToMainActorCached.register { @MainActor in MainActorFooBarBaz(value: "bar") }
            await $0.isolatedToMainActorSingleton.register { @MainActor in MainActorFooBarBaz(value: "bar") }

            await $0.isolatedToCustomGlobalActor.register { IsolatedBar() }
            await $0.isolatedToCustomGlobalActorCached.register { IsolatedBar() }
            await $0.isolatedToCustomGlobalActorSingleton.register { IsolatedBar() }
        }

        await fulfillment(of: [barExpectation], timeout: 60)
    }
}

// Illustrates using the withContainer() helper with an asynchronous transform closure
final class ParallelXCTestBazWithContainerAndAsyncTransform: XCTestCase {
    func testBazWithContainerAsyncTransform() async {
        let bazExpectation = expectation(description: "baz")

        await withContainer(
            shared: Container.$shared,
            container: Container()
        ) {
            await isolatedAsyncTests("baz")
            bazExpectation.fulfill()
        } transform: {
            $0.fooBarBaz.register { Baz() }
            $0.fooBarBazCached.register { Baz() }
            $0.fooBarBazSingleton.register { Baz() }

            await $0.isolatedToMainActor.register { @MainActor in MainActorFooBarBaz(value: "baz") }
            await $0.isolatedToMainActorCached.register { @MainActor in MainActorFooBarBaz(value: "baz") }
            await $0.isolatedToMainActorSingleton.register { @MainActor in MainActorFooBarBaz(value: "baz") }

            await $0.isolatedToCustomGlobalActor.register { IsolatedBaz() }
            await $0.isolatedToCustomGlobalActorCached.register { IsolatedBaz() }
            await $0.isolatedToCustomGlobalActorSingleton.register { IsolatedBaz() }
        }

        await fulfillment(of: [bazExpectation], timeout: 60)
    }
}

/// Illustrates using the `XCContainerTestCase`
final class ParallelXCContainerTestFoo: XCContainerTestCase {
    func testFoo() {
        let c = Container.shared
        c.fooBarBaz.register { Foo() }
        c.fooBarBazCached.register { Foo() }
        c.fooBarBazSingleton.register { Foo() }

        commonTests("foo")
    }
}

/// Illustrates using the `XCContainerTestCase`
final class ParallelXCContainerTestBar: XCContainerTestCase {
    func testBar() {
        let c = Container.shared
        c.fooBarBaz.register { Bar() }
        c.fooBarBazCached.register { Bar() }
        c.fooBarBazSingleton.register { Bar() }

        commonTests("bar")
    }
}

/// Illustrates using the `XCContainerTestCase`
final class ParallelXCContainerTestBaz: XCContainerTestCase {
    func testBaz() {
        let c = Container.shared
        c.fooBarBaz.register { Baz() }
        c.fooBarBazCached.register { Baz() }
        c.fooBarBazSingleton.register { Baz() }

        commonTests("baz")
    }
}

/// Illustrates using the `XCContainerTestCase` with different isolations.
final class ParallelIsolatedXCTestsFoo: XCContainerTestCase {
    func testIsolatedFoo() async {
        let c = Container.shared

        c.fooBarBaz.register { Foo() }
        c.fooBarBazCached.register { Foo() }
        c.fooBarBazSingleton.register { Foo() }

        await c.isolatedToMainActor.register { @MainActor in MainActorFooBarBaz(value: "foo") }
        await c.isolatedToMainActorCached.register { @MainActor in MainActorFooBarBaz(value: "foo") }
        await c.isolatedToMainActorSingleton.register { @MainActor in MainActorFooBarBaz(value: "foo") }

        await c.isolatedToCustomGlobalActor.register { IsolatedFoo() }
        await c.isolatedToCustomGlobalActorCached.register { IsolatedFoo() }
        await c.isolatedToCustomGlobalActorSingleton.register { IsolatedFoo() }

        await isolatedAsyncTests("foo")
    }
}

/// Illustrates using the `XCContainerTestCase` with different isolations.
final class ParallelIsolatedXCTestsBar: XCContainerTestCase {
    func testIsolatedBar() async {
        let c = Container.shared

        c.fooBarBaz.register { Bar() }
        c.fooBarBazCached.register { Bar() }
        c.fooBarBazSingleton.register { Bar() }

        await c.isolatedToMainActor.register { @MainActor in MainActorFooBarBaz(value: "bar") }
        await c.isolatedToMainActorCached.register { @MainActor in MainActorFooBarBaz(value: "bar") }
        await c.isolatedToMainActorSingleton.register { @MainActor in MainActorFooBarBaz(value: "bar") }

        await c.isolatedToCustomGlobalActor.register { IsolatedBar() }
        await c.isolatedToCustomGlobalActorCached.register { IsolatedBar() }
        await c.isolatedToCustomGlobalActorSingleton.register { IsolatedBar() }

        await isolatedAsyncTests("bar")
    }
}

/// Illustrates using the `XCContainerTestCase` with the transform sugar via the initalizer and with different isolations.
final class ParallelIsolatedXCTestsBaz: XCContainerTestCase {

    /// Overriding the transform property to register dependencies in the Container for every unit test inside this class.
    /// This is a synchronous transform, so it should not contain any async code, unlike the `transform` in the `ContainerTrait` for `swift-testing`.
    override var transform: (@Sendable (Container) -> Void)? {
        get {
            {
                $0.fooBarBaz.register { Baz() }
                $0.fooBarBazCached.register { Baz() }
                $0.fooBarBazSingleton.register { Baz() }
            }
        }
        set { }
    }

    func testIsolatedBaz() async {
        let c = Container.shared

        await c.isolatedToMainActor.register { @MainActor in MainActorFooBarBaz(value: "baz") }
        await c.isolatedToMainActorCached.register { @MainActor in MainActorFooBarBaz(value: "baz") }
        await c.isolatedToMainActorSingleton.register { @MainActor in MainActorFooBarBaz(value: "baz") }

        await c.isolatedToCustomGlobalActor.register { IsolatedBaz() }
        await c.isolatedToCustomGlobalActorCached.register { IsolatedBaz() }
        await c.isolatedToCustomGlobalActorSingleton.register { IsolatedBaz() }

        await isolatedAsyncTests("baz")
    }
}

final class ParallelCustomContainerTest: XCCustomContainerTestCase {
    func testCustomContainer() {
        let sut1 = CustomContainer.shared.myServiceType()
        XCTAssertEqual(sut1.text(), "MyService")
        CustomContainer.shared.myServiceType.register { MockService() }
        let sut2 = CustomContainer.shared.myServiceType()
        XCTAssertEqual(sut2.text(), "MockService")
    }
}

/// Illustrates using multiple containers with a custom withContainer variant
final class ParallelWithContainerAndCustomContainerTest: XCTestCase {
    func testContainerAndCustomContainer() {
        withContainerAndCustomContainer {
            commonTests("baz")

            let sut1 = CustomContainer.shared.myServiceType()
            XCTAssertEqual(sut1.text(), "MyService")
            CustomContainer.shared.myServiceType.register { MockService() }
            let sut2 = CustomContainer.shared.myServiceType()
            XCTAssertEqual(sut2.text(), "MockService")
        } containerTransform: {
            $0.fooBarBaz.register { Baz() }
            $0.fooBarBazCached.register { Baz() }
            $0.fooBarBazSingleton.register { Baz() }
        }
    }
}

/// Illustrates using multiple containers with a custom XCContainerAndCustomContainerTestCase
final class ParallelContainerAndCustomContainerTest: XCContainerAndCustomContainerTestCase {
    func testContainerAndCustomContainer() {
        let c = Container.shared
        c.fooBarBaz.register { Baz() }
        c.fooBarBazCached.register { Baz() }
        c.fooBarBazSingleton.register { Baz() }

        commonTests("baz")

        let sut1 = CustomContainer.shared.myServiceType()
        XCTAssertEqual(sut1.text(), "MyService")
        CustomContainer.shared.myServiceType.register { MockService() }
        let sut2 = CustomContainer.shared.myServiceType()
        XCTAssertEqual(sut2.text(), "MockService")
    }
}

private func commonTests(_ value: String) {
    let sut1 = TaskLocalUseCase()
    XCTAssertEqual(sut1.fooBarBaz.value, value)
    XCTAssertEqual(sut1.fooBarBazCached.value, value)
    XCTAssertEqual(sut1.fooBarBazSingleton.value, value)

    let sut2 = TaskLocalUseCase()
    XCTAssertEqual(sut2.fooBarBaz.value, value)
    XCTAssertEqual(sut2.fooBarBazCached.value, value)
    XCTAssertEqual(sut2.fooBarBazSingleton.value, value)

    XCTAssertNotEqual(sut1.fooBarBaz.id, sut2.fooBarBaz.id)
    XCTAssertEqual(sut1.fooBarBazCached.id, sut2.fooBarBazCached.id)
    XCTAssertEqual(sut1.fooBarBazSingleton.id, sut2.fooBarBazSingleton.id)

    Container.shared.fooBarBazSingleton.register { Foo() }

    let sut3 = TaskLocalUseCase()
    XCTAssertEqual(sut3.fooBarBazSingleton.value, "foo")
    XCTAssertNotEqual(sut1.fooBarBazSingleton.id, sut3.fooBarBazSingleton.id)
}

@MainActor
private func isolatedAsyncTests(_ value: String) async {
    let sut1 = await IsolatedTaskLocalUseCase()

    XCTAssertEqual(sut1.fooBarBaz.value, value)
    XCTAssertEqual(sut1.fooBarBazCached.value, value)
    XCTAssertEqual(sut1.fooBarBazSingleton.value, value)

    XCTAssertEqual(sut1.isolatedToMainActor.value, value)
    XCTAssertEqual(sut1.isolatedToMainActorCached.value, value)
    XCTAssertEqual(sut1.isolatedToMainActorSingleton.value, value)

    XCTAssertEqual(sut1.isolatedToCustomGlobalActor.value, value)
    XCTAssertEqual(sut1.isolatedToCustomGlobalActorCached.value, value)
    XCTAssertEqual(sut1.isolatedToCustomGlobalActorSingleton.value, value)

    let sut2 = await IsolatedTaskLocalUseCase()
    XCTAssertEqual(sut2.fooBarBaz.value, value)
    XCTAssertEqual(sut2.fooBarBazCached.value, value)
    XCTAssertEqual(sut2.fooBarBazSingleton.value, value)

    XCTAssertEqual(sut2.isolatedToMainActor.value, value)
    XCTAssertEqual(sut2.isolatedToMainActorCached.value, value)
    XCTAssertEqual(sut2.isolatedToMainActorSingleton.value, value)

    XCTAssertEqual(sut2.isolatedToCustomGlobalActor.value, value)
    XCTAssertEqual(sut2.isolatedToCustomGlobalActorCached.value, value)
    XCTAssertEqual(sut2.isolatedToCustomGlobalActorSingleton.value, value)

    XCTAssertNotEqual(sut1.fooBarBaz.id, sut2.fooBarBaz.id)
    XCTAssertEqual(sut1.fooBarBazCached.id, sut2.fooBarBazCached.id)
    XCTAssertEqual(sut1.fooBarBazSingleton.id, sut2.fooBarBazSingleton.id)

    XCTAssertNotEqual(sut1.isolatedToMainActor.id, sut2.isolatedToMainActor.id)
    XCTAssertEqual(sut1.isolatedToMainActorCached.id, sut2.isolatedToMainActorCached.id)
    XCTAssertEqual(sut1.isolatedToMainActorSingleton.id, sut2.isolatedToMainActorSingleton.id)

    XCTAssertNotEqual(sut1.isolatedToCustomGlobalActor.id, sut2.isolatedToCustomGlobalActor.id)
    XCTAssertEqual(sut1.isolatedToCustomGlobalActorCached.id, sut2.isolatedToCustomGlobalActorCached.id)
    XCTAssertEqual(sut1.isolatedToCustomGlobalActorSingleton.id, sut2.isolatedToCustomGlobalActorSingleton.id)

    Container.shared.fooBarBazSingleton.register { Foo() }
    Container.shared.isolatedToMainActorSingleton.register { @MainActor in  MainActorFooBarBaz(value: "foo") }
    await Container.shared.isolatedToCustomGlobalActorSingleton.register { IsolatedFoo() }

    let sut3 = await IsolatedTaskLocalUseCase()
    XCTAssertEqual(sut3.fooBarBazSingleton.value, "foo")
    XCTAssertEqual(sut3.isolatedToMainActorSingleton.value, "foo")
    XCTAssertEqual(sut3.isolatedToCustomGlobalActorSingleton.value, "foo")

    XCTAssertNotEqual(sut1.fooBarBazSingleton.id, sut3.fooBarBazSingleton.id)
    XCTAssertNotEqual(sut1.isolatedToMainActorSingleton.id, sut3.isolatedToMainActorSingleton.id)
    XCTAssertNotEqual(sut1.isolatedToCustomGlobalActorSingleton.id, sut3.isolatedToCustomGlobalActorSingleton.id)
}
#endif
