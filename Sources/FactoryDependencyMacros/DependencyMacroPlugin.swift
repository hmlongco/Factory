import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct FactoryDependencyMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        DependencyMacro.self,
    ]
}
