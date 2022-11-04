//
//  InjectedObject.swift
//  FactoryDemo
//
//  Created by Michael Long on 11/4/22.
//

import SwiftUI
import Factory

#if os(iOS) || os(macOS) || os(tvOS) || os(watchOS)
/// Immediate injection property wrapper for SwiftUI ObservableObjects. This wrapper is meant for use in SwiftUI Views and exposes
/// bindable objects similar to that of SwiftUI @observedObject and @environmentObject.
///
/// Dependent service must be of type ObservableObject. Updating object state will trigger view update.
///
@available(OSX 10.15, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
@propertyWrapper public struct InjectedObject<T>: DynamicProperty where T: ObservableObject {
    @StateObject private var dependency: T
    public init(_ factory: Factory<T>) {
        self._dependency = StateObject(wrappedValue: factory())
    }
    @MainActor public var wrappedValue: T {
        get { return dependency }
    }
    @MainActor public var projectedValue: ObservedObject<T>.Wrapper {
        return self.$dependency
    }
}
#endif
