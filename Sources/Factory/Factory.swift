//
// Factory.swift
//
// GitHub Repo and Documentation: https://github.com/hmlongco/Factory
//
// Copyright ©2022 Michael Long. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

import Foundation

public class Factory: SharedFactory {
    // base class for user dependencies
}

open class SharedFactory {

    public struct Factory<T> {
        public init(factory: @escaping () -> T) {
            self.factory = factory
        }
        public init(scope: Scope, factory: @escaping () -> T) {
            self.factory = factory
            self.scope = scope
        }
        public func callAsFunction() -> T {
            let id = Int(bitPattern: ObjectIdentifier(T.self))
            let dependency = scope?.cached(id) ?? Registrations.registered(id) ?? factory()
            scope?.cache(id: id, instance: dependency)
            Decorator.decorate?(dependency)
            return dependency
        }
        public func register(factory: @escaping () -> T) {
            let id = Int(bitPattern: ObjectIdentifier(T.self))
            Registrations.register(id: id, factory: factory)
            scope?.reset(id)
        }
        public func reset() {
            let id = Int(bitPattern: ObjectIdentifier(T.self))
            Registrations.reset(id)
            scope?.reset(id)
        }
        private var factory: () -> T
        private var scope: Scope?
    }

    public class Registrations {

        public static func push() {
            defer { lock.unlock() }
            lock.lock()
            stack.append(registrations)
        }
        public static func pop() {
            defer { lock.unlock() }
            lock.lock()
            registrations = stack.popLast() ?? [:]
        }
        public static func reset() {
            defer { lock.unlock() }
            lock.lock()
            registrations = [:]
        }

        fileprivate static func register<T>(id: Int, factory: @escaping () -> T) {
            defer { lock.unlock() }
            lock.lock()
            registrations[id] = factory
        }
        fileprivate static func registered<T>(_ id: Int) -> T? {
            defer { lock.unlock() }
            lock.lock()
            if let registration = registrations[id] {
                let result = registration()
                if let optional = result as? T? {
                    return optional
                }
                return result as? T
            }
            return nil
        }
        fileprivate static func reset(_ id: Int) {
            defer { lock.unlock() }
            lock.lock()
            registrations.removeValue(forKey: id)
        }

        private static var registrations: [Int:() -> Any] = [:]
        private static var stack: [[Int:() -> Any]] = []
        private static var lock = NSRecursiveLock()
    }

    public class Scope {
        private init() {}
        fileprivate func cached<T>(_ id: Int) -> T? {
            fatalError()
        }
        fileprivate func cache(id: Int, instance: Any) {
            fatalError()
        }
        fileprivate func reset(_ id: Int) {}
        public func reset() {}
    }

    public struct Decorator {
        public static var decorate: ((_ dependency: Any) -> Void)?
    }
}

extension SharedFactory.Scope {

    public static let cached = Cached()
    public static let shared = Shared()
    public static let singleton = Cached()

    public final class Cached: SharedFactory.Scope {
        public override init() {}
        public override func reset() {
            defer { lock.unlock() }
            lock.lock()
            cache = [:]
        }
        fileprivate override func cached<T>(_ id: Int) -> T? {
            defer { lock.unlock() }
            lock.lock()
            return cache[id] as? T
        }
        fileprivate override func cache(id: Int, instance: Any) {
            defer { lock.unlock() }
            lock.lock()
            cache[id] = instance
        }
        fileprivate override func reset(_ id: Int) {
            defer { lock.unlock() }
            lock.lock()
            cache.removeValue(forKey: id)
        }
        private var cache = [Int:Any](minimumCapacity: 32)
        private var lock = NSRecursiveLock()
    }

    public final class Shared: SharedFactory.Scope {
        public override init() {}
        public override func reset() {
            defer { lock.unlock() }
            lock.lock()
            cache = [:]
        }
        fileprivate override func cached<T>(_ id: Int) -> T? {
            defer { lock.unlock() }
            lock.lock()
            return cache[id]?.instance as? T
        }
        fileprivate override func cache(id: Int, instance: Any) {
            defer { lock.unlock() }
            lock.lock()
            cache[id] = WeakBox(instance: instance as AnyObject)
        }
        fileprivate override func reset(_ id: Int) {
            defer { lock.unlock() }
            lock.lock()
            cache.removeValue(forKey: id)
        }
        private struct WeakBox {
            weak var instance: AnyObject?
        }
        private var cache = [Int:WeakBox](minimumCapacity: 32)
        private var lock = NSRecursiveLock()
    }

}

@propertyWrapper public struct Injected<T> {
    private var factory:  SharedFactory.Factory<T>
    private var dependency: T
    public init(_ factory: SharedFactory.Factory<T>) {
        self.dependency = factory()
        self.factory = factory
    }
    public var wrappedValue: T {
        get { return dependency }
        mutating set { dependency = newValue }
    }
    public var projectedValue: SharedFactory.Factory<T> {
        get { return factory }
    }
}

@propertyWrapper public struct LazyInjected<T> {
    private var factory:  SharedFactory.Factory<T>
    private var dependency: T!
    public init(_ factory: SharedFactory.Factory<T>) {
        self.factory = factory
    }
    public var wrappedValue: T {
        mutating get {
            if dependency == nil {
                dependency = factory()
            }
            return dependency
        }
        mutating set {
            dependency = newValue
        }
    }
    public var projectedValue: SharedFactory.Factory<T> {
        get { return factory }
    }
}
