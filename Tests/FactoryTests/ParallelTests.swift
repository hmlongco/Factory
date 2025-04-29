#if swift(>=6.1)

@testable import Factory
import Testing

@Suite
struct ParallelTests {

    @Suite
    struct ParallelTraitTests {
        // Illustrates using container test trait
        @Test(.container)
        func foo() {
            let sut1 = TaskLocalUseCase()
            #expect(sut1.fooBarBaz.value == "foo")
            #expect(sut1.fooBarBazCached.value == "foo")
            #expect(sut1.fooBarBazSingleton.value == "foo")

            let sut2 = TaskLocalUseCase()
            #expect(sut2.fooBarBaz.value == "foo")
            #expect(sut2.fooBarBazCached.value == "foo")
            #expect(sut2.fooBarBazSingleton.value == "foo")

            #expect(sut1.fooBarBaz.id != sut2.fooBarBaz.id)
            #expect(sut1.fooBarBazCached.id == sut2.fooBarBazCached.id)
            #expect(sut1.fooBarBazSingleton.id == sut2.fooBarBazSingleton.id)

            Container.shared.fooBarBazSingleton.register { Bar() }

            let sut3 = TaskLocalUseCase()
            #expect(sut3.fooBarBazSingleton.value == "bar")
            #expect(sut1.fooBarBazSingleton.id != sut3.fooBarBazSingleton.id)
        }

        // Illustrates using container test trait
        @Test(.container)
        func bar() {
            let c = Container.shared
            c.fooBarBaz.register { Bar() }
            c.fooBarBazCached.register { Bar() }
            c.fooBarBazSingleton.register { Bar() }

            let sut1 = TaskLocalUseCase()
            #expect(sut1.fooBarBaz.value == "bar")
            #expect(sut1.fooBarBazCached.value == "bar")
            #expect(sut1.fooBarBazSingleton.value == "bar")

            let sut2 = TaskLocalUseCase()
            #expect(sut2.fooBarBaz.value == "bar")
            #expect(sut2.fooBarBazCached.value == "bar")
            #expect(sut2.fooBarBazSingleton.value == "bar")

            #expect(sut1.fooBarBaz.id != sut2.fooBarBaz.id)
            #expect(sut1.fooBarBazCached.id == sut2.fooBarBazCached.id)
            #expect(sut1.fooBarBazSingleton.id == sut2.fooBarBazSingleton.id)

            c.fooBarBazSingleton.register { Foo() }

            let sut3 = TaskLocalUseCase()
            #expect(sut3.fooBarBazSingleton.value == "foo")
            #expect(sut1.fooBarBazSingleton.id != sut3.fooBarBazSingleton.id)
        }

        // Illustrates using container test trait with support closure
        @Test(.container {
            $0.fooBarBaz.register { Baz() }
            $0.fooBarBazCached.register { Baz() }
            $0.fooBarBazSingleton.register { Baz() }
        })
        func baz() {
            let sut1 = TaskLocalUseCase()
            #expect(sut1.fooBarBaz.value == "baz")
            #expect(sut1.fooBarBazCached.value == "baz")
            #expect(sut1.fooBarBazSingleton.value == "baz")

            let sut2 = TaskLocalUseCase()
            #expect(sut2.fooBarBaz.value == "baz")
            #expect(sut2.fooBarBazCached.value == "baz")
            #expect(sut2.fooBarBazSingleton.value == "baz")

            #expect(sut1.fooBarBaz.id != sut2.fooBarBaz.id)
            #expect(sut1.fooBarBazCached.id == sut2.fooBarBazCached.id)
            #expect(sut1.fooBarBazSingleton.id == sut2.fooBarBazSingleton.id)

            Container.shared.fooBarBazSingleton.register { Foo() }

            let sut3 = TaskLocalUseCase()
            #expect(sut3.fooBarBazSingleton.value == "foo")
            #expect(sut1.fooBarBazSingleton.id != sut3.fooBarBazSingleton.id)
        }
    }

    @Suite(.container)
    struct ParallelSuiteTests {
        @Test
        func foo() {
            Container.shared.with {
                $0.fooBarBaz.register { Foo() }
                $0.fooBarBazCached.register { Foo() }
                $0.fooBarBazSingleton.register { Foo() }
            }

            let sut1 = TaskLocalUseCase()
            #expect(sut1.fooBarBaz.value == "foo")
            #expect(sut1.fooBarBazCached.value == "foo")
            #expect(sut1.fooBarBazSingleton.value == "foo")

            let sut2 = TaskLocalUseCase()
            #expect(sut2.fooBarBaz.value == "foo")
            #expect(sut2.fooBarBazCached.value == "foo")
            #expect(sut2.fooBarBazSingleton.value == "foo")

            #expect(sut1.fooBarBaz.id != sut2.fooBarBaz.id)
            #expect(sut1.fooBarBazCached.id == sut2.fooBarBazCached.id)
            #expect(sut1.fooBarBazSingleton.id == sut2.fooBarBazSingleton.id)

            Container.shared.fooBarBazSingleton.register { Bar() }

            let sut3 = TaskLocalUseCase()
            #expect(sut3.fooBarBazSingleton.value == "bar")
            #expect(sut1.fooBarBazSingleton.id != sut3.fooBarBazSingleton.id)
        }

