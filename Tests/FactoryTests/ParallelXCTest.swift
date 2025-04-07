import XCTest
@testable import Factory

final class ParallelXCTest: XCTestCase {
    func testFooBarBaz() {
        let container = Container()
        let fooExpectation = expectation(description: "foo")

        Container.$shared.withValue(container) {
            let sut = SomeUseCase()

            Container.shared.fooBarBaz.register {
                Foo()
            }

            let result = sut.execute()
            XCTAssertEqual(result, "foo")
            fooExpectation.fulfill()
        }

        let barExpectation = expectation(description: "bar")

        Container.$shared.withValue(container) {
            let sut = SomeUseCase()

            Container.shared.fooBarBaz.register {
                Bar()
            }

            let result = sut.execute()
            XCTAssertEqual(result, "bar")
            barExpectation.fulfill()
        }

        let bazExpectation = expectation(description: "baz")

        Container.$shared.withValue(container) {
            let sut = SomeUseCase()

            Container.shared.fooBarBaz.register {
                Baz()
            }

            let result = sut.execute()
            XCTAssertEqual(result, "baz")
            bazExpectation.fulfill()
        }

        wait(for: [fooExpectation, barExpectation, bazExpectation], timeout: 60)
    }
}

//TODO: use MockServices.swift provided types instead of these
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
