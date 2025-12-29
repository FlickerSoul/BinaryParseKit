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
    let binding: TokenSyntax?
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

                if let binding = info.binding {
                    LabeledExprSyntax(
                        label: "intel",
                        expression: ExprSyntax(
                            "try \(raw: Constants.UtilityFunctions.getPrintIntel)(\(binding))",
                        ),
                    )
                } else {
                    LabeledExprSyntax(
                        label: "intel",
                        expression: ExprSyntax(
                            ".skip(.init(byteCount: \(info.byteCount)))",
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
    maskGroup: [(TokenSyntax, TypeSyntax, MaskMacroInfo)],
    context: some MacroExpansionContext,
) throws -> CodeBlockItemListSyntax {
    guard !maskGroup.isEmpty else {
        return CodeBlockItemListSyntax {}
    }

    // Calculate total bits needed
    // For each field, we use either the explicit bitCount or the type's bitCount
    let bitsVarName = context.makeUniqueName("__bitmask_totalBits")
    let bytesVarName = context.makeUniqueName("__bitmask_byteCount")
    let dataVarName = context.makeUniqueName("__bitmask_data")
    let bitsObjVarName = context.makeUniqueName("__bitmask_bits")
    let offsetVarName = context.makeUniqueName("__bitmask_offset")

    // Calculate total bits
    let bitCountExprs = maskGroup.map { _, _, maskInfo -> ExprSyntax in
        guard let fieldType = maskInfo.fieldType else {
            fatalError("MaskMacroInfo must have fieldType set for struct mask groups")
        }
        switch maskInfo.bitCount {
        case let .specified(count):
            return count.expr
        case .inferred:
            return "(\(fieldType.trimmed)).bitCount"
        }
    }
    let firstBitExpr = bitCountExprs.first
    let remainingBitExprs = bitCountExprs.dropFirst()
    let totalBitsExpr: ExprSyntax = if let firstBitExpr {
        remainingBitExprs.reduce(firstBitExpr) { partialResult, next in
            "\(partialResult) + \(next)"
        }
    } else {
        "0"
    }

    return CodeBlockItemListSyntax {
        """
        // Parse bitmask fields
        let \(bitsVarName) = \(totalBitsExpr)
        """

        // Calculate byte count: (totalBits + 7) / 8
        "let \(bytesVarName) = (\(bitsVarName) + 7) / 8"

        // Read bytes from span
        "let \(dataVarName) = try span.sliceSpan(byteCount: \(bytesVarName)).withUnsafeBytes(Data.init(_:))"

        // Create RawBits
        "let \(bitsObjVarName) = BinaryParseKit.RawBits(data: \(dataVarName), size: \(bitsVarName))"

        // Track offset for each field
        "var \(offsetVarName) = 0"

        // Parse each field
        for (variableName, fieldType, maskInfo) in maskGroup {
            switch maskInfo.bitCount {
            case let .specified(count):
                // Assert ExpressibleByRawBits for explicit bit count
                """
                // Parse `\(variableName)` of type \(fieldType) from bits
                \(raw: Constants.UtilityFunctions.assertExpressibleByRawBits)((\(fieldType)).self)
                """
                "self.\(variableName) = try \(raw: Constants.UtilityFunctions.parseFromBits)((\(fieldType)).self, from: \(bitsObjVarName), offset: \(offsetVarName), count: \(count.expr))"
                "\(offsetVarName) += \(count.expr)"
            case .inferred:
                // Assert BitmaskParsable for inferred bit count
                """
                // Parse `\(variableName)` of type \(fieldType) from bits
                \(raw: Constants.UtilityFunctions.assertBitmaskParsable)((\(fieldType)).self)
                """
                "self.\(variableName) = try \(raw: Constants.UtilityFunctions.parseFromBits)((\(fieldType)).self, from: \(bitsObjVarName), offset: \(offsetVarName), count: (\(fieldType.trimmed)).bitCount)"
                "\(offsetVarName) += (\(fieldType.trimmed)).bitCount"
            }
        }
    }
}

/// Generates code to parse a group of consecutive @mask fields for enum associated values
func generateEnumMaskGroupBlock(
    maskGroup: [(TokenSyntax, TypeSyntax, MaskMacroInfo)],
    caseElementName: TokenSyntax,
    context: some MacroExpansionContext,
) throws -> CodeBlockItemListSyntax {
    guard !maskGroup.isEmpty else {
        return CodeBlockItemListSyntax {}
    }

    // Calculate total bits needed
    let bitsVarName = context.makeUniqueName("__bitmask_totalBits")
    let bytesVarName = context.makeUniqueName("__bitmask_byteCount")
    let dataVarName = context.makeUniqueName("__bitmask_data")
    let bitsObjVarName = context.makeUniqueName("__bitmask_bits")
    let offsetVarName = context.makeUniqueName("__bitmask_offset")

    // Calculate total bits
    let bitCountExprs = maskGroup.map { _, type, maskInfo -> ExprSyntax in
        switch maskInfo.bitCount {
        case let .specified(count):
            return count.expr
        case .inferred:
            return "(\(type.trimmed)).bitCount"
        }
    }
    let firstBitCountExpr = bitCountExprs.first
    let remainingBitCountExprs = bitCountExprs.dropFirst()
    let totalBitsExpr: ExprSyntax = if let firstBitCountExpr {
        remainingBitCountExprs.reduce(firstBitCountExpr) { partialResult, next in
            "\(partialResult) + \(next)"
        }
    } else {
        "0"
    }

    return CodeBlockItemListSyntax {
        """
        // Parse bitmask fields for `\(caseElementName)`
        let \(bitsVarName) = \(totalBitsExpr)
        """

        // Calculate byte count: (totalBits + 7) / 8
        "let \(bytesVarName) = (\(bitsVarName) + 7) / 8"

        // Read bytes from span
        "let \(dataVarName) = try span.sliceSpan(byteCount: \(bytesVarName)).withUnsafeBytes(Data.init(_:))"

        // Create RawBits
        "let \(bitsObjVarName) = BinaryParseKit.RawBits(data: \(dataVarName), size: \(bitsVarName))"

        // Track offset for each field
        "var \(offsetVarName) = 0"

        // Parse each field
        for (variableName, fieldType, maskInfo) in maskGroup {
            switch maskInfo.bitCount {
            case let .specified(count):
                // Assert ExpressibleByRawBits for explicit bit count
                """
                // Parse `\(variableName)` of type \(fieldType) from bits
                \(raw: Constants.UtilityFunctions.assertExpressibleByRawBits)((\(fieldType)).self)
                """
                "let \(variableName) = try \(raw: Constants.UtilityFunctions.parseFromBits)((\(fieldType)).self, from: \(bitsObjVarName), offset: \(offsetVarName), count: \(count.expr))"
                "\(offsetVarName) += \(count.expr)"
            case .inferred:
                // Assert BitmaskParsable for inferred bit count
                """
                // Parse `\(variableName)` of type \(fieldType) from bits
                \(raw: Constants.UtilityFunctions.assertBitmaskParsable)((\(fieldType)).self)
                """
                "let \(variableName) = try \(raw: Constants.UtilityFunctions.parseFromBits)((\(fieldType)).self, from: \(bitsObjVarName), offset: \(offsetVarName), count: (\(fieldType.trimmed)).bitCount)"
                "\(offsetVarName) += (\(fieldType.trimmed)).bitCount"
            }
        }
    }
}
