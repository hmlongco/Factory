import XCTest
@testable import Factory

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

}

struct MyStaticScalar: ExpressibleByUnicodeScalarLiteral {
    typealias UnicodeScalarLiteralType = StaticString
    let value: StaticString
    init(unicodeScalarLiteral value: StaticString) {
        self.value = value
    }
}
