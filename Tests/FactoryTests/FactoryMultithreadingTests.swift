import XCTest
@testable import Factory

final class FactoryMultithreadingTests: XCTestCase {

    let container = MultiThreadedContainer()

    let qa = DispatchQueue(label: "A", qos: .userInteractive, attributes: .concurrent)
    let qb = DispatchQueue(label: "B", qos: .userInitiated, attributes: .concurrent)
    let qc = DispatchQueue(label: "C", qos: .background, attributes: .concurrent)
    let qd = DispatchQueue(label: "E", qos: .background, attributes: .concurrent)

    override func setUp() {
        super.setUp()
        Container.Registrations.reset()
        Container.Scope.reset()
    }

    func testMultiThreading() throws {
        // basically tests that nothing locks up or crashes while doing registrations and resolutions.
        // behavior is pretty apparent if locks are disabled.

        let expA = expectation(description: "A")
        let expB = expectation(description: "B")
        let expC = expectation(description: "C")
        let expD = expectation(description: "D")

        for _ in 0...10000 {
            qa.async {
               MultiThreadedContainer.a.register { A(b: MultiThreadedContainer.b()) }
            }
            qa.async {
                self.qc.async {
                    MultiThreadedContainer.b.register { B(c: MultiThreadedContainer.c()) }
                }
                self.qd.async {
                    let b: B = MultiThreadedContainer.b()
                    b.test()
                }
            }
            qc.async {
                MultiThreadedContainer.b.register { B(c: MultiThreadedContainer.c()) }
            }
            qd.async {
                let b: B = MultiThreadedContainer.b()
                b.test()
            }
            qa.async {
                let a: A = MultiThreadedContainer.a()
                a.test()
            }
            qb.async {
                let b: B = MultiThreadedContainer.b()
                b.test()
            }
            qb.async {
                let d: D = MultiThreadedContainer.d()
                d.test()
            }
            qc.async {
                let b: B = MultiThreadedContainer.b()
                b.test()
            }
            qc.async {
                self.qd.async {
                    MultiThreadedContainer.e.register { E() }
                }
                self.qd.async {
                    let e: E = MultiThreadedContainer.e()
                    e.test()
                }
            }
        }

        self.qa.async {  expA.fulfill() }
        self.qb.async {  expB.fulfill() }
        self.qc.async {  expC.fulfill() }
        self.qd.async {  expD.fulfill() }

        wait(for: [expA, expB, expC, expD], timeout: 20)

        // threads not quite done yet
        
        while interationValue() < 80008 {
            Thread.sleep(forTimeInterval: 0.2)
        }

        print(iterations)
        XCTAssertEqual(iterations, 80008)

    }

}

var iterations = 0
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
    @LazyInjected(MultiThreadedContainer.d) var d: D
    init() {}
    func test() {
        d.test()
        increment()
    }
}

class MultiThreadedContainer: SharedContainer {
    fileprivate static var a = Factory<A> { A(b: b()) }
    fileprivate static var b = Factory<B> { B(c: c()) }
    fileprivate static var c = Factory<C> { C(d: d()) }
    fileprivate static var d = Factory<D>(scope: .cached) { D() }
    fileprivate static var e = Factory<E> { E() }
}

extension XCTestCase {
    func wait(interval: TimeInterval = 0.1 , completion: @escaping (() -> Void)) {
        let exp = expectation(description: "")
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            completion()
            exp.fulfill()
        }
        waitForExpectations(timeout: interval + 0.1) // add 0.1 for sure async after called
    }
}
