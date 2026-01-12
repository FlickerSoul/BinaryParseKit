//
//  MacroConfigurationVisitor.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/26/25.
//

import BinaryParseKitCommons
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

enum MacroConfigurationError: DiagnosticMessage, Error {
    case invalidAccessor(String)
    case moreThanOneModifier(modifiers: String)
    case unknownAccessor
    case invalidBitEndian(String)

    var message: String {
        switch self {
        case let .invalidAccessor(accessor):
            #"Invalid ACL value: \#(accessor); Please use one of \#(ExtensionAccessor.allowedCases.map(\.description).joined(separator: ", ")); use it in string literal "public" or enum member access .public."#
        case let .moreThanOneModifier(modifiers: modifiers):
            "More than one modifier found: \(modifiers). Only one modifier is allowed."
        case .unknownAccessor:
            "You have used unknown accessor in `@ParseStruct` or `@ParseEnum`."
        case let .invalidBitEndian(value):
            #"Invalid bitEndian value: \#(value); Please use .big or .little."#
        }
    }

    var diagnosticID: SwiftDiagnostics.MessageID {
        .init(
            domain: "observer.universe.BinaryParseKit.MacroACLError",
            id: "\(self)",
        )
    }

    var severity: SwiftDiagnostics.DiagnosticSeverity {
        switch self {
        case .invalidAccessor, .moreThanOneModifier, .unknownAccessor, .invalidBitEndian: .error
        }
    }
}

class MacroConfigurationVisitor: SyntaxVisitor {
    private static let defaultAccessor = ExtensionAccessor.follow

    private(set) var printingAccessor: ExtensionAccessor = MacroConfigurationVisitor.defaultAccessor
    private(set) var parsingAccessor: ExtensionAccessor = MacroConfigurationVisitor.defaultAccessor
    /// The bit endian value: "big" or "little". Defaults to "big".
    private(set) var bitEndian: String = "big"

    private let context: any MacroExpansionContext

    init(context: any MacroExpansionContext) {
        self.context = context
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: LabeledExprSyntax) -> SyntaxVisitorContinueKind {
        let labelText = node.label?.text
        do {
            switch labelText {
            case "printingAccessor":
                try setACL(to: \.printingAccessor, with: node)
            case "parsingAccessor":
                try setACL(to: \.parsingAccessor, with: node)
            case "bitEndian":
                try setBitEndian(with: node)
            default:
                break
            }
        } catch {
            context.diagnose(.init(node: node, message: error))
        }

        return .skipChildren
    }

    private func setBitEndian(with node: LabeledExprSyntax) throws(MacroConfigurationError) {
        let expression = node.expression
        guard let memberAccessSyntax = expression.as(MemberAccessExprSyntax.self) else {
            throw MacroConfigurationError.invalidBitEndian(expression.description)
        }
        guard memberAccessSyntax.base == nil else {
            throw MacroConfigurationError.invalidBitEndian(expression.description)
        }

        let value = memberAccessSyntax.declName.baseName.text
        guard value == "big" || value == "little" else {
            throw MacroConfigurationError.invalidBitEndian(value)
        }
        bitEndian = value
    }

    private func setACL(
        to keypath: ReferenceWritableKeyPath<MacroConfigurationVisitor, ExtensionAccessor>,
        with node: LabeledExprSyntax,
    ) throws(MacroConfigurationError) {
        let acl = parseACL(from: node)
        self[keyPath: keypath] = acl
        if case let .unknown(value) = acl {
            throw MacroConfigurationError.invalidAccessor(value)
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
    /// The bit endian value: "big" or "little".
    let bitEndian: String

    /// Whether bit parsing should use big endian (MSB-first).
    var isBigEndian: Bool { bitEndian == "big" }
}

private let allAccessModifiers: Set<TokenKind> = [
    .keyword(.private),
    .keyword(.fileprivate),
    .keyword(.internal),
    .keyword(.package),
    .keyword(.public),
]
private let defaultAccessModifier: TokenKind = .keyword(.internal)

func extractMacroConfiguration(
    from attributeNode: AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    in context: some MacroExpansionContext,
) throws(MacroConfigurationError) -> AccessorInfo {
    let accessModifiers = declaration.modifiers
        .filter { modifier in
            allAccessModifiers.contains(modifier.name.tokenKind)
        }

    guard accessModifiers.count < 2 else {
        throw MacroConfigurationError
            .moreThanOneModifier(modifiers: accessModifiers.map(\.name.text).joined(separator: ", "))
    }

    let modifierToken = accessModifiers.first?.name.tokenKind ?? defaultAccessModifier

    let accessorVisitor = MacroConfigurationVisitor(context: context)
    accessorVisitor.walk(attributeNode)

    guard let parsingAccessor = accessorVisitor.parsingAccessor.getAccessorToken(defaultAccessor: modifierToken),
          let printingAccessor = accessorVisitor.printingAccessor.getAccessorToken(defaultAccessor: modifierToken)
    else {
        throw MacroConfigurationError.unknownAccessor
    }

    return .init(
        parsingAccessor: .init(
            name: TokenSyntax(parsingAccessor, presence: .present),
        ),
        printingAccessor: .init(
            name: TokenSyntax(printingAccessor, presence: .present),
        ),
        bitEndian: accessorVisitor.bitEndian,
    )
}
