import XCTest
@testable import Factory

let key1String = StaticString(stringLiteral: "s1")
let key2String = StaticString(stringLiteral: "s2")

final class FactoryComponentTests: XCTestCase {

    let key1 = FactoryKey(type: UUID.self, key: key1String)
    let key2 = FactoryKey(type: UUID.self, key: key2String)

    override func setUp() {
        super.setUp()
        Container.shared.reset()
    }

    func testScopeCache () {
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

}
