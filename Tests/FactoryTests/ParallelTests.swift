#if swift(>=5.5)

@testable import Factory
import FactoryTesting
import Testing

@Suite
struct ParallelTests {

    @Suite
    struct ParallelTraitTests {
        // Illustrates using container test trait
        @Test(.container)
        func foo() {
            commonTests("foo")
        }

        // Illustrates using container test trait
        @Test(.container)
        func bar() {
            let c = Container.shared
            c.fooBarBaz.register { Bar() }
            c.fooBarBazCached.register { Bar() }
            c.fooBarBazSingleton.register { Bar() }

            commonTests("bar")
        }

        // Illustrates using container test trait with support closure
        @Test(.container {
            $0.fooBarBaz.register { Baz() }
            $0.fooBarBazCached.register { Baz() }
            $0.fooBarBazSingleton.register { Baz() }
        })
        func baz() {
            commonTests("baz")
        }

        func commonTests(_ value: String) {
            let sut1 = TaskLocalUseCase()
            #expect(sut1.fooBarBaz.value == value)
            #expect(sut1.fooBarBazCached.value == value)
            #expect(sut1.fooBarBazSingleton.value == value)

            let sut2 = TaskLocalUseCase()
            #expect(sut2.fooBarBaz.value == value)
            #expect(sut2.fooBarBazCached.value == value)
            #expect(sut2.fooBarBazSingleton.value == value)

            #expect(sut1.fooBarBaz.id != sut2.fooBarBaz.id)
            #expect(sut1.fooBarBazCached.id == sut2.fooBarBazCached.id)
            #expect(sut1.fooBarBazSingleton.id == sut2.fooBarBazSingleton.id)

            Container.shared.fooBarBazSingleton.register { Foo() }

            let sut3 = TaskLocalUseCase()
            #expect(sut3.fooBarBazSingleton.value == "foo")
            #expect(sut1.fooBarBazSingleton.id != sut3.fooBarBazSingleton.id)
        }

    }

    @Suite(.container {
        $0.fooBarBaz.register { Foo() }
        $0.fooBarBazCached.register { Foo() }
        $0.fooBarBazSingleton.register { Foo() }
    })
    struct ParallelSuiteTests {
        @Test
        func foo() {
            commonSuiteTests("foo")
        }

        @Test
        func bar() {
            // will reregister services
            Container.shared.with {
                $0.fooBarBaz.register { Bar() }
                $0.fooBarBazCached.register { Bar() }
                $0.fooBarBazSingleton.register { Bar() }
            }

            commonSuiteTests("bar")
        }

        @Test
        func baz() {
            // will reregister services
            Container.shared.with {
                $0.fooBarBaz.register { Baz() }
                $0.fooBarBazCached.register { Baz() }
                $0.fooBarBazSingleton.register { Baz() }
            }

            commonSuiteTests("baz")
        }

        func commonSuiteTests(_ value: String) {
            let sut1 = TaskLocalUseCase()
            #expect(sut1.fooBarBaz.value == value)
            #expect(sut1.fooBarBazCached.value == value)
            #expect(sut1.fooBarBazSingleton.value == value)

            let sut2 = TaskLocalUseCase()
            #expect(sut2.fooBarBaz.value == value)
            #expect(sut2.fooBarBazCached.value == value)
            #expect(sut2.fooBarBazSingleton.value == value)

            #expect(sut1.fooBarBaz.id != sut2.fooBarBaz.id)
            #expect(sut1.fooBarBazCached.id == sut2.fooBarBazCached.id)
            #expect(sut1.fooBarBazSingleton.id == sut2.fooBarBazSingleton.id)

            Container.shared.fooBarBazSingleton.register { Foo() }

            let sut3 = TaskLocalUseCase()
            #expect(sut3.fooBarBazSingleton.value == "foo")
            #expect(sut1.fooBarBazSingleton.id != sut3.fooBarBazSingleton.id)
        }

    }

    @MainActor
    @Suite
    struct ParallelIsolatedTests {

        // Illustrates using the container test trait with different isolations
        @Test(.container {
            $0.fooBarBaz.register { Foo() }
            $0.fooBarBazCached.register { Foo() }
            $0.fooBarBazSingleton.register { Foo() }

            await $0.isolatedToMainActor.register { @MainActor in MainActorFooBarBaz(value: "foo") }
            await $0.isolatedToMainActorCached.register { @MainActor in MainActorFooBarBaz(value: "foo") }
            await $0.isolatedToMainActorSingleton.register { @MainActor in MainActorFooBarBaz(value: "foo") }

            await $0.isolatedToCustomGlobalActor.register { IsolatedFoo() }
            await $0.isolatedToCustomGlobalActorCached.register { IsolatedFoo() }
            await $0.isolatedToCustomGlobalActorSingleton.register { IsolatedFoo() }
        })
        func isolatedFoo() async {
            await isolatedAsyncTests("foo")
        }

