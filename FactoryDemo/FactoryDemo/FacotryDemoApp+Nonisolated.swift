//
//  FacotryDemoApp+Nonisolated.swift
//  FactoryDemo
//
//  Created by Michael Long on 12/26/25.
//

import Foundation
import FactoryKit
import Common
import SwiftUI

nonisolated final class NonisolatedNetworkService0 {
    // @Injected(\.preferences) var preferences // FAILS: 'nonisolated' is not supported on properties with property wrappers
    func load() {}
}

nonisolated final class SharedContainerNetworkService {
    let preferences = Container.shared.preferences()
    func load() {}
}

nonisolated final class PassedContainerNetworkService {
    let preferences: Preferences
    init(_ container: Container = Container.shared) {
        preferences = container.preferences()
    }
    func load() {}
}

nonisolated final class DependencyFunctionNetworkService {
    let preferences: Preferences = resolve(\.preferences)
    func load() {}
}

protocol PreferencesProviding {
    var preferences: Factory<Preferences> { get }
}

extension Container: PreferencesProviding {}

nonisolated final class PassedProtocolNetworkService {
    let preferences: Preferences
    init(_ provider: PreferencesProviding = Container.shared) {
        preferences = provider.preferences()
    }
    func load() {}
}

nonisolated final class FancyWayToAvoidSharedNetworkService {
    let preferences: Preferences = { Injected(\.preferences).wrappedValue }()
    func load() {}
}
