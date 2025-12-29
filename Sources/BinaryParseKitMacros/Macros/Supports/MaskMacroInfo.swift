//
//  MaskMacroInfo.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/28/25.
//
import MacroToolkit
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

enum MaskMacroError: Error, DiagnosticMessage {
    case invalidBitCountArgument
    case bitCountMustBePositive
    case noTypeAnnotation
    case fatalError(description: String)

    var message: String {
        switch self {
        case .invalidBitCountArgument:
            "The bitCount argument must be an integer literal."
        case .bitCountMustBePositive:
            "The bitCount argument must be a positive integer."
        case let .fatalError(description: fatalError):
            "Fatal error in Mask macro: \(fatalError)"
        case .noTypeAnnotation: "@mask fields must have a type annotation."
        }
    }

    var diagnosticID: SwiftDiagnostics.MessageID {
        .init(
            domain: "observer.universe.BinaryParseKit.MaskMacroError",
            id: "\(self)",
        )
    }

    var severity: SwiftDiagnostics.DiagnosticSeverity {
        .error
    }
}

enum BitCount {
    case literal(Int)
    case expression(ExprSyntax)

    var expr: ExprSyntax {
        switch self {
        case let .literal(int):
            "\(raw: int)"
        case let .expression(exprSyntax):
            exprSyntax
        }
    }
}

enum MaskMacroBitCount {
    /// An explicit bit count specified in the macro, e.g., @mask(bitCount: 4)
    case specified(BitCount)
    /// Bit count should be inferred from the type's BitCountProviding conformance
    case inferred
}

struct MaskMacroInfo {
    let bitCount: MaskMacroBitCount
    let fieldName: TokenSyntax?
    let fieldType: TypeSyntax?
    let source: Syntax

    init(
        bitCount: MaskMacroBitCount,
        fieldName: TokenSyntax?,
        fieldType: TypeSyntax?,
        source: Syntax,
    ) {
        self.bitCount = bitCount
        self.fieldName = fieldName?.trimmed
        self.fieldType = fieldType?.trimmed
        self.source = source
    }

    /// Parse a @mask attribute from an AttributeSyntax
    static func parse(
        from attribute: AttributeSyntax,
        fieldName: TokenSyntax?,
        fieldType: TypeSyntax?,
    ) throws(MaskMacroError) -> MaskMacroInfo {
        // Check if there are arguments
        guard let arguments = attribute.arguments?.as(LabeledExprListSyntax.self),
              let bitCountArg = arguments.first(where: { $0.label?.text == "bitCount" }) else {
            // No arguments means @mask() - inferred bit count
            return MaskMacroInfo(
                bitCount: .inferred,
                fieldName: fieldName,
                fieldType: fieldType,
                source: Syntax(attribute),
            )
        }

        let bitCountExpression = bitCountArg.expression

        // Check for bitCount: argument
        if let intLiteral = Expr(bitCountExpression).asIntegerLiteral?.value {
            if intLiteral <= 0 {
                throw .bitCountMustBePositive
            }

            return MaskMacroInfo(
                bitCount: .specified(.literal(intLiteral)),
                fieldName: fieldName,
                fieldType: fieldType,
                source: Syntax(attribute),
            )
        } else {
            return MaskMacroInfo(
                bitCount: .specified(.expression(bitCountExpression)),
                fieldName: fieldName,
                fieldType: fieldType,
                source: Syntax(attribute),
            )
        }
    }
}
