//
//  EnumParseUtils.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/7/25.
//
import BinaryParsing

/// Matches the given bytes in the input parser span.
/// - Warning: This function is used by `@ParseEnum` macro and should not be used directly.
@_documentation(visibility: internal)
@inlinable
public func __match(_ bytes: borrowing [UInt8], in input: borrowing BinaryParsing.ParserSpan) -> Bool {
    if bytes.isEmpty { return true }

    do {
        try input._checkCount(minimum: bytes.count)
    } catch {
        return false
    }

    // O(1)
    let slicedInput = input.bytes.extracting(first: bytes.count)

    // O(n)
    return unsafe slicedInput.withUnsafeBytes { span in
        unsafe span.elementsEqual(bytes)
    }
}

/// Matches when the remaining bytes in the input parser span equals the specified length.
/// - Warning: This function is used by `@ParseEnum` macro and should not be used directly.
@_documentation(visibility: internal)
@inlinable
public func __match(length: Int, in input: borrowing BinaryParsing.ParserSpan) -> Bool {
    input.count == length
}

/// Asserts that the given type conforms to `Parsable`.
/// - Warning: This function is used to `@parse` macro and should not be used directly.
@_documentation(visibility: internal)
@inlinable
public func __assertParsable(_: (some Parsable).Type) {}

/// Asserts that the given type conforms to `SizedParsable`.
/// - Warning: This function is used to `@parse` macro and should not be used directly.
@_documentation(visibility: internal)
@inlinable
public func __assertSizedParsable(_: (some SizedParsable).Type) {}

/// Asserts that the given type conforms to `EndianParsable`.
/// - Warning: This function is used to `@parse` macro and should not be used directly.
@_documentation(visibility: internal)
@inlinable
public func __assertEndianParsable(_: (some EndianParsable).Type) {}

/// Asserts that the given type conforms to `EndianSizedParsable`.
/// - Warning: This function is used to `@parse` macro and should not be used directly.
@_documentation(visibility: internal)
@inlinable
public func __assertEndianSizedParsable(_: (some EndianSizedParsable).Type) {}

// MARK: - Bitmask Parsing Utilities

/// Asserts that the given type conforms to `BitmaskParsable`.
/// - Warning: This function is used by `@mask()` macro and should not be used directly.
@_documentation(visibility: internal)
@inlinable
public func __assertBitmaskParsable(_: (some ExpressibleByRawBits & BitCountProviding).Type) {}

/// Asserts that the given type conforms to `ExpressibleByRawBits`.
/// - Warning: This function is used by `@mask(bitCount:)` macro and should not be used directly.
@_documentation(visibility: internal)
@inlinable
public func __assertExpressibleByRawBits(_: (some ExpressibleByRawBits).Type) {}

// MARK: - RawBits Conversion Utilities

/// Asserts that the given type conforms to `RawBitsConvertible` and `BitCountProviding`.
/// - Warning: This function is used by `@ParseBitmask` macro and should not be used directly.
@_documentation(visibility: internal)
@inlinable
public func __assertRawBitsConvertible(_: (some RawBitsConvertible & BitCountProviding).Type) {}

/// Converts a value to RawBits with the specified bit count.
/// - Warning: This function is used by bitmask macros and should not be used directly.
/// - Parameters:
///   - value: The value to convert
///   - bitCount: The number of bits to produce
/// - Returns: The raw bits representation
/// - Throws: An error if the conversion cannot be performed
@_documentation(visibility: internal)
@inlinable
public func __toRawBits(
    _ value: some RawBitsConvertible,
    bitCount: Int,
) throws -> RawBits {
    try value.toRawBits(bitCount: bitCount)
}

// MARK: - Bit Adjustment Utilities for @mask(bitCount:)

/// Creates an instance of the specified type from the given raw bits span,
///
/// Overload for types that also conform to ``BitCountProviding``.
///
/// - Warning: This function is used by macro generation and should not be used directly.
@_documentation(visibility: internal)
@inlinable
public func __createFromBits<T: ExpressibleByRawBits & BitCountProviding>(
    _: T.Type,
    fieldBits: borrowing RawBitsSpan,
    fieldRequestedBitCount: Int,
    bitEndian: BinaryParsing.Endianness = .big,
) throws -> T {
    let typeBitCount = T.bitCount
    if fieldRequestedBitCount < typeBitCount {
        throw BitmaskParsableError.insufficientBitsAvailable
    } else if fieldRequestedBitCount > typeBitCount {
        // Need to adjust the bit count in the span to match what the type expects
        // For big endian, the significant bits are at the start (MSB side)
        // For little endian, the significant bits are at the end (LSB side)
        let adjustedBitCount = typeBitCount
        let adjustedSpan: RawBitsSpan
        switch bitEndian {
        case .big:
            adjustedSpan = fieldBits.__extracting(unchecked: (), first: adjustedBitCount)
        case .little:
            adjustedSpan = fieldBits.__extracting(unchecked: (), last: adjustedBitCount)
        default:
            fatalError("Unexpected bit endianness value: \(bitEndian)")
        }
        return try T(bits: adjustedSpan)
    } else {
        return try T(bits: fieldBits)
    }
}

/// Creates an instance of the specified type from the given raw bits span,
///
/// Fallback overload for types that only conform to ``ExpressibleByRawBits``.
///
/// - Warning: This function is used by macro generation and should not be used directly.
@_documentation(visibility: internal)
@inlinable
public func __createFromBits<T: ExpressibleByRawBits>(
    _: T.Type,
    fieldBits: borrowing RawBitsSpan,
    fieldRequestedBitCount _: Int,
    bitEndian _: BinaryParsing.Endianness = .big,
) throws -> T {
    try T(bits: fieldBits)
}
