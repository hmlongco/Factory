//
//  FactoryMacroExtensions.swift
//  FactoryMacros
//
//  Created by Michael Long on 5/25/25.
//

import Foundation
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

protocol FactoryMacroExtensions { }

extension FactoryMacroExtensions {

    static func isExplicitlyActorIsolated(_ decl: VariableDeclSyntax) -> Bool {
        actor(from: decl) != nil
    }

    static func actor(from decl: VariableDeclSyntax) -> String? {
        decl
            .attributes
            .first(where: { $0.description.trimmingCharacters(in: .whitespacesAndNewlines).hasSuffix("Actor") })?
            .description
    }

    static func attributes(from decl: VariableDeclSyntax) -> String {
        let preserved = decl
            .attributes
            .compactMap { (attr) -> String? in
                switch attr.kind {
                case .availabilityCondition:
                    return attr.trimmedDescription
                case .attribute:
                    let d = attr.trimmedDescription
                    if d.hasPrefix("@MirrorFactory") || d.hasPrefix("@DefineFactory") || d.hasPrefix("@DefineParameterFactory") {
                        return nil
                    } else {
                        return d
                    }
                default:
                    return nil
                }
            }
            .joined(separator: "\n")
        return preserved.isEmpty ? "" : preserved.appending("\n")
    }

    static func block(from decl: VariableDeclSyntax) throws -> String {
        guard let block = decl
            .bindings
            .first?
            .accessorBlock?
            .description
            .trimmingCharacters(in: .whitespacesAndNewlines)
        else {
            throw FactoryMacroError.type
        }
        return block
    }

    static func identifier(from binding: PatternBindingSyntax) throws -> String {
        guard let identifier = binding
            .pattern
            .as(IdentifierPatternSyntax.self)?
            .identifier
            .text
        else {
            throw FactoryMacroError.type
        }
        return identifier
    }

    static func modifiers(from decl: VariableDeclSyntax) -> String {
        let modifiers = decl
            .modifiers
            .map {
                $0.description.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .joined(separator: " ")
        return modifiers.isEmpty ? "" : modifiers.appending(" ")
    }

    static func scope(from node: SwiftSyntax.AttributeSyntax) -> String {
        guard let extracted = node.arguments?
            .as(LabeledExprListSyntax.self)?
            .first?
            .description
            .split(separator: ":")
            .last?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        else {
            return ""
        }
        return KnownScopes.set.contains(extracted) ? "\n\(extracted)" : "\n.scope(\(extracted))"
    }

    static func type(from binding: PatternBindingSyntax) throws -> String {
        guard let type = binding
            .typeAnnotation?
            .type
            .description
            .trimmingCharacters(in: .whitespacesAndNewlines)
        else {
            throw FactoryMacroError.type
        }
        return type
    }

}

internal enum KnownScopes: String, CaseIterable {
    case cached
    case graph
    case shared
    case singleton
    case unique
    static let set: Set<String> = .init(Self.allCases.map({ ".\($0)" }))
}

internal enum ExcludedAttributes: String, CaseIterable {
    case DefineFactory
    case DefineParameterFactory
    static let set: Set<String> = .init(Self.allCases.map({ "@\($0)" }))
}
