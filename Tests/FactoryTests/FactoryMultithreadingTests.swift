import XCTest
@testable import Factory

final class FactoryMultithreadingTests: XCTestCase, @unchecked Sendable {

    let qa = DispatchQueue(label: "A", qos: .userInteractive, attributes: .concurrent)
    let qb = DispatchQueue(label: "B", qos: .userInitiated, attributes: .concurrent)
    let qc = DispatchQueue(label: "C", qos: .background, attributes: .concurrent)
    let qd = DispatchQueue(label: "E", qos: .background, attributes: .concurrent)

    override func setUp() {
        super.setUp()
        MultiThreadedContainer.shared.reset()
        iterations = 0
    }

    func testMultiThreading() throws {

        // basically tests that nothing locks up or crashes while doing registrations and resolutions.
        // behavior is pretty apparent if locks are disabled.

        // MultiThreadedContainer.shared.manager.dependencyChainTestMax = 0

        let expA = expectation(description: "A")
        let expB = expectation(description: "B")
        let expC = expectation(description: "C")
        let expD = expectation(description: "D")

        for _ in 0...10000 {
            qa.async {
                MultiThreadedContainer.shared.a.register { A(b: MultiThreadedContainer.shared.b()) }
            }
            qa.async {
                self.qc.async {
                    MultiThreadedContainer.shared.b.register { B(c: MultiThreadedContainer.shared.c()) }
                }
                self.qd.async {
                    let b: B = MultiThreadedContainer.shared.b()
                    b.test()
                }
            }
            qc.async {
                MultiThreadedContainer.shared.b.register { B(c: MultiThreadedContainer.shared.c()) }
            }
            qd.async {
                let b: B = MultiThreadedContainer.shared.b()
                b.test()
            }
            qa.async {
                let a: A = MultiThreadedContainer.shared.a()
                a.test()
            }
            qb.async {
                let b: B = MultiThreadedContainer.shared.b()
                b.test()
            }
            qb.async {
                let d: D = MultiThreadedContainer.shared.d()
                d.test()
            }
            qc.async {
                let b: B = MultiThreadedContainer.shared.b()
                b.test()
            }
            qc.async {
                self.qd.async {
                    MultiThreadedContainer.shared.e.register { E() }
                }
                self.qd.async {
                    let e: E = MultiThreadedContainer.shared.e()
                    e.test()
                }
            }
        }

        self.qa.async {  expA.fulfill() }
        self.qb.async {  expB.fulfill() }
        self.qc.async {  expC.fulfill() }
        self.qd.async {  expD.fulfill() }

        wait(for: [expA, expB, expC, expD], timeout: 60)

        // threads not quite done yet

        while interationValue() < 80008 {
            Thread.sleep(forTimeInterval: 0.2)
        }

        print(iterations)
        XCTAssertEqual(iterations, 80008)

        MultiThreadedContainer.shared.manager.dependencyChainTestMax = 8
        
    }

}

nonisolated(unsafe) var iterations = 0
let lock = NSRecursiveLock()

func interationValue() -> Int {
    defer { lock.unlock() }
    lock.lock()
    return iterations
}

func increment() {
    lock.lock()
    iterations += 1
    lock.unlock()
}

fileprivate class A {
    var b: B
    init(b: B) {
        self.b = b
    }
    func test() {
        increment()
    }
}

fileprivate class B {
    var c: C
    init(c: C) {
        self.c = c
    }
    func test() {
        increment()
    }
}

fileprivate class C {
    var d: D
    init(d: D) {
        self.d = d
    }
    func test() {
        increment()
    }
}

fileprivate class D {
    init() {}
    func test() {
        increment()
    }
}

fileprivate class E {
    @LazyInjected(\MultiThreadedContainer.d) var d: D
    init() {}
    func test() {
        d.test()
        increment()
    }
}

fileprivate final class MultiThreadedContainer: SharedContainer {
    fileprivate static let shared = MultiThreadedContainer()
    fileprivate var a: Factory<A> { self { A(b: self.b()) } }
    fileprivate var b: Factory<B> { self { B(c: self.c()) } }
    fileprivate var c: Factory<C> { self { C(d: self.d()) } }
    fileprivate var d: Factory<D> { self { D() }.cached }
    fileprivate var e: Factory<E> { self { E() } }
    let manager = ContainerManager()
}
