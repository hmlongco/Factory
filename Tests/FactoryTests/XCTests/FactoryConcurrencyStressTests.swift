import XCTest
@testable import FactoryKit

/// Stress tests verifying that the split-lock resolution is thread-safe.
final class FactoryConcurrencyStressTests: XCTestCase, @unchecked Sendable {

    override func setUp() {
        super.setUp()
        StressContainer.shared.manager.reset()
        Scope.singleton.reset()
    }

    /// Verifies that singleton scope returns the same instance across all threads.
    func testSingletonConsistencyUnderContention() throws {
        let threadCount = 100
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "singleton-stress", attributes: .concurrent)

        nonisolated(unsafe) let results = UnsafeMutableBufferPointer<ObjectIdentifier?>.allocate(capacity: threadCount)
        results.initialize(repeating: nil)

        for i in 0..<threadCount {
            group.enter()
            queue.async {
                let instance = StressContainer.shared.singletonService()
                results[i] = ObjectIdentifier(instance)
                group.leave()
            }
        }

        let result = group.wait(timeout: .now() + 30)
        XCTAssertEqual(result, .success)

        let first = results[0]
        XCTAssertNotNil(first)
        for i in 1..<threadCount {
            XCTAssertEqual(results[i], first, "Thread \(i) got a different singleton instance")
        }
        results.deallocate()
    }

    /// Verifies that the singleton factory closure executes exactly once,
    /// even under heavy concurrent contention.
    func testSingletonFactoryCalledExactlyOnce() throws {
        let threadCount = 100
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "singleton-once", attributes: .concurrent)

        CountedService.resetCount()

        for _ in 0..<threadCount {
            group.enter()
            queue.async {
                let _ = StressContainer.shared.countedSingleton()
                group.leave()
            }
        }

        let result = group.wait(timeout: .now() + 30)
        XCTAssertEqual(result, .success)
        XCTAssertEqual(CountedService.creationCount, 1,
                       "Singleton factory must execute exactly once, but ran \(CountedService.creationCount) times")
    }

    /// Verifies that cached scope returns stable instances under contention.
    func testCachedScopeStability() throws {
        let threadCount = 50
        let iterations = 100
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "cached-stress", attributes: .concurrent)

        // Pre-warm to establish the cached instance
        let expected = ObjectIdentifier(StressContainer.shared.cachedService())

        nonisolated(unsafe) let failures = UnsafeMutablePointer<Int>.allocate(capacity: 1)
        failures.initialize(to: 0)
        let failureLock = NSLock()

        for _ in 0..<threadCount {
            group.enter()
            queue.async {
                for _ in 0..<iterations {
                    let instance = StressContainer.shared.cachedService()
                    if ObjectIdentifier(instance) != expected {
                        failureLock.lock()
                        failures.pointee += 1
                        failureLock.unlock()
                    }
                }
                group.leave()
            }
        }

        let result = group.wait(timeout: .now() + 30)
        XCTAssertEqual(result, .success)
        XCTAssertEqual(failures.pointee, 0, "Cached scope returned different instances")
        failures.deallocate()
    }

    /// Verifies graph scope shares instances within a resolution cycle but not across threads.
    func testGraphScopeIsolation() throws {
        let threadCount = 50
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "graph-stress", attributes: .concurrent)

        nonisolated(unsafe) let results = UnsafeMutableBufferPointer<Bool>.allocate(capacity: threadCount)
        results.initialize(repeating: false)

        for i in 0..<threadCount {
            group.enter()
            queue.async {
                let parent = StressContainer.shared.graphParent()
                results[i] = (parent.child1 === parent.child2)
                group.leave()
            }
        }

        let result = group.wait(timeout: .now() + 30)
        XCTAssertEqual(result, .success)

        for i in 0..<threadCount {
            XCTAssertTrue(results[i], "Thread \(i): graph scope didn't share instance within cycle")
        }
        results.deallocate()
    }

    /// Regression: concurrent unique resolves on a non-graph container must not
    /// corrupt graph depth/cache while another container is mid graph cycle.
    /// (Release previously called enter/leave without the recursive lock when
    /// hasGraphScope was false.)
    func testNonGraphResolvesDoNotCorruptGraphDepth() throws {
        let threadCount = 40
        let iterations = 200
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "graph-depth-stress", attributes: .concurrent)

        nonisolated(unsafe) let failures = UnsafeMutablePointer<Int>.allocate(capacity: 1)
        failures.initialize(to: 0)
        let failureLock = NSLock()

        // Half the threads hammer a container that never uses graph scope.
        for _ in 0..<(threadCount / 2) {
            group.enter()
            queue.async {
                for _ in 0..<iterations {
                    _ = NonGraphStressContainer.shared.uniqueService()
                }
                group.leave()
            }
        }

        // Half the threads resolve graph parents; children must still share.
        for _ in 0..<(threadCount / 2) {
            group.enter()
            queue.async {
                for _ in 0..<iterations {
                    let parent = StressContainer.shared.graphParent()
                    if parent.child1 !== parent.child2 {
                        failureLock.lock()
                        failures.pointee += 1
                        failureLock.unlock()
                    }
                }
                group.leave()
            }
        }

        let result = group.wait(timeout: .now() + 30)
        XCTAssertEqual(result, .success)
        XCTAssertEqual(failures.pointee, 0,
                       "Graph sharing broke under concurrent non-graph resolves (\(failures.pointee) failures)")
        XCTAssertEqual(Scope.graph.depth, 0, "Graph depth leaked after concurrent resolves")
        failures.deallocate()
    }

    /// defaultScope == .graph must mark hasGraphScope and share within a cycle
    /// even before any factory explicitly registers .graph.
    func testDefaultGraphScopeSharesWithinCycle() throws {
        DefaultGraphStressContainer.shared.manager.reset()
        DefaultGraphStressContainer.shared.manager.defaultScope = .graph

        let parent = DefaultGraphStressContainer.shared.graphParent()
        XCTAssertTrue(parent.child1 === parent.child2)
        XCTAssertTrue(DefaultGraphStressContainer.shared.manager.state.hasGraphScope)
        XCTAssertEqual(Scope.graph.depth, 0)
    }

}

