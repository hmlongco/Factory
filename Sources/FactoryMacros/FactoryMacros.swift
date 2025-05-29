// The Swift Programming Language
// https://docs.swift.org/swift-book

@_exported import FactoryKit

@attached(accessor, names: arbitrary)
@attached(peer, names: arbitrary)
public macro DefineFactory<T>(_ factory: @escaping () -> T, scope: Scope? = nil) = #externalMacro(
    module: "FactoryMacrosImplementation",
    type: "DefineFactoryMacro"
)

//@attached(accessor, names: arbitrary)
//@attached(peer, names: arbitrary)
//public macro DefineParameterFactory(scope: Scope? = nil) = #externalMacro(
//    module: "FactoryMacrosImplementation",
//    type: "DefineParameterFactoryMacro"
//)
