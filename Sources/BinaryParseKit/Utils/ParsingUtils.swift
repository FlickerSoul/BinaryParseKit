//
//  EnumParseUtils.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/7/25.
//
import BinaryParsing

/// Matches the given bytes in the input parser span.
/// - Warning: This function is used by `@ParseEnum` macro and should not be used directly.
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

// MARK: - Bitmask Parsing Utilities

/// Asserts that the given type conforms to `BitmaskParsable`.
/// - Warning: This function is used by `@mask()` macro and should not be used directly.
@inlinable
public func __assertBitmaskParsable(_: (some ExpressibleByRawBits & BitCountProviding).Type) {}

/// Asserts that the given type conforms to `ExpressibleByRawBits`.
/// - Warning: This function is used by `@mask(bitCount:)` macro and should not be used directly.
@inlinable
public func __assertExpressibleByRawBits(_: (some ExpressibleByRawBits).Type) {}

/// Extracts bits from a ParserSpan and creates a RawBitsSpan view.
///
/// The bits are extracted in MSB-first order starting from the specified offset.
/// The returned RawBitsSpan provides a view into the source data with additional
/// metadata about bit offset and count.
///
/// - Parameters:
///   - input: The source ParserSpan
///   - offset: Bit offset to start extraction
///   - count: Number of bits to extract
/// - Returns: A RawBitsSpan containing a view of the extracted bits
///
/// Example: Input `[0b0110_1101]` extracting 3 bits at offset 0:
/// - MSB-first extraction: bits 0, 1, 2 → values 0, 1, 1
/// - Result: RawBitsSpan with view into source bytes and `bitCount = 3`
/// - Warning: This function is used by bitmask macros and should not be used directly.
/// - Important: `input` __must__ have at least `(offset + count + 7) / 8` bytes available.
@inlinable
@_lifetime(borrow input)
func __extractBitsAsSpan(
    from input: borrowing BinaryParsing.ParserSpan,
    offset: Int,
    count: Int,
) -> RawBitsSpan {
    precondition(count >= 0, "Count has to be greater than 0")

    let startByte = offset / 8
    let bitOffset = offset % 8
    let bytesNeeded = (bitOffset + count + 7) / 8

    // Extract a slice starting from the byte that contains our first bit
    let slice = input.bytes.extracting(startByte ..< startByte + bytesNeeded)

    // Create a RawBitsSpan that knows about the bit offset and count
    return RawBitsSpan(slice, bitOffset: bitOffset, bitCount: count)
}

// MARK: - RawBits Conversion Utilities

/// Asserts that the given type conforms to `RawBitsConvertible` and `BitCountProviding`.
/// - Warning: This function is used by `@ParseBitmask` macro and should not be used directly.
@inlinable
public func __assertRawBitsConvertible(_: (some RawBitsConvertible & BitCountProviding).Type) {}

/// Converts a value to RawBits with the specified bit count.
/// - Warning: This function is used by bitmask macros and should not be used directly.
/// - Parameters:
///   - value: The value to convert
///   - bitCount: The number of bits to produce
/// - Returns: The raw bits representation
/// - Throws: An error if the conversion cannot be performed
@inlinable
public func __toRawBits(
    _ value: some RawBitsConvertible,
    bitCount: Int,
) throws -> RawBits {
    try value.toRawBits(bitCount: bitCount)
}

// MARK: - Bit Adjustment Utilities for @mask(bitCount:)

/// Overload for types that also conform to BitCountProviding - handles bit count validation and adjustment.
@inlinable
func __createFromBits<T: ExpressibleByRawBits & BitCountProviding>(
    _: T.Type,
    fieldBits: borrowing RawBitsSpan,
    fieldRequestedBitCount: Int,
) throws -> T {
    let typeBitCount = T.bitCount
    if fieldRequestedBitCount < typeBitCount {
        throw BitmaskParsableError.insufficientBitsAvailable
    } else if fieldRequestedBitCount > typeBitCount {
        // Need to adjust the bit count in the span to match what the type expects
        // The extra bits are at the end (LSB side), so we just update bitCount
        let adjustedBitCount = typeBitCount
        let adjustedSpan = RawBitsSpan(
            fieldBits._bytes,
            bitOffset: fieldBits.bitStartIndex,
            bitCount: adjustedBitCount,
        )
        return try T(bits: adjustedSpan)
    } else {
        return try T(bits: fieldBits)
    }
}

/// Fallback overload for types that only conform to ExpressibleByRawBits.
@inlinable
func __createFromBits<T: ExpressibleByRawBits>(
    _: T.Type,
    fieldBits: borrowing RawBitsSpan,
    fieldRequestedBitCount _: Int,
) throws -> T {
    try T(bits: fieldBits)
}

/// Specialized overload for fields that also conform to BitCountProviding - enables bit count validation.
@inlinable
public func __maskParsing<Field: ExpressibleByRawBits & BitCountProviding>(
    from bits: borrowing RawBitsSpan,
    fieldType: Field.Type,
    fieldRequestedBitCount: Int,
    at bitPosition: Int,
) throws -> Field {
    // Extract the field bits from the parent span
    let fieldSpan = RawBitsSpan(
        bits._bytes,
        bitOffset: bits.bitStartIndex + bitPosition,
        bitCount: fieldRequestedBitCount,
    )
    return try __createFromBits(fieldType, fieldBits: fieldSpan, fieldRequestedBitCount: fieldRequestedBitCount)
}

/// Fallback overload for fields that only conform to ExpressibleByRawBits.
@inlinable
public func __maskParsing<Field: ExpressibleByRawBits>(
    from bits: borrowing RawBitsSpan,
    fieldType: Field.Type,
    fieldRequestedBitCount: Int,
    at bitPosition: Int,
) throws -> Field {
    // Extract the field bits from the parent span
    let fieldSpan = RawBitsSpan(
        bits._bytes,
        bitOffset: bits.bitStartIndex + bitPosition,
        bitCount: fieldRequestedBitCount,
    )
    return try __createFromBits(fieldType, fieldBits: fieldSpan, fieldRequestedBitCount: fieldRequestedBitCount)
}

/// Specialized overload for fields that also conform to BitCountProviding - enables bit count validation.
@inlinable
public func __maskParsing<Field: ExpressibleByRawBits & BitCountProviding>(
    from span: borrowing BinaryParsing.ParserSpan,
    fieldType: Field.Type,
    fieldRequestedBitCount: Int,
    at bitOffset: Int,
) throws -> Field {
    let fieldBits = __extractBitsAsSpan(
        from: span,
        offset: bitOffset,
        count: fieldRequestedBitCount,
    )
    return try __createFromBits(fieldType, fieldBits: fieldBits, fieldRequestedBitCount: fieldRequestedBitCount)
}

/// Fallback overload for fields that only conform to ExpressibleByRawBits.
@inlinable
public func __maskParsing<Field: ExpressibleByRawBits>(
    from span: borrowing BinaryParsing.ParserSpan,
    fieldType: Field.Type,
    fieldRequestedBitCount: Int,
    at bitOffset: Int,
) throws -> Field {
    let fieldBits = __extractBitsAsSpan(
        from: span,
        offset: bitOffset,
        count: fieldRequestedBitCount,
    )
    return try __createFromBits(fieldType, fieldBits: fieldBits, fieldRequestedBitCount: fieldRequestedBitCount)
}