// MARK: - Test Helpers

private final class StressContainer: SharedContainer {
    static let shared = StressContainer()
    let manager = ContainerManager()

    var s0: Factory<StressService> { self { StressService() } }

    var cachedService: Factory<StressService> {
        self { StressService() }.cached
    }

    var singletonService: Factory<StressService> {
        self { StressService() }.singleton
    }

    var countedSingleton: Factory<CountedService> {
        self { CountedService() }.singleton
    }

    var graphParent: Factory<GraphParent> {
        self { GraphParent(child1: self.graphChild(), child2: self.graphChild()) }
    }

    var graphChild: Factory<StressService> {
        self { StressService() }.graph
    }
}

/// Container that never registers a graph-scoped factory — used to stress
/// concurrent unique resolves against a graph-using container.
private final class NonGraphStressContainer: SharedContainer {
    static let shared = NonGraphStressContainer()
    let manager = ContainerManager()

    var uniqueService: Factory<StressService> {
        self { StressService() }
    }
}

/// Container that relies on defaultScope == .graph rather than per-factory .graph.
private final class DefaultGraphStressContainer: SharedContainer {
    static let shared = DefaultGraphStressContainer()
    let manager = ContainerManager()

    var graphParent: Factory<GraphParent> {
        self { GraphParent(child1: self.graphChild(), child2: self.graphChild()) }
    }

    var graphChild: Factory<StressService> {
        self { StressService() }
    }
}

private class StressService {
    init() {}
}

private class CountedService {
    private static let _lock = NSLock()
    nonisolated(unsafe) private static var _count = 0
    static var creationCount: Int {
        _lock.lock()
        defer { _lock.unlock() }
        return _count
    }
    static func resetCount() {
        _lock.lock()
        _count = 0
        _lock.unlock()
    }
    init() {
        CountedService._lock.lock()
        CountedService._count += 1
        CountedService._lock.unlock()
    }
}

private class GraphParent {
    let child1: StressService
    let child2: StressService
    init(child1: StressService, child2: StressService) {
        self.child1 = child1
        self.child2 = child2
    }
}

private final class CallCounter: @unchecked Sendable {
    private let _lock = NSLock()
    private var _value = 0
    var value: Int {
        _lock.lock()
        defer { _lock.unlock() }
        return _value
    }
    func increment() {
        _lock.lock()
        _value += 1
        _lock.unlock()
    }
}
