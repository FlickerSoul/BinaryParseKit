//
//  MacroAccessorVisitor.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/26/25.
//

import BinaryParseKitCommons
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

enum MacroAccessorError: DiagnosticMessage, Error {
    case invalidAccessor(String)
    case moreThanOneModifier(modifiers: String)
    case unknownAccessor

    var message: String {
        switch self {
        case let .invalidAccessor(accessor):
            #"Invalid ACL value: \#(accessor); Please use one of \#(ExtensionAccessor.allowedCases.map(\.description).joined(separator: ", ")); use it in string literal "public" or enum member access .public."#
        case let .moreThanOneModifier(modifiers: modifiers):
            "More than one modifier found: \(modifiers). Only one modifier is allowed."
        case .unknownAccessor:
            "You have used unknown accessor in `@ParseStruct` or `@ParseEnum`."
        }
    }

    var diagnosticID: SwiftDiagnostics.MessageID {
        .init(
            domain: "BinaryParseKit.MacroACLError",
            id: "\(self)",
        )
    }

    var severity: SwiftDiagnostics.DiagnosticSeverity {
        switch self {
        case .invalidAccessor, .moreThanOneModifier, .unknownAccessor: .error
        }
    }
}

class MacroAccessorVisitor: SyntaxVisitor {
    private static let defaultAccessor = ExtensionAccessor.follow

    private(set) var printingAccessor: ExtensionAccessor = MacroAccessorVisitor.defaultAccessor
    private(set) var parsingAccessor: ExtensionAccessor = MacroAccessorVisitor.defaultAccessor

    private let context: any MacroExpansionContext

    init(context: any MacroExpansionContext) {
        self.context = context
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: LabeledExprSyntax) -> SyntaxVisitorContinueKind {
        let labelText = node.label?.text
        switch labelText {
        case "printingAccessor":
            setACL(to: \.printingAccessor, with: node)
        case "parsingAccessor":
            setACL(to: \.parsingAccessor, with: node)
        default:
            break
        }
        return .skipChildren
    }

    private func setACL(
        to keypath: ReferenceWritableKeyPath<MacroAccessorVisitor, ExtensionAccessor>,
        with node: LabeledExprSyntax,
    ) {
        let acl = parseACL(from: node)
        self[keyPath: keypath] = acl
        if case let .unknown(value) = acl {
            context.diagnose(
                .init(
                    node: node,
                    message: MacroAccessorError.invalidAccessor(value),
                ),
            )
        }
    }

    private func parseACL(from node: LabeledExprSyntax) -> ExtensionAccessor {
        let expression = node.expression

        // FIXME: use macro toolkit
        if let stringLiteralSyntax = expression.as(StringLiteralExprSyntax.self),
           let stringLiteral = stringLiteralSyntax.segments.first?.as(StringSegmentSyntax.self)?.content.text {
            return .init(unicodeScalarLiteral: stringLiteral)
        } else if let memberAccessSyntax = expression.as(MemberAccessExprSyntax.self) {
            let element = memberAccessSyntax.declName.baseName.text
            return .init(unicodeScalarLiteral: element)
        }

        return .unknown(expression.description)
    }
}

struct AccessorInfo {
    let parsingAccessor: DeclModifierSyntax
    let printingAccessor: DeclModifierSyntax
}

func extractAccessor(
    from attributeNode: AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    in context: some MacroExpansionContext,
) throws(MacroAccessorError) -> AccessorInfo {
    let modifiers = declaration.modifiers
    guard modifiers.count < 2 else {
        throw MacroAccessorError.moreThanOneModifier(modifiers: modifiers.map(\.name.text).joined(separator: ", "))
    }
    let modifierToken = modifiers.first?.name.tokenKind ?? .keyword(.internal)

    let accessorVisitor = MacroAccessorVisitor(context: context)
    accessorVisitor.walk(attributeNode)

    guard let parsingAccessor = accessorVisitor.parsingAccessor.getAccessorToken(defaultAccessor: modifierToken),
          let printingAccessor = accessorVisitor.printingAccessor.getAccessorToken(defaultAccessor: modifierToken)
    else {
        throw MacroAccessorError.unknownAccessor
    }

    return .init(
        parsingAccessor: .init(
            name: TokenSyntax(parsingAccessor, presence: .present),
        ),
        printingAccessor: .init(
            name: TokenSyntax(printingAccessor, presence: .present),
        ),
    )
}
