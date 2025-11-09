//
//  SkipMacroInfo.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 7/15/25.
//

import BinaryParseKitCommons
import SwiftSyntax

struct SkipMacroInfo {
    let byteCount: ByteCount
    let reason: ExprSyntax
    let source: Syntax

    init(byteCount: ByteCount, reason: ExprSyntax, source: Syntax) {
        self.byteCount = byteCount
        self.reason = reason
        self.source = source
    }

    init(from attribute: AttributeSyntax) throws(ParseStructMacroError) {
        guard let arguments = attribute.arguments?.as(LabeledExprListSyntax.self) else {
            throw ParseStructMacroError.failedExpectation(
                message: "Expected a labeled expression list for `@parseSkip` attribute, but found none.",
            )
        }

        guard arguments.count == 2 else {
            throw ParseStructMacroError.fatalError(
                message: "Expected exactly two arguments for `@parseSkip` attribute, but found \(arguments.count).",
            )
        }

        let byteCountArgument = arguments[arguments.index(at: 0)]
        let reasonArgument = arguments[arguments.index(at: 1)]

        guard case let .integerLiteral(byteCount) = byteCountArgument.expression.as(IntegerLiteralExprSyntax.self)?
            .literal.tokenKind else {
            throw ParseStructMacroError.failedExpectation(
                message: "Expected the first argument of `@parseSkip` to be an integer literal representing byte count.",
            )
        }

        guard let byteCountValue = ByteCount(byteCount) else {
            throw ParseStructMacroError.failedExpectation(
                message: "byteCount should be convertible to Int.",
            )
        }

        self.init(byteCount: byteCountValue, reason: reasonArgument.expression, source: Syntax(attribute))
    }
}