        @Test
        func bar() {
            Container.shared.with {
                $0.fooBarBaz.register { Bar() }
                $0.fooBarBazCached.register { Bar() }
                $0.fooBarBazSingleton.register { Bar() }
            }

            let sut1 = TaskLocalUseCase()
            #expect(sut1.fooBarBaz.value == "bar")
            #expect(sut1.fooBarBazCached.value == "bar")
            #expect(sut1.fooBarBazSingleton.value == "bar")

            let sut2 = TaskLocalUseCase()
            #expect(sut2.fooBarBaz.value == "bar")
            #expect(sut2.fooBarBazCached.value == "bar")
            #expect(sut2.fooBarBazSingleton.value == "bar")

            #expect(sut1.fooBarBaz.id != sut2.fooBarBaz.id)
            #expect(sut1.fooBarBazCached.id == sut2.fooBarBazCached.id)
            #expect(sut1.fooBarBazSingleton.id == sut2.fooBarBazSingleton.id)

            Container.shared.fooBarBazSingleton.register { Foo() }

            let sut3 = TaskLocalUseCase()
            #expect(sut3.fooBarBazSingleton.value == "foo")
            #expect(sut1.fooBarBazSingleton.id != sut3.fooBarBazSingleton.id)
        }

        @Test
        func baz() {
            Container.shared.with {
                $0.fooBarBaz.register { Baz() }
                $0.fooBarBazCached.register { Baz() }
                $0.fooBarBazSingleton.register { Baz() }
            }

            let sut1 = TaskLocalUseCase()
            #expect(sut1.fooBarBaz.value == "baz")
            #expect(sut1.fooBarBazCached.value == "baz")
            #expect(sut1.fooBarBazSingleton.value == "baz")

            let sut2 = TaskLocalUseCase()
            #expect(sut2.fooBarBaz.value == "baz")
            #expect(sut2.fooBarBazCached.value == "baz")
            #expect(sut2.fooBarBazSingleton.value == "baz")

            #expect(sut1.fooBarBaz.id != sut2.fooBarBaz.id)
            #expect(sut1.fooBarBazCached.id == sut2.fooBarBazCached.id)
            #expect(sut1.fooBarBazSingleton.id == sut2.fooBarBazSingleton.id)

            Container.shared.fooBarBazSingleton.register { Bar() }

            let sut3 = TaskLocalUseCase()
            #expect(sut3.fooBarBazSingleton.value == "bar")
            #expect(sut1.fooBarBazSingleton.id != sut3.fooBarBazSingleton.id)
        }

