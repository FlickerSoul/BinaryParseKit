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
    case bitCountMustBePositive
    case noTypeAnnotation
    case fatalError(message: String)

    var message: String {
        switch self {
        case .bitCountMustBePositive:
            "The bitCount argument must be a positive integer."
        case .noTypeAnnotation: "@mask fields must have a type annotation."
        case let .fatalError(message: message):
            "Fatal error in Mask macro: \(message)"
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

    func expr(of type: TypeSyntax) -> ExprSyntax {
        switch self {
        case let .specified(count):
            count.expr
        case .inferred:
            "(\(type)).bitCount"
        }
    }
}

struct MaskMacroInfo {
    let bitCount: MaskMacroBitCount
    let source: Syntax

    func validate(in errors: inout [Diagnostic]) {
        if case let .specified(.literal(bitCountInt)) = bitCount, bitCountInt <= 0 {
            errors.append(.init(
                node: source,
                message: MaskMacroError.bitCountMustBePositive,
            ))
        }
    }

    /// Parse a @mask attribute from an AttributeSyntax
    static func parse(from attribute: AttributeSyntax) -> MaskMacroInfo {
        // Check if there are arguments
        guard let arguments = attribute.arguments?.as(LabeledExprListSyntax.self),
              let bitCountArg = arguments.first(where: { $0.label?.text == "bitCount" }) else {
            // No arguments means @mask() - inferred bit count
            return MaskMacroInfo(
                bitCount: .inferred,
                source: Syntax(attribute),
            )
        }

        let bitCountExpression = bitCountArg.expression

        // Check for bitCount: argument
        if let intLiteral = Expr(bitCountExpression).asIntegerLiteral?.value {
            return MaskMacroInfo(
                bitCount: .specified(.literal(intLiteral)),
                source: Syntax(attribute),
            )
        } else {
            return MaskMacroInfo(
                bitCount: .specified(.expression(bitCountExpression)),
                source: Syntax(attribute),
            )
        }
    }
}
