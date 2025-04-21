#if swift(>=6.1)

import XCTest
@testable import Factory

final class ParallelXCTest: XCTestCase {
    func testFooBarBaz() {
        let container = Container()
        let fooExpectation = expectation(description: "foo")

        Container.$shared.withValue(container) {
            Container.shared.fooBarBaz.register { Foo() }

            let sut = TaskLocalUseCase()
            XCTAssertEqual(sut.fooBarBaz.value, "foo")
            fooExpectation.fulfill()
        }

        let barExpectation = expectation(description: "bar")

        Container.$shared.withValue(container) {
            Container.shared.fooBarBaz.register { Bar() }

            let sut = TaskLocalUseCase()
            XCTAssertEqual(sut.fooBarBaz.value, "bar")
            barExpectation.fulfill()
        }

        let bazExpectation = expectation(description: "baz")

        Container.$shared.withValue(container) {
            Container.shared.fooBarBaz.register { Baz() }

            let sut = TaskLocalUseCase()
            XCTAssertEqual(sut.fooBarBaz.value, "baz")
            bazExpectation.fulfill()
        }

        wait(for: [fooExpectation, barExpectation, bazExpectation], timeout: 60)
    }
}
#endif
