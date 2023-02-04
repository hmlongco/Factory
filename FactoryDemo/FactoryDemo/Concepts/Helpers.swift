//
//  Helpers.swift
//  FactoryDemo
//
//  Created by Michael Long on 2/4/23.
//

import Foundation
import Factory

extension SharedContainer {

    // Container Scope Helpers

    /// Makes a Factory with cached scope.
    public func cached<T>(key: String = #function, _ factory: @escaping () -> T) -> Factory<T> {
        Factory(self, key: key, factory).cached
    }
    /// Makes a Factory with a custome scope.
    public func custom<T>(scope: Scope, key: String = #function, _ factory: @escaping () -> T) -> Factory<T> {
        Factory(self, key: key, factory).custom(scope: scope)
    }
    /// Makes a Factory with graph scope.
    public func graph<T>(key: String = #function, _ factory: @escaping () -> T) -> Factory<T> {
        Factory(self, key: key, factory).graph
    }
    /// Makes a Factory with shared scope.
    public func shared<T>(key: String = #function, _ factory: @escaping () -> T) -> Factory<T> {
        Factory(self, key: key, factory).shared
    }
    /// Makes a Factory with singleton scope.
    public func singleton<T>(key: String = #function, _ factory: @escaping () -> T) -> Factory<T> {
        Factory(self, key: key, factory).singleton
    }
    /// Makes a Factory with unique scope.
    public func unique<T>(key: String = #function, _ factory: @escaping () -> T) -> Factory<T> {
        Factory(self, key: key, factory)
    }
    /// Makes a ParameterFactory with cached scope.
    public func cached<P,T>(key: String = #function, _ parameterFactory: @escaping (P) -> T) -> ParameterFactory<P,T> {
        ParameterFactory(self, key: key, parameterFactory).cached
    }
    /// Makes a ParameterFactory with a custome scope.
    public func custom<P,T>(scope: Scope, key: String = #function, _ parameterFactory: @escaping (P) -> T) -> ParameterFactory<P,T> {
        ParameterFactory(self, key: key, parameterFactory).custom(scope: scope)
    }
    /// Makes a ParameterFactory with graph scope.
    public func graph<P,T>(key: String = #function, _ parameterFactory: @escaping (P) -> T) -> ParameterFactory<P,T> {
        ParameterFactory(self, key: key, parameterFactory).graph
    }
    /// Makes a ParameterFactory with shared scope.
    public func shared<P,T>(key: String = #function, _ parameterFactory: @escaping (P) -> T) -> ParameterFactory<P,T> {
        ParameterFactory(self, key: key, parameterFactory).shared
    }
    /// Makes a ParameterFactory with singleton scope.
    public func singleton<P,T>(key: String = #function, _ parameterFactory: @escaping (P) -> T) -> ParameterFactory<P,T> {
        ParameterFactory(self, key: key, parameterFactory).singleton
    }
    /// Makes a ParameterFactory with unique scope.
    public func unique<P,T>(key: String = #function, _ parameterFactory: @escaping (P) -> T) -> ParameterFactory<P,T> {
        ParameterFactory(self, key: key, parameterFactory)
    }

    // Static Scope Helpers

    /// Makes a Factory with cached scope.
    public static func cached<T>(key: String = #function, _ factory: @escaping () -> T) -> Factory<T> {
        Factory(shared, key: key, factory).cached
    }
    /// Makes a Factory with a custome scope.
    public static func custom<T>(scope: Scope, key: String = #function, _ factory: @escaping () -> T) -> Factory<T> {
        Factory(shared, key: key, factory).custom(scope: scope)
    }
    /// Makes a Factory with graph scope.
    public static func graph<T>(key: String = #function, _ factory: @escaping () -> T) -> Factory<T> {
        Factory(shared, key: key, factory).graph
    }
    /// Makes a Factory with shared scope.
    public static func shared<T>(key: String = #function, _ factory: @escaping () -> T) -> Factory<T> {
        Factory(shared, key: key, factory).shared
    }
    /// Makes a Factory with singleton scope.
    public static func singleton<T>(key: String = #function, _ factory: @escaping () -> T) -> Factory<T> {
        Factory(shared, key: key, factory).singleton
    }
    /// Makes a Factory with unique scope.
    public static func unique<T>(key: String = #function, _ factory: @escaping () -> T) -> Factory<T> {
        Factory(shared, key: key, factory)
    }
    /// Makes a ParameterFactory with cached scope.
    public static func cached<P,T>(key: String = #function, _ parameterFactory: @escaping (P) -> T) -> ParameterFactory<P,T> {
        ParameterFactory(shared, key: key, parameterFactory).cached
    }
    /// Makes a ParameterFactory with a custome scope.
    public static func custom<P,T>(scope: Scope, key: String = #function, _ parameterFactory: @escaping (P) -> T) -> ParameterFactory<P,T> {
        ParameterFactory(shared, key: key, parameterFactory).custom(scope: scope)
    }
    /// Makes a ParameterFactory with graph scope.
    public static func graph<P,T>(key: String = #function, _ parameterFactory: @escaping (P) -> T) -> ParameterFactory<P,T> {
        ParameterFactory(shared, key: key, parameterFactory).graph
    }
    /// Makes a ParameterFactory with shared scope.
    public static func shared<P,T>(key: String = #function, _ parameterFactory: @escaping (P) -> T) -> ParameterFactory<P,T> {
        ParameterFactory(shared, key: key, parameterFactory).shared
    }
    /// Makes a ParameterFactory with singleton scope.
    public static func singleton<P,T>(key: String = #function, _ parameterFactory: @escaping (P) -> T) -> ParameterFactory<P,T> {
        ParameterFactory(shared, key: key, parameterFactory).singleton
    }
    /// Makes a ParameterFactory with unique scope.
    public static func unique<P,T>(key: String = #function, _ parameterFactory: @escaping (P) -> T) -> ParameterFactory<P,T> {
        ParameterFactory(shared, key: key, parameterFactory)
    }

}
