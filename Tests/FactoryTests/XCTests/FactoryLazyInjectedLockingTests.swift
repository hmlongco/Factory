import XCTest
@testable import FactoryKit

final class FactoryLazyInjectedLockingTests: XCTestCase, @unchecked Sendable {

    override func setUp() {
        super.setUp()
        LazyLockingContainer.shared.reset()
        Scope.singleton.reset()
    }

    // Verifies the core guarantee: even when many threads race on first access,
    // the factory closure is invoked exactly once.
    func testConcurrentFirstAccessInvokesFactoryExactlyOnce() {
        let counter = InvocationCounter()
        LazyLockingContainer.shared.service.register {
            counter.increment()
            return LazyLockingService()
        }

        let holder = LazyInjectedLockingHolder()
        DispatchQueue.concurrentPerform(iterations: 50) { _ in
            _ = holder.service
        }

        XCTAssertEqual(counter.value, 1, "@LazyInjected factory should be invoked exactly once under concurrent first access, got \(counter.value)")
    }

    // Runs the exactly-once check multiple times to catch probabilistic races.
    func testConcurrentFirstAccessInvokesFactoryExactlyOnceRepeated() {
        for _ in 0..<20 {
            LazyLockingContainer.shared.reset()
            let counter = InvocationCounter()
            LazyLockingContainer.shared.service.register {
                counter.increment()
                return LazyLockingService()
            }

            let holder = LazyInjectedLockingHolder()
            DispatchQueue.concurrentPerform(iterations: 50) { _ in
                _ = holder.service
            }

            XCTAssertEqual(counter.value, 1, "Factory invocation count should be 1, got \(counter.value)")
        }
    }

    // Same guarantee for @WeakLazyInjected.
    func testWeakLazyInjectedConcurrentFirstAccessInvokesFactoryExactlyOnce() {
        let counter = InvocationCounter()
        LazyLockingContainer.shared.service.register {
            counter.increment()
            return LazyLockingService()
        }

        let holder = WeakLazyInjectedLockingHolder()
        // Keep strong references so the weak dependency isn't released mid-test.
        let retained = RetainBag<LazyLockingService>()
        DispatchQueue.concurrentPerform(iterations: 50) { _ in
            if let svc = holder.service {
                retained.append(svc)
            }
        }

        XCTAssertEqual(counter.value, 1, "@WeakLazyInjected factory should be invoked exactly once under concurrent first access, got \(counter.value)")
        retained.discard()
    }

    // resolvedOrNil() should return nil before first access and non-nil after.
    func testResolvedOrNilSemanticsBeforeAndAfterAccess() {
        let holder = LazyInjectedLockingHolder()
        XCTAssertNil(holder.resolvedOrNil, "resolvedOrNil() should be nil before first access")
        _ = holder.service
        XCTAssertNotNil(holder.resolvedOrNil, "resolvedOrNil() should be non-nil after first access")
    }

    // resolve(reset:) should re-invoke the factory and result in a non-nil dependency.
    func testExplicitResolveUpdatesValue() {
        let holder = LazyInjectedLockingHolder()
        let first = holder.service
        holder.$service.resolve(reset: .none)
        let second = holder.resolvedOrNil
        XCTAssertNotNil(second)
        XCTAssertFalse(first === second, "resolve() should produce a new instance with a unique-scoped factory")
    }

}

// MARK: - Infrastructure

private final class InvocationCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0
    func increment() { lock.withLock { count += 1 } }
    var value: Int { lock.withLock { count } }
}

private final class RetainBag<T: AnyObject>: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [T] = []
    func append(_ element: T) { lock.withLock { storage.append(element) } }
    func discard() { lock.withLock { storage.removeAll() } }
}

final class LazyLockingService: @unchecked Sendable {
    init() {}
}

final class LazyLockingContainer: SharedContainer {
    static let shared = LazyLockingContainer()
    var service: Factory<LazyLockingService> { self { LazyLockingService() } }
    let manager = ContainerManager()
}

final class LazyInjectedLockingHolder: @unchecked Sendable {
    @LazyInjected(\LazyLockingContainer.service) var service: LazyLockingService
    var resolvedOrNil: LazyLockingService? { $service.resolvedOrNil() }
}

final class WeakLazyInjectedLockingHolder: @unchecked Sendable {
    @WeakLazyInjected(\LazyLockingContainer.service) var service: LazyLockingService?
}
