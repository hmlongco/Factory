#if swift(>=6.1)

@testable import Factory
import Testing

@Suite
struct ParallelTests {
    @Test(.container(resetSingletonScope: false))
    func foo() {
        let sut = SomeUseCase()

        Container.shared.fooBarBaz.register {
            Foo()
        }

        let result = sut.execute()
        #expect(result == "foo")
    }

    @Test(.container(resetSingletonScope: false))
    func bar() {
        let sut = SomeUseCase()

        Container.shared.fooBarBaz.register {
            Bar()
        }

        let result = sut.execute()
        #expect(result == "bar")
    }

    @Test(.container(resetSingletonScope: false))
    func baz() {
        let sut = SomeUseCase()

        Container.shared.fooBarBaz.register {
            Baz()
        }

        let result = sut.execute()
        #expect(result == "baz")
    }

    @Test(.container())
    func fooSingleton() {
        let sut = SomeUseCase()

        Container.shared.fooBarBazSingleton.register {
            Foo()
        }

        let result = sut.executeSingleton()
        #expect(result == "foo")
    }

    @Test(.container())
    func barSingleton() {
        let sut = SomeUseCase()

        Container.shared.fooBarBazSingleton.register {
            Bar()
        }

        let result = sut.executeSingleton()
        #expect(result == "bar")
    }

    @Test(.container())
    func bazSingleton() {
        let sut = SomeUseCase()

        Container.shared.fooBarBazSingleton.register {
            Baz()
        }

        let result = sut.executeSingleton()
        #expect(result == "baz")
    }
}
#endif
