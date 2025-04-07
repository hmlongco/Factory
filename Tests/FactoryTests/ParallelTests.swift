@testable import Factory
import Testing

@Suite
struct ParallelTests {
    @Test(.container)
    func foo() {
        let sut = SomeUseCase()

        Container.shared.fooBarBaz.register {
            Foo()
        }

        let result = sut.execute()
        #expect(result == "foo")
    }

    @Test(.container)
    func bar() {
        let sut = SomeUseCase()

        Container.shared.fooBarBaz.register {
            Bar()
        }

        let result = sut.execute()
        #expect(result == "bar")
    }

    @Test(.container)
    func baz() {
        let sut = SomeUseCase()

        Container.shared.fooBarBaz.register {
            Baz()
        }

        let result = sut.execute()
        #expect(result == "baz")
    }
}

fileprivate protocol FooBarBazProtocol {
    var value: String { get set }
}

fileprivate struct Foo: FooBarBazProtocol {
    var value = "foo"
}

fileprivate struct Bar: FooBarBazProtocol {
    var value = "bar"
}

fileprivate struct Baz: FooBarBazProtocol {
    var value = "baz"
}

fileprivate extension Container {
    var fooBarBaz: Factory<FooBarBazProtocol> {
        self { Foo() }
    }
}

fileprivate final class SomeUseCase {
    fileprivate func execute() -> String {
        @Injected(\.fooBarBaz) var fooBarBaz: FooBarBazProtocol

        return fooBarBaz.value
    }
}
