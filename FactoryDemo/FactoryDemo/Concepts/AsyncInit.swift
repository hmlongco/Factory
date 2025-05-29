//
//  AsyncInit.swift
//  FactoryDemo
//
//  Created by Michael Long on 6/26/24.
//

import Foundation
import FactoryMacros

// something with an asynchronous initializer
struct AsyncInit {
    let a: Int
    init() async {
        a = 1
    }
}

// generic wrapper for any asynchronous initializer
struct AsyncInitWrapper<T> {
    let wrapped: () async -> T
}

extension Container {
    // Factory using initialization wrapper
    var someAsyncObject: Factory<AsyncInitWrapper<AsyncInit>> {
        self {
            AsyncInitWrapper { await AsyncInit() }
        }
    }
    // Factory using Task isolated context
    var taskAsyncObject: Factory<Task<AsyncInit, Never>> {
        self {
            Task { await AsyncInit() }
        }
    }
}

func testAsyncInit() {
    Task {
        let a1 = await Container.shared.someAsyncObject().wrapped()
        let a2 = await Container.shared.taskAsyncObject().value
    }
}
