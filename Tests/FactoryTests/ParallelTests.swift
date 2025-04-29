#if swift(>=5.5)

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
    }

}
#endif