        // Illustrates using the container test trait with different isolations
        @MainActor
        @Suite
        struct ParallelIsolatedTests {
            @Test(.container {
                $0.fooBarBaz.register { Foo() }
                $0.fooBarBazCached.register { Foo() }
                $0.fooBarBazSingleton.register { Foo() }

                await $0.isolatedToMainActor.register { ObservableFooBarBaz(value: "foo") }
                await $0.isolatedToMainActorCached.register { ObservableFooBarBaz(value: "foo") }
                await $0.isolatedToMainActorSingleton.register { ObservableFooBarBaz(value: "foo") }

                await $0.isolatedToCustomGlobalActor.register { IsolatedFoo() }
                await $0.isolatedToCustomGlobalActorCached.register { IsolatedFoo() }
                await $0.isolatedToCustomGlobalActorSingleton.register { IsolatedFoo() }
            })
            func isolatedFoo() async {
                let sut1 = await IsolatedTaskLocalUseCase()
                #expect(sut1.fooBarBaz.value == "foo")
                #expect(sut1.fooBarBazCached.value == "foo")
                #expect(sut1.fooBarBazSingleton.value == "foo")

                #expect(sut1.isolatedToMainActor.value == "foo")
                #expect(sut1.isolatedToMainActorCached.value == "foo")
                #expect(sut1.isolatedToMainActorSingleton.value == "foo")

                #expect(sut1.isolatedToCustomGlobalActor.value == "foo")
                #expect(sut1.isolatedToCustomGlobalActorCached.value == "foo")
                #expect(sut1.isolatedToCustomGlobalActorSingleton.value == "foo")

                let sut2 = await IsolatedTaskLocalUseCase()
                #expect(sut2.fooBarBaz.value == "foo")
                #expect(sut2.fooBarBazCached.value == "foo")
                #expect(sut2.fooBarBazSingleton.value == "foo")

                #expect(sut2.isolatedToMainActor.value == "foo")
                #expect(sut2.isolatedToMainActorCached.value == "foo")
                #expect(sut2.isolatedToMainActorSingleton.value == "foo")

                #expect(sut2.isolatedToCustomGlobalActor.value == "foo")
                #expect(sut2.isolatedToCustomGlobalActorCached.value == "foo")
                #expect(sut2.isolatedToCustomGlobalActorSingleton.value == "foo")

                #expect(sut1.fooBarBaz.id != sut2.fooBarBaz.id)
                #expect(sut1.fooBarBazCached.id == sut2.fooBarBazCached.id)
                #expect(sut1.fooBarBazSingleton.id == sut2.fooBarBazSingleton.id)

                #expect(sut1.isolatedToMainActor.id != sut2.isolatedToMainActor.id)
                #expect(sut1.isolatedToMainActorCached.id == sut2.isolatedToMainActorCached.id)
                #expect(sut1.isolatedToMainActorSingleton.id == sut2.isolatedToMainActorSingleton.id)

                #expect(sut1.isolatedToCustomGlobalActor.id != sut2.isolatedToCustomGlobalActor.id)
                #expect(sut1.isolatedToCustomGlobalActorCached.id == sut2.isolatedToCustomGlobalActorCached.id)
                #expect(sut1.isolatedToCustomGlobalActorSingleton.id == sut2.isolatedToCustomGlobalActorSingleton.id)

                Container.shared.fooBarBazSingleton.register { Bar() }
                Container.shared.isolatedToMainActorSingleton.register { ObservableFooBarBaz(value: "bar") }
                await Container.shared.isolatedToCustomGlobalActorSingleton.register { IsolatedBar() }

                let sut3 = await IsolatedTaskLocalUseCase()
                #expect(sut3.fooBarBazSingleton.value == "bar")
                #expect(sut3.isolatedToMainActorSingleton.value == "bar")
                #expect(sut3.isolatedToCustomGlobalActorSingleton.value == "bar")

                #expect(sut1.fooBarBazSingleton.id != sut3.fooBarBazSingleton.id)
                #expect(sut1.isolatedToMainActorSingleton.id != sut3.isolatedToMainActorSingleton.id)
                #expect(sut1.isolatedToCustomGlobalActorSingleton.id != sut3.isolatedToCustomGlobalActorSingleton.id)
            }

