//
//  MirrorFactoryMacro.swift
//  Factory
//
//  Created by Michael Long on 5/30/25.
//


import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct MirrorFactoryMacro: PeerMacro, FactoryMacroExtensions {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {

        guard let varDecl = declaration.as(VariableDeclSyntax.self),
              let binding = varDecl.bindings.first else {
            throw FactoryMacroError.invalid
        }

        let name = try identifier(from: binding)
        let type = try type(from: binding)

        let attributes = attributes(from: varDecl)
        let modifiers = modifiers(from: varDecl)

        let mirror = """
        \(attributes)\(modifiers)var $\(name): Factory<\(type)> {
            Factory<\(type)>(self, key: "\(name)") { [unowned self] in self.\(name) }
        }
        """

        return [DeclSyntax(stringLiteral: mirror)]
    }
}

// Utility helpers and error type
func identifier(from binding: PatternBindingSyntax) throws -> String {
    guard let ident = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
        throw FactoryMacroError.identifier
    }
    return ident
}

func extractFactoryReturnType(from binding: PatternBindingSyntax) throws -> String {
    guard let annotation = binding.typeAnnotation?.type.as(IdentifierTypeSyntax.self),
          annotation.name.text == "Factory",
          let genericArgs = annotation.genericArgumentClause?.arguments,
          let returnType = genericArgs.last?.description.trimmingCharacters(in: .whitespacesAndNewlines) else {
        throw FactoryMacroError.message("@MirrorFactory expects a Factory<T> type")
    }
    return returnType
}
