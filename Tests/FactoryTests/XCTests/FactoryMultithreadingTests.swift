import XCTest
@testable import FactoryKit

final class FactoryMultithreadingTests: XCTestCase, @unchecked Sendable {

    let qa = DispatchQueue(label: "A", qos: .userInteractive, attributes: .concurrent)
    let qb = DispatchQueue(label: "B", qos: .userInitiated, attributes: .concurrent)
    let qc = DispatchQueue(label: "C", qos: .background, attributes: .concurrent)
    let qd = DispatchQueue(label: "E", qos: .utility, attributes: .concurrent)

    override func setUp() {
        super.setUp()
        MultiThreadedContainer.shared.reset()
        iterations = 0
    }

    func testMultiThreading() throws {

        // basically tests that nothing locks up or crashes while doing registrations and resolutions.
        // behavior is pretty apparent if locks are disabled.

        let group = DispatchGroup()

        for _ in 0...10000 {
            group.enter()
            qa.async {
                MultiThreadedContainer.shared.a.register { A(b: MultiThreadedContainer.shared.b()) }
                group.leave()
            }
            group.enter() // outer qa
            group.enter() // nested qc
            group.enter() // nested qd
            qa.async {
                self.qc.async {
                    MultiThreadedContainer.shared.b.register { B(c: MultiThreadedContainer.shared.c()) }
                    group.leave()
                }
                self.qd.async {
                    let b: B = MultiThreadedContainer.shared.b()
                    b.test()
                    group.leave()
                }
                group.leave()
            }
            group.enter()
            qc.async {
                MultiThreadedContainer.shared.b.register { B(c: MultiThreadedContainer.shared.c()) }
                group.leave()
            }
            group.enter()
            qd.async {
                let b: B = MultiThreadedContainer.shared.b()
                b.test()
                group.leave()
            }
            group.enter()
            qa.async {
                let a: A = MultiThreadedContainer.shared.a()
                a.test()
                group.leave()
            }
            group.enter()
            qb.async {
                let b: B = MultiThreadedContainer.shared.b()
                b.test()
                group.leave()
            }
            group.enter()
            qb.async {
                let d: D = MultiThreadedContainer.shared.d()
                d.test()
                group.leave()
            }
            group.enter()
            qc.async {
                let b: B = MultiThreadedContainer.shared.b()
                b.test()
                group.leave()
            }
            group.enter() // outer qc
            group.enter() // nested qd register
            group.enter() // nested qd resolve
            qc.async {
                self.qd.async {
                    MultiThreadedContainer.shared.e.register { E() }
                    group.leave()
                }
                self.qd.async {
                    let e: E = MultiThreadedContainer.shared.e()
                    e.test()
                    group.leave()
                }
                group.leave()
            }
        }

        let result = group.wait(timeout: .now() + 60)
        XCTAssertEqual(result, .success, "test timed out — stuck at \(interationValue())/80008 iterations")
        XCTAssertEqual(iterations, 80008)
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