            @Test(.container {
                $0.fooBarBaz.register { Bar() }
                $0.fooBarBazCached.register { Bar() }
                $0.fooBarBazSingleton.register { Bar() }

                await $0.isolatedToMainActor.register { ObservableFooBarBaz(value: "bar") }
                await $0.isolatedToMainActorCached.register { ObservableFooBarBaz(value: "bar") }
                await $0.isolatedToMainActorSingleton.register { ObservableFooBarBaz(value: "bar") }

                await $0.isolatedToCustomGlobalActor.register { IsolatedBar() }
                await $0.isolatedToCustomGlobalActorCached.register { IsolatedBar() }
                await $0.isolatedToCustomGlobalActorSingleton.register { IsolatedBar() }
            })
            func isolatedBar() async {
                let sut1 = await IsolatedTaskLocalUseCase()
                #expect(sut1.fooBarBaz.value == "bar")
                #expect(sut1.fooBarBazCached.value == "bar")
                #expect(sut1.fooBarBazSingleton.value == "bar")

                #expect(sut1.isolatedToMainActor.value == "bar")
                #expect(sut1.isolatedToMainActorCached.value == "bar")
                #expect(sut1.isolatedToMainActorSingleton.value == "bar")

                #expect(sut1.isolatedToCustomGlobalActor.value == "bar")
                #expect(sut1.isolatedToCustomGlobalActorCached.value == "bar")
                #expect(sut1.isolatedToCustomGlobalActorSingleton.value == "bar")

                let sut2 = await IsolatedTaskLocalUseCase()
                #expect(sut2.fooBarBaz.value == "bar")
                #expect(sut2.fooBarBazCached.value == "bar")
                #expect(sut2.fooBarBazSingleton.value == "bar")

                #expect(sut2.isolatedToMainActor.value == "bar")
                #expect(sut2.isolatedToMainActorCached.value == "bar")
                #expect(sut2.isolatedToMainActorSingleton.value == "bar")

                #expect(sut2.isolatedToCustomGlobalActor.value == "bar")
                #expect(sut2.isolatedToCustomGlobalActorCached.value == "bar")
                #expect(sut2.isolatedToCustomGlobalActorSingleton.value == "bar")

                #expect(sut1.fooBarBaz.id != sut2.fooBarBaz.id)
                #expect(sut1.fooBarBazCached.id == sut2.fooBarBazCached.id)
                #expect(sut1.fooBarBazSingleton.id == sut2.fooBarBazSingleton.id)

                #expect(sut1.isolatedToMainActor.id != sut2.isolatedToMainActor.id)
                #expect(sut1.isolatedToMainActorCached.id == sut2.isolatedToMainActorCached.id)
                #expect(sut1.isolatedToMainActorSingleton.id == sut2.isolatedToMainActorSingleton.id)

                #expect(sut1.isolatedToCustomGlobalActor.id != sut2.isolatedToCustomGlobalActor.id)
                #expect(sut1.isolatedToCustomGlobalActorCached.id == sut2.isolatedToCustomGlobalActorCached.id)
                #expect(sut1.isolatedToCustomGlobalActorSingleton.id == sut2.isolatedToCustomGlobalActorSingleton.id)

                Container.shared.fooBarBazSingleton.register { Baz() }
                Container.shared.isolatedToMainActorSingleton.register { ObservableFooBarBaz(value: "baz") }
                await Container.shared.isolatedToCustomGlobalActorSingleton.register { IsolatedBaz() }

                let sut3 = await IsolatedTaskLocalUseCase()
                #expect(sut3.fooBarBazSingleton.value == "baz")
                #expect(sut3.isolatedToMainActorSingleton.value == "baz")
                #expect(sut3.isolatedToCustomGlobalActorSingleton.value == "baz")

                #expect(sut1.fooBarBazSingleton.id != sut3.fooBarBazSingleton.id)
                #expect(sut1.isolatedToMainActorSingleton.id != sut3.isolatedToMainActorSingleton.id)
                #expect(sut1.isolatedToCustomGlobalActorSingleton.id != sut3.isolatedToCustomGlobalActorSingleton.id)
            }

            @Test(.container {
                $0.fooBarBaz.register { Baz() }
                $0.fooBarBazCached.register { Baz() }
                $0.fooBarBazSingleton.register { Baz() }

                await $0.isolatedToMainActor.register { ObservableFooBarBaz(value: "baz") }
                await $0.isolatedToMainActorCached.register { ObservableFooBarBaz(value: "baz") }
                await $0.isolatedToMainActorSingleton.register { ObservableFooBarBaz(value: "baz") }

                await $0.isolatedToCustomGlobalActor.register { IsolatedBaz() }
                await $0.isolatedToCustomGlobalActorCached.register { IsolatedBaz() }
                await $0.isolatedToCustomGlobalActorSingleton.register { IsolatedBaz() }
            })
            func isolatedBaz() async {
                let sut1 = await IsolatedTaskLocalUseCase()
                #expect(sut1.fooBarBaz.value == "baz")
                #expect(sut1.fooBarBazCached.value == "baz")
                #expect(sut1.fooBarBazSingleton.value == "baz")

                #expect(sut1.isolatedToMainActor.value == "baz")
                #expect(sut1.isolatedToMainActorCached.value == "baz")
                #expect(sut1.isolatedToMainActorSingleton.value == "baz")

                #expect(sut1.isolatedToCustomGlobalActor.value == "baz")
                #expect(sut1.isolatedToCustomGlobalActorCached.value == "baz")
                #expect(sut1.isolatedToCustomGlobalActorSingleton.value == "baz")

                let sut2 = await IsolatedTaskLocalUseCase()
                #expect(sut2.fooBarBaz.value == "baz")
                #expect(sut2.fooBarBazCached.value == "baz")
                #expect(sut2.fooBarBazSingleton.value == "baz")

                #expect(sut2.isolatedToMainActor.value == "baz")
                #expect(sut2.isolatedToMainActorCached.value == "baz")
                #expect(sut2.isolatedToMainActorSingleton.value == "baz")

                #expect(sut2.isolatedToCustomGlobalActor.value == "baz")
                #expect(sut2.isolatedToCustomGlobalActorCached.value == "baz")
                #expect(sut2.isolatedToCustomGlobalActorSingleton.value == "baz")

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
                Container.shared.isolatedToMainActorSingleton.register { ObservableFooBarBaz(value: "foo") }
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
}
#endif