        // Illustrates using the container test trait with different isolations
        @Test(.container {
            $0.fooBarBaz.register { Bar() }
            $0.fooBarBazCached.register { Bar() }
            $0.fooBarBazSingleton.register { Bar() }

            await $0.isolatedToMainActor.register { @MainActor in MainActorFooBarBaz(value: "bar") }
            await $0.isolatedToMainActorCached.register { @MainActor in MainActorFooBarBaz(value: "bar") }
            await $0.isolatedToMainActorSingleton.register { @MainActor in MainActorFooBarBaz(value: "bar") }

            await $0.isolatedToCustomGlobalActor.register { IsolatedBar() }
            await $0.isolatedToCustomGlobalActorCached.register { IsolatedBar() }
            await $0.isolatedToCustomGlobalActorSingleton.register { IsolatedBar() }
        })
        func isolatedBar() async {
            await isolatedAsyncTests("bar")
        }

        // Illustrates using the container with function with different isolations
        @MainActor
        @Test(.container)
        func isolatedBaz() async {
            await Container.shared.with {
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
            await isolatedAsyncTests("baz")
        }

        func isolatedAsyncTests(_ value: String) async {
            let sut1 = await IsolatedTaskLocalUseCase()
            #expect(sut1.fooBarBaz.value == value)
            #expect(sut1.fooBarBazCached.value == value)
            #expect(sut1.fooBarBazSingleton.value == value)

            #expect(sut1.isolatedToMainActor.value == value)
            #expect(sut1.isolatedToMainActorCached.value == value)
            #expect(sut1.isolatedToMainActorSingleton.value == value)

            #expect(sut1.isolatedToCustomGlobalActor.value == value)
            #expect(sut1.isolatedToCustomGlobalActorCached.value == value)
            #expect(sut1.isolatedToCustomGlobalActorSingleton.value == value)

            let sut2 = await IsolatedTaskLocalUseCase()
            #expect(sut2.fooBarBaz.value == value)
            #expect(sut2.fooBarBazCached.value == value)
            #expect(sut2.fooBarBazSingleton.value == value)

            #expect(sut2.isolatedToMainActor.value == value)
            #expect(sut2.isolatedToMainActorCached.value == value)
            #expect(sut2.isolatedToMainActorSingleton.value == value)

            #expect(sut2.isolatedToCustomGlobalActor.value == value)
            #expect(sut2.isolatedToCustomGlobalActorCached.value == value)
            #expect(sut2.isolatedToCustomGlobalActorSingleton.value == value)

            #expect(sut1.fooBarBaz.id != sut2.fooBarBaz.id)
            #expect(sut1.fooBarBazCached.id == sut2.fooBarBazCached.id)
            #expect(sut1.fooBarBazSingleton.id == sut2.fooBarBazSingleton.id)

            #expect(sut1.isolatedToMainActor.id != sut2.isolatedToMainActor.id)
            #expect(sut1.isolatedToMainActorCached.id == sut2.isolatedToMainActorCached.id)
            #expect(sut1.isolatedToMainActorSingleton.id == sut2.isolatedToMainActorSingleton.id)

            #expect(sut1.isolatedToCustomGlobalActor.id != sut2.isolatedToCustomGlobalActor.id)
            #expect(sut1.isolatedToCustomGlobalActorCached.id == sut2.isolatedToCustomGlobalActorCached.id)
            #expect(sut1.isolatedToCustomGlobalActorSingleton.id == sut2.isolatedToCustomGlobalActorSingleton.id)

            Container.shared.fooBarBazSingleton.register { Foo() }
            Container.shared.isolatedToMainActorSingleton.register { @MainActor in  MainActorFooBarBaz(value: "foo") }
            await Container.shared.isolatedToCustomGlobalActorSingleton.register { IsolatedFoo() }

            let sut3 = await IsolatedTaskLocalUseCase()
            #expect(sut3.fooBarBazSingleton.value == "foo")
            #expect(sut3.isolatedToMainActorSingleton.value == "foo")
            #expect(sut3.isolatedToCustomGlobalActorSingleton.value == "foo")

            #expect(sut1.fooBarBazSingleton.id != sut3.fooBarBazSingleton.id)
            #expect(sut1.isolatedToMainActorSingleton.id != sut3.isolatedToMainActorSingleton.id)
            #expect(sut1.isolatedToCustomGlobalActorSingleton.id != sut3.isolatedToCustomGlobalActorSingleton.id)
        }
    }
}

#endif
