//
//  ParseBitmaskMacroError.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 12/23/25.
//
import SwiftDiagnostics
import SwiftSyntax

/// Errors that can occur during `@ParseBitmask` macro expansion.
enum ParseBitmaskMacroError: Error, DiagnosticMessage {
    // MARK: - Declaration Type Errors

    /// The macro was applied to an unsupported declaration type.
    case unsupportedDeclarationType

    /// The macro was applied to an enum with associated values.
    case enumWithAssociatedValues

    /// The macro was applied to an enum without raw values.
    case enumWithoutRawValues

    // MARK: - Field Annotation Errors

    /// A stored property is missing the `@mask` annotation.
    case missingMaskAttribute(fieldName: String)

    /// A field has an invalid bit count value.
    case invalidBitCountValue(source: Syntax)

    /// A field is missing a type annotation.
    case missingTypeAnnotation(fieldName: String)

    // MARK: - Bit Count Validation Errors

    /// The sum of field bit counts doesn't match the specified total.
    case bitCountMismatch(expected: Int, actual: Int)

    /// The bit count cannot be inferred (no explicit bitCount and no @mask fields).
    case cannotInferBitCount

    /// A field's inferred bit count cannot be determined from its type.
    case cannotInferFieldBitCount(fieldName: String, typeName: String)

    // MARK: - Endianness Errors

    /// Endianness is required for multi-byte bitmasks but was not specified.
    case missingEndiannessForMultiByte(bitCount: Int)

    // MARK: - General Errors

    /// A fatal error occurred during macro expansion.
    case fatalError(message: String)

    // MARK: - DiagnosticMessage

    var message: String {
        switch self {
        case .unsupportedDeclarationType:
            "@ParseBitmask can only be applied to structs or enums."
        case .enumWithAssociatedValues:
            "@ParseBitmask cannot be applied to enums with associated values."
        case .enumWithoutRawValues:
            "@ParseBitmask requires enums to have a raw value type conforming to BinaryInteger."
        case let .missingMaskAttribute(fieldName):
            "Stored property '\(fieldName)' must have a @mask attribute."
        case .invalidBitCountValue:
            "Invalid bit count value. Expected a positive integer literal."
        case let .missingTypeAnnotation(fieldName):
            "Field '\(fieldName)' must have an explicit type annotation."
        case let .bitCountMismatch(expected, actual):
            "Bit count mismatch: specified \(expected) bits but fields total \(actual) bits."
        case .cannotInferBitCount:
            "Cannot infer bit count. Either specify bitCount parameter or add @mask fields with explicit bit counts."
        case let .cannotInferFieldBitCount(fieldName, typeName):
            "Cannot infer bit count for field '\(fieldName)' of type '\(typeName)'. Use @mask(bitCount:) to specify explicitly."
        case let .missingEndiannessForMultiByte(bitCount):
            "Bitmask with \(bitCount) bits (more than 8) requires endianness to be specified."
        case let .fatalError(message):
            "Fatal error: \(message)"
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
        case .unsupportedDeclarationType,
             .enumWithAssociatedValues,
             .enumWithoutRawValues,
             .missingMaskAttribute,
             .invalidBitCountValue,
             .missingTypeAnnotation,
             .bitCountMismatch,
             .cannotInferBitCount,
             .cannotInferFieldBitCount,
             .missingEndiannessForMultiByte,
             .fatalError:
            .error
        }
    }
}
