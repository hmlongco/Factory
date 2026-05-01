import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct DependencyMacro: MemberMacro {

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let args = node.arguments?.as(LabeledExprListSyntax.self),
              let first = args.first(where: { $0.label == nil }),
              let keyPath = first.expression.as(KeyPathExprSyntax.self)
        else {
            throw MacroError("@Dependency requires a key path argument — e.g. @Dependency(\\.myService)")
        }

        guard let propName = keyPath.components
            .compactMap({ $0.component.as(KeyPathPropertyComponentSyntax.self)?.declName.baseName.text })
            .last
        else {
            throw MacroError("@Dependency could not determine the property name from the key path")
        }

        let container = keyPath.root?.trimmedDescription ?? "Container"
        let mode      = parseMode(from: node)

        let isObservable = declaration.attributes.contains { attr in
            guard let custom = attr.as(AttributeSyntax.self) else { return false }
            return custom.attributeName.trimmedDescription == "Observable"
        }

        let isView = declaration.inheritanceClause?.inheritedTypes.contains { type in
            type.type.trimmedDescription == "View"
        } ?? false

        let call = "\(container).shared.\(propName)()"

        // View structs need @State so SwiftUI owns the storage across render passes.
        // @Observable classes need @ObservationIgnored to opt stored properties out of tracking.
        let prefix = isView ? "@State " : (isObservable ? "@ObservationIgnored " : "")

        let decl: DeclSyntax
        if isView {
            if mode == "lazy" || mode == "weak" {
                throw MacroError("@Dependency(mode: .\(mode)) is not supported on a SwiftUI View — use the default mode and @State storage instead")
            }
            decl = "\(raw: prefix)internal var \(raw: propName) = \(raw: call)"
        } else {
            switch mode {
            case "lazy":
                decl = "\(raw: prefix)internal lazy var \(raw: propName) = \(raw: call)"
            case "optional":
                decl = "\(raw: prefix)internal var \(raw: propName) = _wrapOptional(\(raw: call))"
            case "weak":
                decl = "\(raw: prefix)internal weak var \(raw: propName) = \(raw: call)"
            default: // immediate, dynamic
                decl = "\(raw: prefix)internal var \(raw: propName) = \(raw: call)"
            }
        }

        return [decl]
    }

    private static func parseMode(from node: AttributeSyntax) -> String {
        guard let args = node.arguments?.as(LabeledExprListSyntax.self) else { return "immediate" }
        for arg in args where arg.label?.text == "mode" {
            let raw = arg.expression.trimmedDescription
            if raw.hasSuffix("lazy")     { return "lazy" }
            if raw.hasSuffix("dynamic")  { return "dynamic" }
            if raw.hasSuffix("optional") { return "optional" }
            if raw.hasSuffix("weak")     { return "weak" }
        }
        return "immediate"
    }
}

private struct MacroError: Error, CustomStringConvertible {
    let description: String
    init(_ description: String) { self.description = description }
}
