//
//  StructFieldParseInfo.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 7/15/25.
//

import BinaryParseKitCommons
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

private class ParseMacroArgVisitor<C: MacroExpansionContext>: SyntaxVisitor {
    var byteCountOfArgument: LabeledExprSyntax?
    var byteCountArgument: LabeledExprSyntax?
    var endiannessArgument: LabeledExprSyntax?

    private var errors: [Diagnostic] = []

    private let context: C
    init(context: C) {
        self.context = context
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: LabeledExprSyntax) -> SyntaxVisitorContinueKind {
        switch node.label?.text {
        case "byteCountOf":
            byteCountOfArgument = node
        case "byteCount":
            byteCountArgument = node
        case "endianness":
            endiannessArgument = node
        case _:
            errors.append(.init(node: node, message: ParseStructMacroError.unknownParseArgument(node.description)))
        }
        return .skipChildren
    }

    func toStructFieldParseInfo() throws(ParseStructMacroError) -> StructFieldParseInfo {
        if byteCountOfArgument != nil, byteCountArgument != nil {
            throw ParseStructMacroError
                .fatalError(message: "Both `byteCountOf` and `byteCount` cannot be specified at the same time.")
        }
        let byteCount: StructFieldParseInfo.Count

        if let byteCountArgument {
            guard case let .integerLiteral(byteCountLiteral) = byteCountArgument.expression
                .as(IntegerLiteralExprSyntax.self)?
                .literal
                .tokenKind else {
                throw ParseStructMacroError.failedExpectation(message: "byteCount should be an integer literal.")
            }
            guard let integerCount = ByteCount(byteCountLiteral) else {
                throw ParseStructMacroError.failedExpectation(message: "byteCount should be convertible to Int.")
            }
            byteCount = .fixed(integerCount)
        } else if let byteCountOfArgument {
            guard let keyPath = byteCountOfArgument.expression.as(KeyPathExprSyntax.self) else {
                throw ParseStructMacroError
                    .failedExpectation(message: "byteCountOf should be a KeyPath lietarl expression.")
            }

            let selfAccessExpr = ExprSyntax("self\(keyPath.components)")

            byteCount = .ofVariable(selfAccessExpr)
        } else {
            byteCount = .unspecified
        }

        return .init(byteCount: byteCount, endianness: endiannessArgument?.expression)
    }

    func validate() throws(ParseStructMacroError) {
        if !errors.isEmpty {
            for error in errors {
                context.diagnose(error)
            }

            throw ParseStructMacroError.fatalError(message: "@parse argument validation failed.")
        }
    }
}

struct StructFieldParseInfo {
    enum Count {
        /// A fixed byte count, specified by `byteCount` argument
        case fixed(ByteCount)
        /// A variable byte count, specified by `@parseRest` macro
        case variable
        /// An unspecified byte count, meaning it uses `Parsable` or `EndianParsable` which doesn't care about the size
        case unspecified
        /// A variable byte count, specified by `byteCountOf` argument
        case ofVariable(ExprSyntax)
    }

    /// The byte count of this field
    let byteCount: Count
    /// The endianness of this field, if specified
    let endianness: ExprSyntax?

    init(byteCount: Count, endianness: ExprSyntax? = nil) {
        self.byteCount = byteCount
        self.endianness = endianness
    }

    init(
        fromParse attribute: borrowing AttributeSyntax,
        in context: some MacroExpansionContext,
    ) throws(ParseStructMacroError) {
        if attribute.arguments == nil {
            self.init(byteCount: .unspecified, endianness: nil)
            return
        }

        let visitor = ParseMacroArgVisitor(context: context)
        visitor.walk(attribute)
        try visitor.validate()

        self = try visitor.toStructFieldParseInfo()
    }

    init(fromParseRest attribute: AttributeSyntax) {
        let endiannessArgument: LabeledExprSyntax? = attribute.arguments?.as(LabeledExprListSyntax.self)?.first

        self.init(byteCount: .variable, endianness: endiannessArgument?.expression)
    }
}
