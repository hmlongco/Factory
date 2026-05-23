//
//  FactoryPerformanceTests.swift
//  Factory
//
//  Created by Michael Long on 5/22/26.
//
//  Run in Release. In Xcode: Product > Scheme > Edit Scheme > Test > Info,
//  set the test build configuration to Release. From the CLI:
//
//      swift test -c release --filter FactoryPerformanceTests
//
//  DEBUG builds include the circular-dependency check and other instrumentation
//  in `resolve(with:)`, which dominates the numbers and hides the change under test.

import XCTest
@testable import FactoryKit

private final class Leaf1 {
    @Injected(\PerfContainer.leaf2) var d
    var total: Int = 0
    init() {
        for i in 0..<10 {
            total += i
        }
    }
}
private final class Leaf2 {
    @Injected(\PerfContainer.leaf3) var d
    @Injected(\PerfContainer.leaf3) var e
    @Injected(\PerfContainer.leaf3) var f
    @Injected(\PerfContainer.leaf3) var g
    var total: Int = 0
}
private final class Leaf3 {
    var total: Int = 0
    init() {
        for i in 0..<10 {
            total += i
        }
    }
}
private final class Mid1 {
    @Injected(\PerfContainer.leaf1) var a
    var total: Int = 0
    //    init() {
    //        for i in 0..<10 {
    //            total += i
    //        }
    //    }
}
private final class Mid2 {
    @Injected(\PerfContainer.leaf2) var b
    @Injected(\PerfContainer.leaf2) var c
    @Injected(\PerfContainer.leaf2) var d
    var total: Int = 0
    //    init() {
    //        for i in 0..<10 {
    //            total += i
    //        }
    //    }
}
private final class Root {
    @Injected(\PerfContainer.mid1) var m1
    @Injected(\PerfContainer.mid2) var m2
    var total: Int = 0
    //    init() {
    //        for i in 0..<10 {
    //            total += i
    //        }
    //    }
}

/// Dedicated container for the performance tests so registrations, scope caches,
/// and the `hasGraphScope` flag are isolated from `Container.shared` and from
/// every other test that touches it.
fileprivate final class PerfContainer: SharedContainer, @unchecked Sendable {
    @TaskLocal static var shared = PerfContainer()
    let manager = ContainerManager()

    var leaf1: Factory<Leaf1> { self { Leaf1() }.cached }
    var leaf2: Factory<Leaf2> { self { Leaf2() } }
    var leaf3: Factory<Leaf3> { self { Leaf3() } }
    var mid1:  Factory<Mid1>  { self { Mid1() } }
    var mid2:  Factory<Mid2>  { self { Mid2() } }
    var root: Factory<Root> { self { Root() } }
}

final class FactoryPerformanceTests: XCTestCase {

    override func setUp() {
        super.setUp()
        PerfContainer.shared.manager.reset()
        globalCircularDependencyTesting = false
    }
    override func tearDown() {
        super.tearDown()
        PerfContainer.shared.manager.reset()
        globalCircularDependencyTesting = true
    }

    /// Raw multi-threaded throughput. Prints ns/op per run so you can diff the
    /// console output between `main` and `locks` directly.
    @available(iOS 15.0, *)
    func testMultiThreadedResolutionThroughput() {
        let threads = ProcessInfo.processInfo.activeProcessorCount
        let perThread = 10_000

        // Warm up — let modifiers fire, autoRegister settle, caches prime.
        for _ in 0..<10 { _ = PerfContainer.shared.root() }

        print("---- FactoryPerformanceTests ----")
        for run in 1...3 {
            let (wallMs, msPerOp) = measureOnce(threads: threads, perThread: perThread)
            let iters = (threads * perThread).formatted(.number)
            let wall = wallMs.formatted(.number)
            let op = msPerOp.formatted(.number.precision(.fractionLength(4)))
            print("run\(run)\tthreads=\(threads)\titers=\(iters)\twall=\(wall)ms\top=\(op)ms")
        }
        print("---- FactoryPerformanceTests ----")
    }

    // MARK: - Helpers

    private func measureOnce(threads: Int, perThread: Int) -> (wallMs: UInt64, msPerOp: Double) {
        let start = DispatchTime.now()
        DispatchQueue.concurrentPerform(iterations: threads) { _ in
            for _ in 0..<perThread { _ = PerfContainer.shared.root() }
        }
        let ns = DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds
        let total = threads * perThread
        return (ns / 1_000_000, (Double(ns) / Double(total)) / 1_000_000)
    }
}
