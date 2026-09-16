import XCTest
@testable import FactoryKit

final class FactoryResolutionLockTests: XCTestCase {
    func testContainerResetReleasesParameters() {
        let container = Container()
        let factory = ParameterFactory<Parameter, UUID>(container) { _ in UUID() }.scopeOnParameters.cached
        weak var parameter: Parameter?
        do {
            let value = Parameter()
            parameter = value
            _ = factory(value)
        }
        XCTAssertNotNil(parameter)
        container.reset()
        XCTAssertNil(parameter)
    }

    func testFactoryResetReleasesParameters() {
        let container = Container()
        let factory = ParameterFactory<Parameter, UUID>(container) { _ in UUID() }.scopeOnParameters.cached
        weak var parameter: Parameter?
        do {
            let value = Parameter()
            parameter = value
            _ = factory(value)
        }
        factory.reset(.scope)
        XCTAssertNil(parameter)
    }

    func testScopeResetReleasesParameters() {
        let container = Container()
        let scope = Scope.Cached()
        let factory = ParameterFactory<Parameter, UUID>(container) { _ in UUID() }.scopeOnParameters.scope(scope)
        weak var parameter: Parameter?
        do {
            let value = Parameter()
            parameter = value
            _ = factory(value)
        }
        container.manager.reset(scope: scope)
        XCTAssertNil(parameter)
    }

    func testUncachedNilReleasesParametersWithoutReset() {
        let container = Container()
        let factory = ParameterFactory<Parameter, UUID?>(container) { _ in nil }.scopeOnParameters.cached
        weak var parameter: Parameter?
        do {
            let value = Parameter()
            parameter = value
            XCTAssertNil(factory(value))
        }
        XCTAssertNil(parameter)
    }

    func testResetPreservesLockUntilAllHoldersAndWaitersReleaseIt() {
        let cache = Scope.Cache()
        weak var parameter: Parameter?
        weak var retiredLock: CrossPlatformLock?
        do {
            let value = Parameter()
            parameter = value
            let key = FactoryKey(type: UUID.self, key: "service").parameterized(value)
            let holder = cache.resolutionLock(forKey: key)
            retiredLock = holder
            holder.lock()
            // A waiting resolution registers before attempting to acquire the held lock.
            let waiter = cache.resolutionLock(forKey: key)
            XCTAssertTrue(holder === waiter)
            cache.reset()
            holder.unlock()
            cache.releaseResolutionLock(forKey: key)

            let newcomer = cache.resolutionLock(forKey: key)
            XCTAssertTrue(waiter === newcomer, "Reset must not replace a lock with registered waiters")
            cache.releaseResolutionLock(forKey: key)
            cache.releaseResolutionLock(forKey: key)

            let replacement = cache.resolutionLock(forKey: key)
            XCTAssertFalse(replacement === holder, "An unused lock must be reclaimed")
            cache.releaseResolutionLock(forKey: key)
        }
        XCTAssertNil(retiredLock)
        XCTAssertNil(parameter)
    }

    private final class Parameter: Hashable {
        static func == (lhs: Parameter, rhs: Parameter) -> Bool { lhs === rhs }
        func hash(into hasher: inout Hasher) { hasher.combine(ObjectIdentifier(self)) }
    }
}
