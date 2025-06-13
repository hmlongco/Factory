//
//  DefineCustomContainerMacro.swift
//  Factory
//
//  Created by Michael Long on 6/6/25.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct DefineCustomContainerMacro: MemberMacro /*, ExtensionMacro */ {

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {

        guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
            throw FactoryMacroError.class
        }

        let className = classDecl.name.text

        let initializer = DeclSyntax(stringLiteral: """
        public init() {}
        """)

        let manager = DeclSyntax(stringLiteral: """
        public let manager = ContainerManager()
        """)

        let shared = DeclSyntax(stringLiteral: """
        public static var shared = \(className)()
        """)

        return [initializer, manager, shared]
    }

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {

        guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
            throw FactoryMacroError.class
        }

        let className = classDecl.name.text

        let inheritanceClause = InheritanceClauseSyntax(
            inheritedTypes: InheritedTypeListSyntax {
                InheritedTypeSyntax(type: TypeSyntax(stringLiteral: "SharedContainer"))
            }
        )

        let memberBlock = MemberBlockSyntax(members: MemberBlockItemListSyntax([]))

        let extensionDecl = ExtensionDeclSyntax(
            extendedType: TypeSyntax(stringLiteral: className),
            inheritanceClause: inheritanceClause,
            memberBlock: memberBlock
        )

        return [extensionDecl]
    }

}
