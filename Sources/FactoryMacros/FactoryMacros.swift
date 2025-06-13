// The Swift Programming Language
// https://docs.swift.org/swift-book

@_exported import FactoryKit

@attached(accessor, names: arbitrary)
@attached(peer, names: arbitrary)
public macro DefineFactory<T>(_ factory: @escaping () -> T, scope: Scope? = nil) = #externalMacro(
    module: "FactoryMacrosImplementation",
    type: "DefineFactoryMacro"
)

@attached(peer, names: arbitrary)
public macro MirrorFactory() = #externalMacro(
    module: "FactoryMacrosImplementation",
    type: "MirrorFactoryMacro"
)

//@attached(accessor, names: arbitrary)
//@attached(peer, names: arbitrary)
//public macro DefineParameterFactory(scope: Scope? = nil) = #externalMacro(
//    module: "FactoryMacrosImplementation",
//    type: "DefineParameterFactoryMacro"
//)

// @attached(extension, conformances: SharedContainer)
//@attached(member, names: named(init), named(manager), named(shared))
//public macro DefineCustomContainer() = #externalMacro(
//    module: "FactoryMacrosImplementation",
//    type: "DefineCustomContainerMacro"
//)
