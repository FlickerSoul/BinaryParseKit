//
//  MaskMacroInfo.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/28/25.
//
import SwiftSyntax

/// Information about a `@mask` annotated field in a bitmask struct.
struct MaskMacroInfo {
    /// How the bit count is specified for this field.
    enum BitCount: Equatable {
        /// Explicit bit count specified in `@mask(bitCount:)`.
        case specified(Int)

        /// Bit count should be inferred from the field type's `bitWidth`.
        case inferred

        /// Returns the bit count value, or `nil` if it needs to be inferred.
        var value: Int? {
            switch self {
            case let .specified(count): count
            case .inferred: nil
            }
        }
    }

    /// The bit count for this field.
    let bitCount: BitCount

    /// The field name token.
    let name: TokenSyntax

    /// The field type syntax.
    let type: TypeSyntax

    /// The starting bit position for this field (0-indexed from field order).
    /// This is computed after all fields are collected.
    var startBit: Int

    /// The source syntax node for error reporting.
    let source: Syntax

    /// Creates a new mask macro info.
    ///
    /// - Parameters:
    ///   - bitCount: How the bit count is specified.
    ///   - name: The field name token.
    ///   - type: The field type syntax.
    ///   - startBit: The starting bit position (default 0, computed later).
    ///   - source: The source syntax for error reporting.
    init(
        bitCount: BitCount,
        name: TokenSyntax,
        type: TypeSyntax,
        startBit: Int = 0,
        source: Syntax,
    ) {
        self.bitCount = bitCount
        self.name = name
        self.type = type.trimmed
        self.startBit = startBit
        self.source = source
    }
}

/// Extension to parse `@mask` attribute syntax.
extension MaskMacroInfo {
    /// Creates mask info from a `@mask` attribute and variable declaration.
    ///
    /// - Parameters:
    ///   - attribute: The `@mask` attribute syntax.
    ///   - name: The variable name.
    ///   - type: The variable type.
    ///   - source: The source syntax for error reporting.
    /// - Throws: `ParseBitmaskMacroError` if the attribute is invalid.
    init(
        from attribute: AttributeSyntax,
        name: TokenSyntax,
        type: TypeSyntax,
        source: Syntax,
    ) throws(ParseBitmaskMacroError) {
        self.name = name
        self.type = type.trimmed
        startBit = 0
        self.source = source

        // Parse the bit count from the attribute arguments
        guard let arguments = attribute.arguments?.as(LabeledExprListSyntax.self) else {
            // @mask() with no arguments - infer from type
            bitCount = .inferred
            return
        }

        // Look for bitCount argument
        for argument in arguments where argument.label?.text == "bitCount" {
            guard let intLiteral = argument.expression.as(IntegerLiteralExprSyntax.self),
                  let value = Int(intLiteral.literal.text)
            else {
                throw .invalidBitCountValue(source: source)
            }
            bitCount = .specified(value)
            return
        }

        // No bitCount argument found - infer from type
        bitCount = .inferred
    }
}
