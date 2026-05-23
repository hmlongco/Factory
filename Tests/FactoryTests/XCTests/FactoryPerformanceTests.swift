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

private final class Leaf { }
private final class Mid {
    @Injected(\PerfContainer.leaf) var a
    @Injected(\PerfContainer.leaf) var b
}
private final class Root {
    @Injected(\PerfContainer.mid) var m1
    @Injected(\PerfContainer.mid) var m2
}

/// Dedicated container for the performance tests so registrations, scope caches,
/// and the `hasGraphScope` flag are isolated from `Container.shared` and from
/// every other test that touches it.
fileprivate final class PerfContainer: SharedContainer, @unchecked Sendable {
    @TaskLocal static var shared = PerfContainer()
    let manager = ContainerManager()

    var leaf: Factory<Leaf> { self { Leaf() }.cached }
    var mid:  Factory<Mid>  { self { Mid() } }
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
    func testMultiThreadedResolutionThroughput() {
        let threads = ProcessInfo.processInfo.activeProcessorCount
        let perThread = 10_000

        // Warm up — let modifiers fire, autoRegister settle, caches prime.
        for _ in 0..<1_000 { _ = PerfContainer.shared.root() }

        print("---- FactoryPerformanceTests throughput ----")
        for run in 1...3 {
            let (wallMs, nsPerOp) = measureOnce(threads: threads, perThread: perThread)
            print("run\(run)\tthreads=\(threads)\titers=\(threads * perThread)\twall=\(wallMs)ms\tns/op=\(String(format: "%.1f", nsPerOp))")
        }
    }

    /// XCTest `measure` variant. Useful if you want Xcode's baseline tracking
    /// and the standard 10-iteration stddev report. Less useful for cross-branch
    /// diffs because baselines are stored per machine.
    func testMultiThreadedResolutionBaseline() {
        let threads = ProcessInfo.processInfo.activeProcessorCount
        let perThread = 1_000

        for _ in 0..<1_000 { _ = PerfContainer.shared.root() }

        measure {
            DispatchQueue.concurrentPerform(iterations: threads) { _ in
                for _ in 0..<perThread { _ = PerfContainer.shared.root() }
            }
        }
    }

    // MARK: - Helpers

    private func measureOnce(threads: Int, perThread: Int) -> (wallMs: UInt64, nsPerOp: Double) {
        let start = DispatchTime.now()
        DispatchQueue.concurrentPerform(iterations: threads) { _ in
            for _ in 0..<perThread { _ = PerfContainer.shared.root() }
        }
        let ns = DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds
        let total = threads * perThread
        return (ns / 1_000_000, Double(ns) / Double(total))
    }
}
