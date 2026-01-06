//
//  EnumParseUtils.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/7/25.
//
import BinaryParsing

/// Matches the given bytes in the input parser span.
/// - Warning: This function is used by `@ParseEnum` macro and should not be used directly.
@inline(__always)
public func __match(_ bytes: borrowing [UInt8], in input: inout BinaryParsing.ParserSpan) -> Bool {
    if bytes.isEmpty { return true }

    do {
        try input._checkCount(minimum: bytes.count)
    } catch {
        return false
    }

    for (index, byte) in bytes.enumerated()
        where unsafe input.bytes.unsafeLoad(fromByteOffset: index, as: UInt8.self) != byte {
        return false
    }

    return true
}

/// Matches when the remaining bytes in the input parser span equals the specified length.
/// - Warning: This function is used by `@ParseEnum` macro and should not be used directly.
@inline(__always)
public func __match(length: Int, in input: borrowing BinaryParsing.ParserSpan) -> Bool {
    input.count == length
}

/// Asserts that the given type conforms to `Parsable`.
/// - Warning: This function is used to `@parse` macro and should not be used directly.
@inline(__always)
public func __assertParsable(_: (some Parsable).Type) {}

/// Asserts that the given type conforms to `SizedParsable`.
/// - Warning: This function is used to `@parse` macro and should not be used directly.
@inline(__always)
public func __assertSizedParsable(_: (some SizedParsable).Type) {}

/// Asserts that the given type conforms to `EndianParsable`.
/// - Warning: This function is used to `@parse` macro and should not be used directly.
@inline(__always)
public func __assertEndianParsable(_: (some EndianParsable).Type) {}

/// Asserts that the given type conforms to `EndianSizedParsable`.
/// - Warning: This function is used to `@parse` macro and should not be used directly.
@inline(__always)
public func __assertEndianSizedParsable(_: (some EndianSizedParsable).Type) {}

// MARK: - Bitmask Parsing Utilities

/// Asserts that the given type conforms to `BitmaskParsable`.
/// - Warning: This function is used by `@mask()` macro and should not be used directly.
@inline(__always)
public func __assertBitmaskParsable(_: (some ExpressibleByRawBits & BitCountProviding).Type) {}

/// Asserts that the given type conforms to `ExpressibleByRawBits`.
/// - Warning: This function is used by `@mask(bitCount:)` macro and should not be used directly.
@inline(__always)
public func __assertExpressibleByRawBits(_: (some ExpressibleByRawBits).Type) {}

/// Parses a value from a bit slice.
/// - Warning: This function is used by bitmask macros and should not be used directly.
/// - Parameters:
///   - type: The type to parse
///   - bits: The RawBits containing all bits
///   - offset: The bit offset to start from
///   - count: The number of bits to extract
/// - Returns: The parsed value
@inline(__always)
public func __parseFromBits<T: ExpressibleByRawBits>(
    _: T.Type,
    from bits: RawBits,
    offset: Int,
    count: Int,
) throws -> T {
    let slice = bits.slice(from: offset, count: count)
    return try T(bits: slice)
}

// MARK: - RawBits Conversion Utilities

/// Asserts that the given type conforms to `RawBitsConvertible` and `BitCountProviding`.
/// - Warning: This function is used by `@ParseBitmask` macro and should not be used directly.
@inline(__always)
public func __assertRawBitsConvertible(_: (some RawBitsConvertible & BitCountProviding).Type) {}

/// Converts a value to RawBits with the specified bit count.
/// - Warning: This function is used by bitmask macros and should not be used directly.
/// - Parameters:
///   - value: The value to convert
///   - bitCount: The number of bits to produce
/// - Returns: The raw bits representation
/// - Throws: An error if the conversion cannot be performed
@inline(__always)
public func __toRawBits(
    _ value: some RawBitsConvertible,
    bitCount: Int,
) throws -> RawBits {
    try value.toRawBits(bitCount: bitCount)
}
