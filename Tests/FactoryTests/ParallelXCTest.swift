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
