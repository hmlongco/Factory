import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct DefineParameterFactoryMacro: AccessorMacro, PeerMacro, FactoryMacroExtensions {

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

        let name = try identifier(from: binding)

        let accessor = """
        get { { self.$\(name)($0) } }
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

        let name = try identifier(from: binding)
        let rType = try type(from: binding)

        let attributes = attributes(from: varDecl)
        let modifiers = modifiers(from: varDecl)

        var closure: String?
        var scope: String = ""

        if let args = node.arguments?.as(LabeledExprListSyntax.self) {
            for arg in args {
                let label = arg.label?.text
                let value = arg.expression.description.trimmingCharacters(in: .whitespacesAndNewlines)

                if label == "parameterFactory" {
                    closure = value
                } else if label == "scope" {
                    scope = KnownScopes.set.contains(value) ? "\n\(value)" : "\n.scope(\(value))"
                }
            }
        }

        guard let closure else {
            throw FactoryMacroError.closure
        }

//        guard let function = binding.typeAnnotation?.type.as(FunctionTypeSyntax.self),
//              let pType = function.parameters.first?.type.description.trimmingCharacters(in: .whitespacesAndNewlines)
//        else {
//            throw FactoryMacroError.parameterized
//        }

        let pType = "Int"

        let factory = """
        \(attributes)\(modifiers)var $\(name): ParameterFactory<\(pType), \(rType)> {
            ParameterFactory<\(pType), \(rType)>(self) \(closure)\(scope)
        }
        """

        return [DeclSyntax(stringLiteral: factory)]
    }
}
