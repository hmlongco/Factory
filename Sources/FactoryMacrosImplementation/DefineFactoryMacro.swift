import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct DefineFactoryMacro: AccessorMacro, PeerMacro, FactoryMacroExtensions {

    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingAccessorsOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.AccessorDeclSyntax] {

        guard let varDecl = declaration.as(VariableDeclSyntax.self),
              let binding = varDecl.bindings.first
        else {
            throw FactoryMacroError.invalid
        }

        guard !isExplicitlyActorIsolated(varDecl) else {
            throw FactoryMacroError.isolated
        }

        let name = try identifier(from: binding)

        let accessor = """
        get { $\(name)() }
        """

        return [AccessorDeclSyntax(stringLiteral: accessor)]
    }

    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {

        guard let varDecl = declaration.as(VariableDeclSyntax.self),
              let binding = varDecl.bindings.first
        else {
            throw FactoryMacroError.invalid
        }

        guard !isExplicitlyActorIsolated(varDecl) else {
            throw FactoryMacroError.isolated
        }

        let name = try identifier(from: binding)
        let type = try type(from: binding)

        // let attributes = attributes(from: varDecl)
        let modifiers = modifiers(from: varDecl)

        var closure: String?
        var scope: String = ""

        if let args = node.arguments?.as(LabeledExprListSyntax.self) {
            for arg in args {
                let label = arg.label?.text
                let value = arg.expression.description.trimmingCharacters(in: .whitespacesAndNewlines)

                if label == nil {
                    closure = value
                } else if label == "scope" {
                    scope = KnownScopes.set.contains(value) ? "\n\(value)" : "\n.scope(\(value))"
                }
            }
        }

        guard let closure else {
            throw FactoryMacroError.closure
        }

        let factory = """
        \(modifiers)var $\(name): Factory<\(type)> {
            Factory<\(type)>(self) \(closure)\(scope)
        }
        """

        return [DeclSyntax(stringLiteral: factory)]
    }

}
