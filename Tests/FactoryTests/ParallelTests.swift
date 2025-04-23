#if swift(>=6.1)

@testable import Factory
import Testing

@Suite
struct ParallelTests {
    // Illustrates using Container test trait directly
    @Test(Container.taskLocalTestTrait)
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

    // Illustrates using autocomplete test trait
    @Test(.container)
    func bar() {
        Container.shared.fooBarBaz.register { Bar() }
        Container.shared.fooBarBazCached.register { Bar() }
        Container.shared.fooBarBazSingleton.register { Bar() }

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

    // Illustrates using autocomplete test trait with modifications
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

    // Illustrates using autocomplete test trait with modifications on isolated registrations
    @MainActor
    @Test(await .isolatedContainer {
        $0.isolatedFooBarBaz.register { IsolatedBaz() }
        $0.isolatedFooBarBazCached.register { IsolatedBaz() }
        $0.isolatedFooBarBazSingleton.register { IsolatedBaz() }
    })
    func isolatedBaz() async {
        let sut1 = IsolatedTaskLocalUseCase()
        #expect(sut1.isolatedFooBarBaz.value == "baz")
        #expect(sut1.isolatedFooBarBazCached.value == "baz")
        #expect(sut1.isolatedFooBarBazSingleton.value == "baz")

        let sut2 = IsolatedTaskLocalUseCase()
        #expect(sut2.isolatedFooBarBaz.value == "baz")
        #expect(sut2.isolatedFooBarBazCached.value == "baz")
        #expect(sut2.isolatedFooBarBazSingleton.value == "baz")

        #expect(sut1.isolatedFooBarBaz.id != sut2.isolatedFooBarBaz.id)
        #expect(sut1.isolatedFooBarBazCached.id == sut2.isolatedFooBarBazCached.id)
        #expect(sut1.isolatedFooBarBazSingleton.id == sut2.isolatedFooBarBazSingleton.id)

        Container.shared.isolatedFooBarBazSingleton.register { IsolatedFoo() }

        let sut3 = IsolatedTaskLocalUseCase()
        #expect(sut3.isolatedFooBarBazSingleton.value == "foo")
        #expect(sut1.isolatedFooBarBazSingleton.id != sut3.isolatedFooBarBazSingleton.id)
    }
}
#endif
