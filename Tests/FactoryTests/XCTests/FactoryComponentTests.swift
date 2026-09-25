import XCTest
@testable import FactoryKit

let key1String = StaticString(stringLiteral: "s1")
let key1StringDup = StaticString(stringLiteral: "s1")
let key2String = StaticString(stringLiteral: "s2")
let key3Unicode = MyStaticScalar("\u{1F600}").value
let key4Unicode = MyStaticScalar("\u{1F601}").value

final class FactoryComponentTests: XCTestCase {

    let key1 = FactoryKey(type: UUID.self, key: key1String)
    let key1D = FactoryKey(type: UUID.self, key: key1StringDup)
    let key1S = FactoryKey(type: String.self, key: key1String)
    let key2 = FactoryKey(type: UUID.self, key: key2String)
    let key3U = FactoryKey(type: UUID.self, key: key3Unicode)
    let key4U = FactoryKey(type: UUID.self, key: key4Unicode)

    override func setUp() {
        super.setUp()
        Container.shared.reset()
    }

    func testScopeCache() {
        let cache = Scope.Cache()
        let scopeID = UUID()
        let strongBox = StrongBox(scopeID: scopeID, timestamp: 0, boxed: { MyService() })
        let anotherBox = StrongBox(scopeID: UUID(), timestamp: 0, boxed: { MyService() })
        // Finds nothing
        XCTAssertNil(cache.value(forKey: key1))
        XCTAssertNil(cache.value(forKey: key2))
        XCTAssertTrue(cache.isEmpty)
        // Finds for  key
        cache.set(value: strongBox, forKey: key1)
        cache.set(value: anotherBox, forKey: key2)
        XCTAssertNotNil(cache.value(forKey: key1))
        XCTAssertNotNil(cache.value(forKey: key2))
        XCTAssertFalse(cache.isEmpty)
        // Remove works
        cache.removeValue(forKey: key1)
        XCTAssertNil(cache.value(forKey: key1))
        XCTAssertNotNil(cache.value(forKey: key2))
        XCTAssertFalse(cache.isEmpty)
        // Reset works
        cache.reset()
        XCTAssertNil(cache.value(forKey: key1))
        XCTAssertNil(cache.value(forKey: key2))
        XCTAssertTrue(cache.isEmpty)
        // Scope reset works
        cache.set(value: strongBox, forKey: key1)
        cache.set(value: anotherBox, forKey: key2)
        cache.reset(scopeID: scopeID)
        XCTAssertNil(cache.value(forKey: key1))
        XCTAssertNotNil(cache.value(forKey: key2))
        XCTAssertFalse(cache.isEmpty)
        // Resolution locks start empty
        XCTAssertTrue(cache.resolutionLocks.isEmpty)
        // First request creates lock
        let lock1 = cache.resolutionLock(forKey: key1)
        XCTAssertEqual(lock1.locks, 1)
        XCTAssertEqual(cache.resolutionLocks.count, 1)
        // Second request for same key shares lock and bumps count
        let lock1B = cache.resolutionLock(forKey: key1)
        XCTAssertTrue(lock1 === lock1B)
        XCTAssertEqual(lock1.locks, 2)
        XCTAssertEqual(cache.resolutionLocks.count, 1)
        // Different key gets its own lock
        let lock2 = cache.resolutionLock(forKey: key2)
        XCTAssertFalse(lock1 === lock2)
        XCTAssertEqual(cache.resolutionLocks.count, 2)
        // Cache reset leaves in-flight locks alone
        cache.reset()
        XCTAssertEqual(cache.resolutionLocks.count, 2)
        // Partial unlock keeps lock
        cache.resolution(unlock: lock1, forKey: key1)
        XCTAssertEqual(lock1.locks, 1)
        XCTAssertTrue(cache.resolutionLocks[key1] === lock1)
        // Final unlock removes lock
        cache.resolution(unlock: lock1, forKey: key1)
        XCTAssertEqual(lock1.locks, 0)
        XCTAssertNil(cache.resolutionLocks[key1])
        cache.resolution(unlock: lock2, forKey: key2)
        XCTAssertTrue(cache.resolutionLocks.isEmpty)
        // New request after release gets a fresh lock
        let lock1C = cache.resolutionLock(forKey: key1)
        XCTAssertFalse(lock1 === lock1C)
        XCTAssertEqual(lock1C.locks, 1)
        cache.resolution(unlock: lock1C, forKey: key1)
        XCTAssertTrue(cache.resolutionLocks.isEmpty)
        // Scope resolution releases its lock on both miss and hit paths
        var calls = 0
        _ = Scope.cached.resolve(using: cache, key: key1, ttl: nil) { calls += 1; return UUID() }
        XCTAssertTrue(cache.resolutionLocks.isEmpty)
        _ = Scope.cached.resolve(using: cache, key: key1, ttl: nil) { calls += 1; return UUID() }
        XCTAssertTrue(cache.resolutionLocks.isEmpty)
        XCTAssertEqual(calls, 1)
        // Uncacheable (nil) results always take the slow path and still release
        _ = Scope.cached.resolve(using: cache, key: key2, ttl: nil) { Optional<UUID>.none }
        _ = Scope.cached.resolve(using: cache, key: key2, ttl: nil) { Optional<UUID>.none }
        XCTAssertTrue(cache.resolutionLocks.isEmpty)
    }

