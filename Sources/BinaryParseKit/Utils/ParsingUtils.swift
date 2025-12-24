//
//  EnumParseUtils.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/7/25.
//
import BinaryParsing
import Foundation

/// Matches the given bytes in the input parser span.
/// - Warning: This function is used by `@ParseEnum` macro and should not be used directly.
@inlinable
public func __match(_ bytes: borrowing [UInt8], in input: inout BinaryParsing.ParserSpan) -> Bool {
    if bytes.isEmpty { return true }

    do {
        try input._checkCount(minimum: bytes.count)
    } catch {
        return false
    }

    let toMatch = unsafe input.bytes.extracting(first: bytes.count).withUnsafeBytes(Array.init)
    return toMatch == bytes
}

/// Matches when the remaining bytes in the input parser span equals the specified length.
/// - Warning: This function is used by `@ParseEnum` macro and should not be used directly.
@inlinable
public func __match(length: Int, in input: borrowing BinaryParsing.ParserSpan) -> Bool {
    input.count == length
}

/// Asserts that the given type conforms to `Parsable`.
/// - Warning: This function is used to `@parse` macro and should not be used directly.
@inlinable
public func __assertParsable(_: (some Parsable).Type) {}

/// Asserts that the given type conforms to `SizedParsable`.
/// - Warning: This function is used to `@parse` macro and should not be used directly.
@inlinable
public func __assertSizedParsable(_: (some SizedParsable).Type) {}

/// Asserts that the given type conforms to `EndianParsable`.
/// - Warning: This function is used to `@parse` macro and should not be used directly.
@inlinable
public func __assertEndianParsable(_: (some EndianParsable).Type) {}

/// Asserts that the given type conforms to `EndianSizedParsable`.
/// - Warning: This function is used to `@parse` macro and should not be used directly.
@inlinable
public func __assertEndianSizedParsable(_: (some EndianSizedParsable).Type) {}

/// Asserts that the given type conforms to `ExpressibleByRawBits`.
/// - Warning: This function is used by `@mask` macro and should not be used directly.
@inlinable
public func __assertExpressibleByRawBits(_: (some ExpressibleByRawBits).Type) {}

/// Asserts that the given type conforms to `BitmaskParsable`.
/// - Warning: This function is used by `@parseBitmask` and `@mask` macros and should not be used directly.
@inlinable
public func __assertBitmaskParsable(_: (some BitmaskParsable).Type) {}

/// Parses a bitmask value from the input span with byte-boundary padding.
///
/// This function reads enough bytes to satisfy the bit count requirement,
/// padding to byte boundaries as needed.
///
/// - Parameters:
///   - type: The type to parse (must conform to BitmaskParsable)
///   - input: The parser span to read from
/// - Returns: The parsed value
/// - Throws: ParsingError if parsing fails
/// - Warning: This function is used by `@parseBitmask` macro and should not be used directly.
@inlinable
public func __parseBitmask<T: BitmaskParsable>(
    _: T.Type,
    from input: inout BinaryParsing.ParserSpan,
) throws(ThrownParsingError) -> T {
    let bitCount = T.bitCount
    let byteCount = (bitCount + 7) / 8

    // Read the required bytes
    let bytes = try input.sliceSpan(byteCount: byteCount)

    // Create RawBits from the bytes using Data
    let data = Data(unsafe bytes.bytes.withUnsafeBytes(Array.init))
    let rawBits = RawBits(data: data, size: bitCount)

    // Initialize the type from raw bits
    do {
        return try T(from: rawBits)
    } catch {
        throw ParsingError(
            userError: BinaryParserKitError
                .failedToParse("Failed to parse \(T.self) from bitmask: \(error)"),
        )
    }
}

/// Parses a value from raw bits with a specified bit count.
///
/// - Parameters:
///   - type: The type to parse (must conform to ExpressibleByRawBits)
///   - bits: The raw bits to parse from
///   - offset: The bit offset to start from
///   - count: The number of bits to extract
/// - Returns: The parsed value
/// - Throws: An error if parsing fails
/// - Warning: This function is used by `@ParseBitmask` macro and should not be used directly.
@inlinable
public func __parseFromBits<T: ExpressibleByRawBits>(
    _: T.Type,
    from bits: borrowing RawBits,
    offset: Int,
    count: Int,
) throws -> T {
    let slicedBits = bits.slice(from: offset, count: count)
    return try T(from: slicedBits)
}
