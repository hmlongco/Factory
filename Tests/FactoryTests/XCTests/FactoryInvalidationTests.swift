import XCTest
@testable import FactoryKit

final class FactoryInvalidationTests: XCTestCase {
    func testRegistrationDiscardsInFlightCachedValue() {
        assertInvalidation(scope: Scope.Cached(), expected: 100) { _, factory in
            factory.register { 100 }
        }
    }

    func testRegistrationDiscardsInFlightSingletonValue() {
        assertInvalidation(scope: Scope.Singleton(), expected: 100) { _, factory in
            factory.register { 100 }
        }
    }

    func testFactoryResetDiscardsInFlightValue() {
        assertInvalidation(scope: Scope.Cached(), expected: 2) { _, factory in
            factory.reset(.scope)
        }
    }

    func testContainerResetDiscardsInFlightValue() {
        assertInvalidation(scope: Scope.Cached(), expected: 2) { container, _ in
            container.reset(options: .scope)
        }
    }

    func testScopeResetDiscardsInFlightValue() {
        let scope = Scope.Cached()
        assertInvalidation(scope: scope, expected: 2) { container, _ in
            container.manager.reset(scope: scope)
        }
    }

    func testUnrelatedRegistrationPreservesInFlightValue() {
        assertInvalidation(scope: Scope.Cached(), expected: 1) { container, _ in
            Factory(container, key: "unrelated") { 0 }.cached.register { 100 }
        }
    }

    func testUnrelatedScopeResetPreservesInFlightValue() {
        assertInvalidation(scope: Scope.Cached(), expected: 1) { container, _ in
            container.manager.reset(scope: Scope.Shared())
        }
    }

    func testRestoringContainerStateDiscardsInFlightValue() {
        assertInvalidation(scope: Scope.Cached(), expected: 2) { container, _ in
            container.manager.push()
            container.manager.pop()
        }
    }

    func testPreviouslySelectedParameterizedResolutionCannotRepopulateCache() {
        let scope = Scope.Cached()
        let cache = Scope.Cache()
        let key = FactoryKey(type: Int.self, key: "service")
        // Model a caller that selected its registration before invalidation but has not entered Scope.resolve yet.
        let revision = cache.revision(forKey: key, scopeID: scope.scopeID)
        cache.removeValue(forKey: key)
        let parameterKey = key.parameterized(42)
        let (old, _) = scope.resolve(using: cache, key: parameterKey, ttl: nil, revision: revision) { 1 }
        XCTAssertEqual(old, 1)
        XCTAssertNil(cache.value(forKey: parameterKey))
        let (fresh, _) = scope.resolve(using: cache, key: parameterKey, ttl: nil) { 2 }
        XCTAssertEqual(fresh, 2)
        let (cached, _) = scope.resolve(using: cache, key: parameterKey, ttl: nil) { 3 }
        XCTAssertEqual(cached, 2)
    }

    private func assertInvalidation(scope: Scope, expected: Int,
                                    file: StaticString = #filePath, line: UInt = #line,
                                    invalidate: (Container, Factory<Int>) -> Void) {
        let container = Container()
        let circular = container.manager.circularDependencyTesting
        let trace = container.manager.trace
        container.manager.circularDependencyTesting = false
        container.manager.trace = false
        defer {
            container.manager.circularDependencyTesting = circular
            container.manager.trace = trace
        }
        let started = DispatchSemaphore(value: 0)
        let resume = DispatchSemaphore(value: 0)
        let finished = DispatchSemaphore(value: 0)
        let counter = InvalidationCounter()
        let factory = Factory(container, key: "service") {
            let value = counter.next()
            if value == 1 {
                started.signal()
                _ = resume.wait(timeout: .now() + 10)
            }
            return value
        }.scope(scope)
        DispatchQueue.global().async {
            _ = factory()
            finished.signal()
        }
        defer { resume.signal() }
        guard started.wait(timeout: .now() + 5) == .success else {
            XCTFail("Resolution did not start", file: file, line: line)
            return
        }
        invalidate(container, factory)
        resume.signal()
        guard finished.wait(timeout: .now() + 5) == .success else {
            XCTFail("Resolution did not finish", file: file, line: line)
            return
        }
        XCTAssertEqual(factory(), expected, file: file, line: line)
        XCTAssertEqual(factory(), expected, "The fresh result should be cached", file: file, line: line)
    }
}

private final class InvalidationCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var value = 0

    func next() -> Int {
        lock.withLock {
            value += 1
            return value
        }
    }
}
