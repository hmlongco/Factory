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
        let varName   = parseName(from: node) ?? propName

        let isObservable = declaration.attributes.contains { attr in
            guard let custom = attr.as(AttributeSyntax.self) else { return false }
            return custom.attributeName.trimmedDescription == "Observable"
        }

        let isView = declaration.inheritanceClause?.inheritedTypes.contains { type in
            type.type.trimmedDescription == "View"
        } ?? false

        let call = "\(container).shared.\(propName)()"

        // When `mode:` is omitted, the default depends on context:
        //   inside a SwiftUI View → .observable  (@State storage)
        //   elsewhere             → .immediate   (plain stored property)
        let userMode = parseMode(from: node)
        let mode = userMode ?? (isView ? "observable" : "immediate")

        let observationPrefix = isObservable ? "@ObservationIgnored " : ""

        let decl: DeclSyntax
        switch mode {

        case "observable":
            if isView {
                decl = "@State internal var \(raw: varName) = \(raw: call)"
            } else {
                decl = "\(raw: observationPrefix)internal let \(raw: varName) = \(raw: call)"
            }

        case "observableObject":
            if isView {
                decl = "@StateObject internal var \(raw: varName) = \(raw: call)"
            } else {
                decl = "\(raw: observationPrefix)internal let \(raw: varName) = \(raw: call)"
            }

        case "lazy":
            if isView { throw MacroError("@Dependency(mode: .lazy) is not supported on a SwiftUI View") }
            decl = "\(raw: observationPrefix)internal lazy var \(raw: varName) = \(raw: call)"

        case "weak":
            if isView { throw MacroError("@Dependency(mode: .weak) is not supported on a SwiftUI View") }
            decl = "\(raw: observationPrefix)internal weak var \(raw: varName) = \(raw: call)"

        case "dynamic":
            if isView { throw MacroError("@Dependency(mode: .dynamic) is not supported on a SwiftUI View") }
            // @DynamicDependency captures the factory call as an @autoclosure so the
            // container is queried on every property access, not just at init time.
            let dynPrefix = isObservable ? "@ObservationIgnored @DynamicDependency " : "@DynamicDependency "
            decl = "\(raw: dynPrefix)internal var \(raw: varName) = \(raw: call)"

        case "optional":
            if isView { throw MacroError("@Dependency(mode: .optional) is not supported on a SwiftUI View") }
            decl = "\(raw: observationPrefix)internal var \(raw: varName) = _wrapOptional(\(raw: call))"

        default: // immediate
            decl = "\(raw: observationPrefix)internal let \(raw: varName) = \(raw: call)"
        }

        return [decl]
    }

    private static func parseName(from node: AttributeSyntax) -> String? {
        guard let args = node.arguments?.as(LabeledExprListSyntax.self) else { return nil }
        for arg in args where arg.label?.text == "name" {
            // Accept string literals only; nil literal means no override
            if let segments = arg.expression.as(StringLiteralExprSyntax.self)?.segments,
               case let .stringSegment(seg) = segments.first {
                return seg.content.text
            }
        }
        return nil
    }

    private static func parseMode(from node: AttributeSyntax) -> String? {
        guard let args = node.arguments?.as(LabeledExprListSyntax.self) else { return nil }

        // Mode is declared as `_ mode: DependencyMode? = nil`, so call sites pass it
        // positionally. Prefer an explicit `mode:` label if present (matches the docs
        // and keeps the parser working if the public signature ever requires the label),
        // otherwise take the second unlabeled argument (1st is the keypath).
        let candidate: ExprSyntax? = {
            if let labeled = args.first(where: { $0.label?.text == "mode" }) {
                return labeled.expression
            }
            let positionals = args.filter { $0.label == nil }
            return positionals.dropFirst().first?.expression
        }()

        guard let raw = candidate?.trimmedDescription, raw != "nil" else { return nil }

        // Order matters: the longer suffixes must come first so "observableObject"
        // doesn't get misclassified by an earlier shorter match.
        if raw.hasSuffix("observableObject") { return "observableObject" }
        if raw.hasSuffix("observable")       { return "observable" }
        if raw.hasSuffix("immediate")        { return "immediate" }
        if raw.hasSuffix("lazy")             { return "lazy" }
        if raw.hasSuffix("dynamic")          { return "dynamic" }
        if raw.hasSuffix("optional")         { return "optional" }
        if raw.hasSuffix("weak")             { return "weak" }
        return nil
    }
}

private struct MacroError: Error, CustomStringConvertible {
    let description: String
    init(_ description: String) { self.description = description }
}
