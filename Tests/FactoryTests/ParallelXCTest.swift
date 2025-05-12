#if swift(>=5.5)

import XCTest
@testable import Factory
import FactoryTesting

final class ParallelXCTest: XCTestCase {
    //TODO: maybe delete because these examples do not contain the singleton resetting logic...
    func testFooBarBaz() {
        let container = Container()
        let fooExpectation = expectation(description: "foo")

        Container.$shared.withValue(container) {
            Container.shared.fooBarBaz.register { Foo() }

            let sut = TaskLocalUseCase()
            XCTAssertEqual(sut.fooBarBaz.value, "foo")
            fooExpectation.fulfill()
        }

        let barExpectation = expectation(description: "bar")

        Container.$shared.withValue(container) {
            Container.shared.fooBarBaz.register { Bar() }

            let sut = TaskLocalUseCase()
            XCTAssertEqual(sut.fooBarBaz.value, "bar")
            barExpectation.fulfill()
        }

        let bazExpectation = expectation(description: "baz")

        Container.$shared.withValue(container) {
            Container.shared.fooBarBaz.register { Baz() }

            let sut = TaskLocalUseCase()
            XCTAssertEqual(sut.fooBarBaz.value, "baz")
            bazExpectation.fulfill()
        }

        wait(for: [fooExpectation, barExpectation, bazExpectation], timeout: 60)
    }

    // Illustrates using the withContainer() helper with a synchronous transform closure
    func testFooBarBazWithContainer() {
        let fooExpectation = expectation(description: "foo")

        FactoryTestingHelper.withContainer() {
            let sut = TaskLocalUseCase()
            XCTAssertEqual(sut.fooBarBaz.value, "foo")
            fooExpectation.fulfill()
        } transform: {
            $0.fooBarBaz.register { Foo() }
        }

        let barExpectation = expectation(description: "bar")

        FactoryTestingHelper.withContainer {
            let sut = TaskLocalUseCase()
            XCTAssertEqual(sut.fooBarBaz.value, "bar")
            barExpectation.fulfill()
        } transform: {
            $0.fooBarBaz.register { Bar() }
        }

        let bazExpectation = expectation(description: "baz")

        FactoryTestingHelper.withContainer {
            let sut = TaskLocalUseCase()
            XCTAssertEqual(sut.fooBarBaz.value, "baz")
            bazExpectation.fulfill()
        } transform: {
            $0.fooBarBaz.register { Baz() }
        }

        wait(for: [fooExpectation, barExpectation, bazExpectation], timeout: 60)
    }

    // Illustrates using the withContainer() helper with an asynchronous transform closure
    func testFooBarBazWithContainerAsync() async {
        let fooExpectation = expectation(description: "foo")

        await FactoryTestingHelper.withContainer() {
            let sut = await IsolatedTaskLocalUseCase()
            let value = await sut.isolatedToMainActor.value
            XCTAssertEqual(value, "foo")
            fooExpectation.fulfill()
        } transform: {
            await $0.isolatedToMainActor.register { @MainActor in MainActorFooBarBaz(value: "foo") }
        }

        let barExpectation = expectation(description: "bar")

        await FactoryTestingHelper.withContainer {
            let sut = await IsolatedTaskLocalUseCase()
            let value = await sut.isolatedToMainActor.value
            XCTAssertEqual(value, "bar")
            barExpectation.fulfill()
        } transform: {
            await $0.isolatedToMainActor.register { @MainActor in MainActorFooBarBaz(value: "bar") }
        }

        let bazExpectation = expectation(description: "baz")

        await FactoryTestingHelper.withContainer {
            let sut = await IsolatedTaskLocalUseCase()
            let value = await sut.isolatedToMainActor.value
            XCTAssertEqual(value, "baz")
            bazExpectation.fulfill()
        } transform: {
            await $0.isolatedToMainActor.register { @MainActor in MainActorFooBarBaz(value: "baz") }
        }

        await fulfillment(of: [fooExpectation, barExpectation, bazExpectation], timeout: 60)
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
