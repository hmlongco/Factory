//
//  AsyncInit.swift
//  FactoryDemo
//
//  Created by Michael Long on 6/26/24.
//

import Foundation
import FactoryKit

// something with an asynchronous initializer
nonisolated struct AsyncInit {
    private let value: Int
    init() async {
        value = 123456
    }
    func value() async -> Int {
        value
    }
}

// generic wrapper for any asynchronous initializer
class AsyncWrapper<T> {
    private var instance: T?
    private let factory: () async -> T

    init(factory: @escaping () async -> T) {
        self.factory = factory
    }

    func callAsFunction() async -> T {
        if let instance {
            return instance
        }
        let instance = await factory()
        self.instance = instance
        return instance
    }
}

extension Container {
    // Factory using async initialization wrapper
    var asyncObject: Factory<AsyncWrapper<AsyncInit>> {
        self { AsyncWrapper { await AsyncInit() } }.cached
    }
}

func testAsyncInit() {
    @Injected(\.asyncObject) var asyncObject
    Task {
        let result = await asyncObject().value()
        print("AsyncInit Value: \(result)")
    }
}
