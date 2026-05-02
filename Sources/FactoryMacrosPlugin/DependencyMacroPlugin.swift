import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct FactoryMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        DependencyMacro.self,
    ]
}
