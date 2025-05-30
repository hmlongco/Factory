//
//  MirrorFactoryMacro.swift
//  Factory
//
//  Created by Michael Long on 5/30/25.
//


import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct MirrorFactoryMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {

        guard let varDecl = declaration.as(VariableDeclSyntax.self),
              let binding = varDecl.bindings.first else {
            throw FactoryMacroError.invalid
        }

        let originalName = try identifier(from: binding)

        // Enforce convention: original should start with underscore _
        guard originalName.hasPrefix("_") else {
            throw FactoryMacroError.message("@MirrorFactory expects the original property to be prefixed with '_' (underscore)")
        }

        let mirrorName = String(originalName.dropFirst()) // remove leading _
        let returnType = try extractFactoryReturnType(from: binding)

        let mirror = """
        var \(mirrorName): \(returnType) {
            \(originalName)()
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