    func testFactoryKey() {
        // All should match
        XCTAssertEqual(key1, key1)
        XCTAssertEqual(key1S, key1S)
        XCTAssertEqual(key1, key1D)
        XCTAssertEqual(key1S, key1S)
        XCTAssertEqual(key2, key2)
        XCTAssertEqual(key3U, key3U)
        // Dup should match
        XCTAssertEqual(key1, key1D)
        // All should not match
        XCTAssertNotEqual(key1, key1S)
        XCTAssertNotEqual(key1, key3U)
        XCTAssertNotEqual(key1, key2)
        XCTAssertNotEqual(key3U, key4U)
    }

    func testFactoryKeyEdgeCases() {
        let f1 = FactoryKey(type: Int.self, key: key1String)
        XCTAssertEqual(f1, f1)
        let f2a = FactoryKey(type: Int.self, key: key1String)
        let f2b = FactoryKey(type: Int.self, key: key1StringDup)
        XCTAssertEqual(f2a, f2b)
        let f3 = FactoryKey(type: Int.self, key: key3Unicode)
        XCTAssertEqual(f3, f3)
        let f3a = FactoryKey(type: Int.self, key: key3Unicode)
        let f3b = FactoryKey(type: Int.self, key: key3Unicode)
        XCTAssertEqual(f3a, f3b)
        let f4a = FactoryKey(type: Int.self, key: key1String)
        let f4b = FactoryKey(type: Int.self, key: key3Unicode)
        XCTAssertNotEqual(f4a, f4b)
        var hasher = Hasher()
        let h1 = FactoryKey(type: Int.self, key: key1String)
        h1.hash(into: &hasher)
        let h2 = FactoryKey(type: Int.self, key: key3Unicode)
        h2.hash(into: &hasher)
    }

    func testParameterizedFactoryKey() {
        let f1 = FactoryKey(type: Int.self, key: key1String)
        let f2 = FactoryKey(type: Int.self, key: key1String)
        XCTAssertEqual(f1, f2)
        let f1f = f1.parameterized("foo")
        XCTAssertNotEqual(f1f, f2)
        let f2f = f2.parameterized("foo")
        XCTAssertEqual(f1f, f2f)
        let f1b = f2.parameterized("bar")
        XCTAssertNotEqual(f1b, f2f)
        let f1v = f1.parameterized(())
        XCTAssertEqual(f1v, f1)
        XCTAssertEqual(f1f.normalized(), f1)
        XCTAssertEqual(f1b.normalized(), f2)
    }

}

struct MyStaticScalar: ExpressibleByUnicodeScalarLiteral {
    typealias UnicodeScalarLiteralType = StaticString
    let value: StaticString
    init(unicodeScalarLiteral value: StaticString) {
        self.value = value
    }
}
