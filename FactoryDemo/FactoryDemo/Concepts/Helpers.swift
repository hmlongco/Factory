//
//  Helpers.swift
//  FactoryDemo
//
//  Created by Michael Long on 2/4/23.
//

import Foundation
import Factory

//    /// Makes a Factory with cached scope.
//    @inlinable public func cached<T>(key: String = #function, _ factory: @escaping () -> T) -> Factory<T> {
//        Factory(self, key: key, scope: .cached, factory)
//    }
//    /// Makes a Factory with graph scope.
//    @inlinable public func graph<T>(key: String = #function, _ factory: @escaping () -> T) -> Factory<T> {
//        Factory(self, key: key, scope: .graph, factory)
//    }
//    /// Makes a Factory with a custom scope.
//    @inlinable public func scope<T>(_ scope: Scope, key: String = #function, _ factory: @escaping () -> T) -> Factory<T> {
//        Factory(self, key: key, scope: scope, factory)
//    }
//    /// Makes a Factory with shared scope.
//    @inlinable public func shared<T>(key: String = #function, _ factory: @escaping () -> T) -> Factory<T> {
//        Factory(self, key: key, scope: .shared, factory)
//    }
//    /// Makes a Factory with singleton scope.
//    @inlinable public func singleton<T>(key: String = #function, _ factory: @escaping () -> T) -> Factory<T> {
//        Factory(self, key: key, scope: .singleton, factory)
//    }
//    /// Makes a Factory with unique scope.
//    @inlinable public func unique<T>(key: String = #function, _ factory: @escaping () -> T) -> Factory<T> {
//        Factory(self, key: key, scope: .none, factory)
//    }
//    /// Makes a ParameterFactory with cached scope.
//    @inlinable public func cached<P,T>(key: String = #function, _ parameterFactory: @escaping (P) -> T) -> ParameterFactory<P,T> {
//        ParameterFactory(self, key: key, scope: .cached, parameterFactory)
//    }
//    /// Makes a ParameterFactory with graph scope.
//    @inlinable public func graph<P,T>(key: String = #function, _ parameterFactory: @escaping (P) -> T) -> ParameterFactory<P,T> {
//        ParameterFactory(self, key: key, scope: .graph, parameterFactory)
//    }
//    /// Makes a ParameterFactory with a custom scope.
//    @inlinable public func scope<P,T>(_ scope: Scope, key: String = #function, _ parameterFactory: @escaping (P) -> T) -> ParameterFactory<P,T> {
//        ParameterFactory(self, key: key, scope:scope , parameterFactory)
//    }
//    /// Makes a ParameterFactory with shared scope.
//    @inlinable public func shared<P,T>(key: String = #function, _ parameterFactory: @escaping (P) -> T) -> ParameterFactory<P,T> {
//        ParameterFactory(self, key: key, scope: .shared, parameterFactory)
//    }
//    /// Makes a ParameterFactory with singleton scope.
//    @inlinable public func singleton<P,T>(key: String = #function, _ parameterFactory: @escaping (P) -> T) -> ParameterFactory<P,T> {
//        ParameterFactory(self, key: key, scope: .singleton, parameterFactory)
//    }
//    /// Makes a ParameterFactory with unique scope.
//    @inlinable public func unique<P,T>(key: String = #function, _ parameterFactory: @escaping (P) -> T) -> ParameterFactory<P,T> {
//        ParameterFactory(self, key: key, scope: .none, parameterFactory)
//    }
