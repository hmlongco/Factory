@testable import Factory
import Testing

@Suite
struct ParallelTests {
    @Test(.container)
    func foo() {
        let sut = SomeUseCase()

        Container.shared.fooOrBar.register {
            Foo()
        }

        let result = sut.execute()
        #expect(result == "foo")
    }

    @Test(.container)
    func bar() {
        let sut = SomeUseCase()

        Container.shared.fooOrBar.register {
            Bar()
        }

        let result = sut.execute()
        #expect(result == "bar")
    }
}

fileprivate protocol FooOrBarProtocol {
    var value: String { get set }
}

fileprivate struct Foo: FooOrBarProtocol {
    var value = "foo"
}

fileprivate struct Bar: FooOrBarProtocol {
    var value = "bar"
}

fileprivate extension Container {
    var fooOrBar: Factory<FooOrBarProtocol> {
        self { Foo() }
    }
}

fileprivate final class SomeUseCase {
    fileprivate func execute() -> String {
        @Injected(\.fooOrBar) var fooOrBar: FooOrBarProtocol

        return fooOrBar.value
    }
}
