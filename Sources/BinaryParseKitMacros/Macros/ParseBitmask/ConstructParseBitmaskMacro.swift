//
//  ConstructParseBitmaskMacro.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/28/25.
//

import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

enum ParseBitmaskMacroError: Error, DiagnosticMessage {
    case onlyStructsAreSupported
    case multipleMaskAttributes
    case maskOnAccessorVariable
    case noMaskAttributeOnVariable
    case variableNoTypeAnnotation
    case notIdentifierDef
    case invalidTypeAnnotation
    case emptyBitmask
    case fatalError(message: String)

    var message: String {
        switch self {
        case .onlyStructsAreSupported:
            "@ParseBitmask can only be applied to structs."
        case .multipleMaskAttributes:
            "A field cannot have multiple @mask attributes."
        case .maskOnAccessorVariable:
            "@mask cannot be applied to computed properties."
        case .noMaskAttributeOnVariable:
            "All stored properties must have a @mask attribute."
        case .variableNoTypeAnnotation:
            "Fields with @mask must have explicit type annotations."
        case .notIdentifierDef:
            "Field must use a simple identifier pattern, not destructuring."
        case .invalidTypeAnnotation:
            "Invalid type annotation on field."
        case .emptyBitmask:
            "@ParseBitmask struct must have at least one @mask field."
        case let .fatalError(message):
            message
        }
    }

    var diagnosticID: SwiftDiagnostics.MessageID {
        .init(
            domain: "observer.universe.BinaryParseKit.ParseBitmaskMacroError",
            id: "\(self)",
        )
    }

    var severity: SwiftDiagnostics.DiagnosticSeverity {
        switch self {
        case .emptyBitmask:
            .warning
        default:
            .error
        }
    }
}

public struct ConstructParseBitmaskMacro: ExtensionMacro {
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
        providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
        conformingTo _: [SwiftSyntax.TypeSyntax],
        in context: some SwiftSyntaxMacros.MacroExpansionContext,
    ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        guard let structDeclaration = declaration.as(StructDeclSyntax.self) else {
            throw ParseBitmaskMacroError.onlyStructsAreSupported
        }

        let type = type.trimmed

        let accessorInfo = try extractAccessor(
            from: node,
            attachedTo: declaration,
            in: context,
        )

        // Extract mask field info
        let fieldVisitor = ParseBitmaskField(context: context)
        fieldVisitor.walk(structDeclaration.memberBlock)
        try fieldVisitor.validate(for: structDeclaration)

        let fields = fieldVisitor.fields

        // Generate bitCount expression
        let bitCountExpr = generateBitCountExpression(fields: fields)

        // Generate init(from:) body
        let initBody = generateInitBody(fields: fields)

        let bitmaskParsableExtension =
            try ExtensionDeclSyntax("extension \(type): \(raw: Constants.Protocols.bitmaskParsableProtocol)") {
                // static var bitCount: Int
                try VariableDeclSyntax("\(accessorInfo.parsingAccessor) static var bitCount: Int") {
                    bitCountExpr
                }

                // init(from bits: RawBits) throws
                try InitializerDeclSyntax(
                    "\(accessorInfo.parsingAccessor) init(from bits: borrowing \(raw: Constants.Types.rawBits)) throws",
                ) {
                    initBody
                }
            }

        return [bitmaskParsableExtension]
    }

    private static func generateBitCountExpression(
        fields: ParseBitmaskField.FieldMapping,
    ) -> CodeBlockItemListSyntax {
        var parts: [String] = []

        for (_, field) in fields {
            switch field.bitCount {
            case let .specified(count):
                parts.append("\(count)")
            case .inferred:
                parts.append("\(field.type.trimmedDescription).bitCount")
            }
        }

        let expression = parts.isEmpty ? "0" : parts.joined(separator: " + ")
        return CodeBlockItemListSyntax {
            CodeBlockItemSyntax(item: .expr(ExprSyntax(stringLiteral: expression)))
        }
    }

    private static func generateInitBody(
        fields: ParseBitmaskField.FieldMapping,
    ) -> CodeBlockItemListSyntax {
        CodeBlockItemListSyntax {
            // Track bit offset
            DeclSyntax("var bitOffset = 0")

            // Generate parsing for each field
            for (_, field) in fields {
                switch field.bitCount {
                case let .specified(count):
                    // Assert ExpressibleByRawBits conformance
                    ExprSyntax(
                        "\(raw: Constants.UtilityFunctions.assertExpressibleByRawBits)((\(field.type)).self)",
                    )

                    // Parse the field
                    ExprSyntax(
                        """
                        self.\(field.name) = try \(raw: Constants.UtilityFunctions.parseFromBits)((\(field
                            .type)).self, from: bits, offset: bitOffset, count: \(raw: count))
                        """,
                    )

                    // Advance bit offset
                    ExprSyntax("bitOffset += \(raw: count)")

                case .inferred:
                    // Assert BitmaskParsable conformance
                    ExprSyntax(
                        "\(raw: Constants.UtilityFunctions.assertBitmaskParsable)((\(field.type)).self)",
                    )

                    // Parse the field using type's bitCount
                    ExprSyntax(
                        """
                        self.\(field.name) = try \(raw: Constants.UtilityFunctions.parseFromBits)((\(field
                            .type)).self, from: bits, offset: bitOffset, count: \(field.type).bitCount)
                        """,
                    )

                    // Advance bit offset
                    ExprSyntax("bitOffset += \(field.type).bitCount")
                }
            }
        }
    }
}
