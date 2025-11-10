//
//  Utilities.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/8/25.
//
import SwiftSyntax
import SwiftSyntaxBuilder

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
