#if swift(>=6.1)

@testable import Factory
import Testing

@Suite
struct ParallelTests {
    @Test(.container())
    func foo() {
        let sut = SomeUseCase()

        Container.shared.fooBarBaz.register {
            Foo()
        }

        let result = sut.execute()
        #expect(result == "foo")
    }

    @Test(.container())
    func bar() {
        let sut = SomeUseCase()

        Container.shared.fooBarBaz.register {
            Bar()
        }

        let result = sut.execute()
        #expect(result == "bar")
    }

    @Test(.container())
    func baz() {
        let sut = SomeUseCase()

        Container.shared.fooBarBaz.register {
            Baz()
        }

        let result = sut.execute()
        #expect(result == "baz")
    }
}
#endif
