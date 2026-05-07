import XCTest
@testable import FactoryKit

// MARK: - Thread-Safety Tests for @LazyInjected and @WeakLazyInjected

final class FactoryLazyInjectedThreadSafetyTests: XCTestCase, @unchecked Sendable {

    override func setUp() {
        super.setUp()
        LazyThreadSafetyContainer.shared.reset()
    }

    /// Verifies that concurrent first-access to a @LazyInjected property does not crash.
    /// Under TSan, this would flag the data race present in the unfixed version.
    func testConcurrentFirstAccessDoesNotCrash() {
        for _ in 0..<100 {
            let object = LazyInjectedHolder()
            DispatchQueue.concurrentPerform(iterations: 20) { _ in
                // All threads race to trigger first resolution
                let value = object.service
                XCTAssertNotNil(value)
            }
        }
    }

    /// Verifies that a singleton-scoped factory is only resolved once despite concurrent access.
    func testConcurrentFirstAccessResolvesOnce() {
        let object = LazyInjectedSingletonHolder()
        let results = LockedArray<ObjectIdentifier>()

        DispatchQueue.concurrentPerform(iterations: 50) { _ in
            let value = object.service
            results.append(ObjectIdentifier(value))
        }

        // All results should be the same instance (singleton scope)
        let unique = Set(results.values)
        XCTAssertEqual(unique.count, 1, "Singleton-scoped @LazyInjected should resolve to a single instance, got \(unique.count)")
    }

    /// Verifies that concurrent first-access to a @WeakLazyInjected property does not crash.
    func testWeakLazyInjectedConcurrentFirstAccessDoesNotCrash() {
        for _ in 0..<100 {
            let object = WeakLazyInjectedHolder()
            DispatchQueue.concurrentPerform(iterations: 20) { _ in
                _ = object.service
            }
        }
    }

    /// Verifies that concurrent writes to @LazyInjected do not crash.
    func testConcurrentWriteDoesNotCrash() {
        for _ in 0..<100 {
            let object = LazyInjectedHolder()
            DispatchQueue.concurrentPerform(iterations: 20) { i in
                if i % 2 == 0 {
                    _ = object.service
                } else {
                    object.service = ThreadSafeService()
                }
            }
        }
    }

    /// Verifies resolvedOrNil() returns nil before first access and a value after.
    func testResolvedOrNilThreadSafety() {
        let object = LazyInjectedHolder()

        // Before access, should be nil
        XCTAssertNil(object.resolvedOrNil)

        // Trigger resolution
        _ = object.service

        // After access, should be non-nil
        XCTAssertNotNil(object.resolvedOrNil)
    }
}

// MARK: - Test Helpers

/// Thread-safe array wrapper for use in concurrent closures.
private final class LockedArray<Element>: @unchecked Sendable {
    private var storage: [Element] = []
    private let lock = NSLock()

    func append(_ element: Element) {
        lock.lock()
        storage.append(element)
        lock.unlock()
    }

    var values: [Element] {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }
}

private final class ThreadSafeService: @unchecked Sendable {
    let id = UUID()
    init() {
        // Simulate non-trivial initialization
        Thread.sleep(forTimeInterval: 0.001)
    }
}

private final class LazyThreadSafetyContainer: SharedContainer {
    static let shared = LazyThreadSafetyContainer()
    var service: Factory<ThreadSafeService> { self { ThreadSafeService() } }
    var singletonService: Factory<ThreadSafeService> { self { ThreadSafeService() }.singleton }
    let manager = ContainerManager()
}

/// Test holder using @LazyInjected with default (unique) scope.
private final class LazyInjectedHolder: @unchecked Sendable {
    @LazyInjected(\LazyThreadSafetyContainer.service) var service: ThreadSafeService

    var resolvedOrNil: ThreadSafeService? {
        $service.resolvedOrNil()
    }
}

/// Test holder using @LazyInjected with singleton scope.
private final class LazyInjectedSingletonHolder: @unchecked Sendable {
    @LazyInjected(\LazyThreadSafetyContainer.singletonService) var service: ThreadSafeService
}

/// Test holder using @WeakLazyInjected.
private final class WeakLazyInjectedHolder: @unchecked Sendable {
    @WeakLazyInjected(\LazyThreadSafetyContainer.service) var service: ThreadSafeService?
}
