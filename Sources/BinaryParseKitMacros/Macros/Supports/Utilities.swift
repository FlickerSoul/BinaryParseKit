//
//  Utilities.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/8/25.
//
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@CodeBlockItemListBuilder
func generateParseBlock(
    variableName: TokenSyntax,
    variableType: TypeSyntax,
    fieldParseInfo: ParseMacroInfo,
    useSelf: Bool,
) -> CodeBlockItemListSyntax {
    let byteCount: ExprSyntax? = switch fieldParseInfo.byteCount {
    case let .fixed(count):
        ExprSyntax("\(raw: count)")
    case .variable:
        ExprSyntax("span.endPosition - span.startPosition")
    case .unspecified:
        nil
    case let .ofVariable(expr):
        ExprSyntax("Int(\(expr))")
    }
    let endianness = fieldParseInfo.endianness

    switch (endianness, byteCount) {
    case let (endianness?, size?):
        #"""
        // Parse `\#(variableName)` of type \#(variableType) with endianness and byte count
        \#(raw: Constants.UtilityFunctions.assertEndianSizedParsable)((\#(variableType)).self)
        """#

        let assigned: ExprSyntax = #"try \#(variableType)(parsing: &span, endianness: \#(endianness), byteCount: \#(size))"#

        if useSelf {
            "self.\(variableName) = \(assigned)"
        } else {
            "let \(variableName) = \(assigned)"
        }
    case (let endianness?, nil):
        #"""
        // Parse `\#(variableName)` of type \#(variableType) with endianness
        \#(raw: Constants.UtilityFunctions.assertEndianParsable)((\#(variableType)).self)
        """#

        let assigned: ExprSyntax = #"try \#(variableType)(parsing: &span, endianness: \#(endianness))"#

        if useSelf {
            "self.\(variableName) = \(assigned)"
        } else {
            "let \(variableName) = \(assigned)"
        }
    case (nil, let size?):
        #"""
        // Parse `\#(variableName)` of type \#(variableType) with byte count
        \#(raw: Constants.UtilityFunctions.assertSizedParsable)((\#(variableType)).self)
        """#

        let assigned: ExprSyntax = #"try \#(variableType)(parsing: &span, byteCount: \#(size))"#

        if useSelf {
            "self.\(variableName) = \(assigned)"
        } else {
            "let \(variableName) = \(assigned)"
        }
    case (nil, nil):
        #"""
        // Parse `\#(variableName)` of type \#(variableType)
        \#(raw: Constants.UtilityFunctions.assertParsable)((\#(variableType)).self)
        """#

        let assigned: ExprSyntax = #"try \#(variableType)(parsing: &span)"#

        if useSelf {
            "self.\(variableName) = \(assigned)"
        } else {
            "let \(variableName) = \(assigned)"
        }
    }
}

@CodeBlockItemListBuilder
func generateSkipBlock(variableName: TokenSyntax, skipInfo: SkipMacroInfo) -> CodeBlockItemListSyntax {
    let byteCount = skipInfo.byteCount
    let reason = skipInfo.reason
    #"""
    // Skip \#(raw: byteCount) because of \#(reason), before parsing `\#(variableName)`
    try span.seek(toRelativeOffset: \#(raw: byteCount))
    """#
}

struct PrintableFieldInfo {
    enum Content {
        case binding(fieldName: TokenSyntax)
        case skip
        case bits(variableName: TokenSyntax)
    }

    let content: Content
    let byteCount: ExprSyntax?
    let endianness: ExprSyntax?
}

@ArrayElementListBuilder
func generatePrintableFields(_ infos: [PrintableFieldInfo]) -> ArrayElementListSyntax {
    for info in infos {
        ArrayElementSyntax(
            expression:
            FunctionCallExprSyntax(callee: MemberAccessExprSyntax(name: "init")) {
                LabeledExprSyntax(
                    label: "byteCount",
                    expression: info.byteCount ?? ExprSyntax("nil"),
                )
                LabeledExprSyntax(
                    label: "endianness",
                    expression: info.endianness ?? ExprSyntax("nil"),
                )

                switch info.content {
                case let .binding(binding):
                    LabeledExprSyntax(
                        label: "intel",
                        expression: ExprSyntax(
                            "try \(raw: Constants.UtilityFunctions.getPrintIntel)(\(binding))",
                        ),
                    )
                case .skip:
                    LabeledExprSyntax(
                        label: "intel",
                        expression: ExprSyntax(
                            ".skip(.init(byteCount: \(info.byteCount)))",
                        ),
                    )
                case let .bits(variableName):
                    LabeledExprSyntax(
                        label: "intel",
                        expression: ExprSyntax(
                            ".bitmask(.init(bits: \(variableName)))",
                        ),
                    )
                }
            },
        )
    }
}

// MARK: - Bitmask Parsing

/// Generates code to parse a group of consecutive @mask fields for structs
func generateMaskGroupBlock(
    maskActions: [ParseActionGroup.MaskGroupAction],
    bitEndian: String,
    context: some MacroExpansionContext,
) throws -> CodeBlockItemListSyntax {
    guard !maskActions.isEmpty else {
        return CodeBlockItemListSyntax {}
    }

    let isBigEndian = bitEndian == "big"
    let slicingMethod = isBigEndian ? "first" : "last"

    // Calculate total bits needed
    // For each field, we use either the explicit bitCount or the type's bitCount
    let bitsVarName = context.makeUniqueName("__bitmask_totalBits")
    let bytesVarName = context.makeUniqueName("__bitmask_byteCount")
    let spanVarName = context.makeUniqueName("__bitmask_span")

    // Calculate total bits
    let bitCountExprs = maskActions.map { maskAction in
        maskAction.maskInfo.bitCount.expr(of: maskAction.variableType)
    }
    let firstBitExpr = bitCountExprs.first
    let remainingBitExprs = bitCountExprs.dropFirst()
    let totalBitsExpr: ExprSyntax = if let firstBitExpr {
        remainingBitExprs.reduce(firstBitExpr) { partialResult, next in
            "\(partialResult) + \(next)"
        }
    } else {
        throw ParseStructMacroError.fatalError(message: "Failed to calculate total bits.")
    }

    return CodeBlockItemListSyntax {
        """
        // Parse bitmask fields
        let \(bitsVarName) = \(totalBitsExpr)
        """

        // Calculate byte count: (totalBits + 7) / 8
        "let \(bytesVarName) = (\(bitsVarName) + 7) / 8"

        // Get a sliced span for bitmask bytes
        "var \(spanVarName) = try RawBitsSpan(span.sliceSpan(byteCount: \(bytesVarName)).bytes, bitCount: \(bitsVarName))"

        // Parse each field
        for action in maskActions {
            let variableName = action.variableName
            let fieldType = action.variableType
            let subSpan = context.makeUniqueName("__subSpan")

            switch action.maskInfo.bitCount {
            case let .specified(count):
                // Assert ExpressibleByRawBits for explicit bit count
                let countExpr = count.expr
                """
                // Parse `\(variableName)` of type \(fieldType) from bits
                \(raw: Constants.UtilityFunctions.assertExpressibleByRawBits)((\(fieldType)).self)
                """
                """
                let \(subSpan) = \(spanVarName).slicing(unchecked: (), \(raw: slicingMethod): \(countExpr))
                """
                """
                self.\(variableName) = try \(raw: Constants.UtilityFunctions.createFromBits)(
                    (\(fieldType)).self,
                    fieldBits: \(subSpan),
                    fieldRequestedBitCount: \(countExpr),
                    bitEndian: .\(raw: bitEndian),
                )
                """
            case .inferred:
                // Assert BitmaskParsable for inferred bit count
                let countExpr: ExprSyntax = "(\(fieldType.trimmed)).bitCount"
                """
                // Parse `\(variableName)` of type \(fieldType) from bits
                \(raw: Constants.UtilityFunctions.assertBitmaskParsable)((\(fieldType)).self)
                """
                """
                let \(subSpan) = \(spanVarName).slicing(unchecked: (), \(raw: slicingMethod): \(countExpr))
                """
                """
                self.\(variableName) = try \(raw: Constants.UtilityFunctions.createFromBits)(
                    (\(fieldType)).self,
                    fieldBits: \(subSpan),
                    fieldRequestedBitCount: \(countExpr),
                    bitEndian: .\(raw: bitEndian),
                )
                """
            }
        }
    }
}

/// Generates code to parse a group of consecutive @mask fields for enum associated values
func generateEnumMaskGroupBlock(
    maskActions: [ParseActionGroup.MaskGroupAction],
    caseElementName: TokenSyntax,
    bitEndian: String,
    context: some MacroExpansionContext,
) throws -> CodeBlockItemListSyntax {
    guard !maskActions.isEmpty else {
        return CodeBlockItemListSyntax {}
    }

    let isBigEndian = bitEndian == "big"
    let slicingMethod = isBigEndian ? "first" : "last"

    // Calculate total bits needed
    let bitsVarName = context.makeUniqueName("__bitmask_totalBits")
    let bytesVarName = context.makeUniqueName("__bitmask_byteCount")
    let spanVarName = context.makeUniqueName("__bitmask_span")

    // Calculate total bits
    let bitCountExprs = maskActions.map { maskAction in
        maskAction.maskInfo.bitCount.expr(of: maskAction.variableType)
    }
    let firstBitCountExpr = bitCountExprs.first
    let remainingBitCountExprs = bitCountExprs.dropFirst()
    let totalBitsExpr: ExprSyntax = if let firstBitCountExpr {
        remainingBitCountExprs.reduce(firstBitCountExpr) { partialResult, next in
            "\(partialResult) + \(next)"
        }
    } else {
        throw ParseEnumMacroError
            .unexpectedError(description: "Failed to calculate total bits for enum case \(caseElementName.text).")
    }

    return CodeBlockItemListSyntax {
        """
        // Parse bitmask fields for `\(caseElementName)`
        let \(bitsVarName) = \(totalBitsExpr)
        """

        // Calculate byte count: (totalBits + 7) / 8
        "let \(bytesVarName) = (\(bitsVarName) + 7) / 8"

        // Get a sliced span for bitmask bytes
        "var \(spanVarName) = try RawBitsSpan(span.sliceSpan(byteCount: \(bytesVarName)).bytes, bitCount: \(bitsVarName))"

        // Parse each field
        for maskAction in maskActions {
            let variableName = maskAction.variableName
            let fieldType = maskAction.variableType
            let subSpan = context.makeUniqueName("__subSpan")

            switch maskAction.maskInfo.bitCount {
            case let .specified(count):
                // Assert ExpressibleByRawBits for explicit bit count
                let countExpr = count.expr
                """
                // Parse `\(variableName)` of type \(fieldType) from bits
                \(raw: Constants.UtilityFunctions.assertExpressibleByRawBits)((\(fieldType)).self)
                """
                """
                let \(subSpan) = \(spanVarName).slicing(unchecked: (), \(raw: slicingMethod): \(countExpr))
                """
                """
                let \(variableName) = try \(raw: Constants.UtilityFunctions.createFromBits)(
                    (\(fieldType)).self,
                    fieldBits: \(subSpan),
                    fieldRequestedBitCount: \(countExpr),
                    bitEndian: .\(raw: bitEndian),
                )
                """
            case .inferred:
                // Assert BitmaskParsable for inferred bit count
                let countExpr: ExprSyntax = "(\(fieldType.trimmed)).bitCount"
                """
                // Parse `\(variableName)` of type \(fieldType) from bits
                \(raw: Constants.UtilityFunctions.assertBitmaskParsable)((\(fieldType)).self)
                """
                """
                let \(subSpan) = \(spanVarName).slicing(unchecked: (), \(raw: slicingMethod): \(countExpr))
                """
                """
                let \(variableName) = try \(raw: Constants.UtilityFunctions.createFromBits)(
                    (\(fieldType)).self,
                    fieldBits: \(subSpan),
                    fieldRequestedBitCount: \(countExpr),
                    bitEndian: .\(raw: bitEndian),
                )
                """
            }
        }
    }
}
