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

/// Extracts bits from a ParserSpan and returns them as a right-aligned FixedWidthInteger.
///
/// The bits are extracted in MSB-first order and returned right-aligned in the integer.
/// Excess bits in the integer are masked to 0.
///
/// - Parameters:
///   - type: The integer type to return
///   - input: The source ParserSpan
///   - offset: Bit offset to start extraction
///   - count: Number of bits to extract
/// - Returns: The extracted bits right-aligned in the integer with excess bits masked to 0
///
/// Example: Input `[0b0110_1101]` extracting 3 bits at offset 0:
/// - MSB-first extraction: bits 0, 1, 2 → values 0, 1, 1
/// - Right-aligned result: 0b0000_0011 = 3
/// - Warning: This function is used by bitmask macros and should not be used directly.
/// - Important: `input` but have at least `(offset + count + 7) / 8` bytes available.
@inlinable
func __extractBitsAsInteger<I: FixedWidthInteger>(
    _: I.Type,
    from input: borrowing BinaryParsing.ParserSpan,
    offset: Int,
    count: Int,
) throws -> I {
    precondition(count >= 0, "Count has to be grater than 0")

    guard count <= I.bitWidth else {
        throw BitmaskParsableError.rawBitsIntegerNotWideEnough
    }

    guard count > 0 else { return 0 }

    let startByte = offset / 8
    let bitOffset = offset % 8
    let dataSpan = input.bytes

    // For small extractions (up to 8 bits), use optimized single/double byte path
    if count <= 8 {
        var value: UInt8
        if bitOffset + count <= 8 {
            // Single byte extraction
            value = unsafe dataSpan.unsafeLoad(fromByteOffset: startByte, as: UInt8.self)
            value <<= bitOffset
            value >>= (8 - count)
        } else {
            // Two byte extraction
            let highByte = unsafe dataSpan.unsafeLoad(fromByteOffset: startByte, as: UInt8.self)
            let lowByte = unsafe dataSpan.unsafeLoad(fromByteOffset: startByte + 1, as: UInt8.self)
            let combined = (UInt16(highByte) << 8) | UInt16(lowByte)
            value = UInt8((combined << bitOffset) >> (16 - count))
        }
        return I(value)
    }

    // For larger extractions, build the integer using << and | for speed
    var result: I = 0
    var bitsRemaining = count
    var currentByteIndex = startByte
    var currentBitOffset = bitOffset

    while bitsRemaining > 0 {
        let bitsInCurrentByte = min(8 - currentBitOffset, bitsRemaining)
        let byte = unsafe dataSpan.unsafeLoad(fromByteOffset: currentByteIndex, as: UInt8.self)

        // Extract bits from this byte: shift left to clear leading bits, shift right to position
        let extracted = (byte << currentBitOffset) >> (8 - bitsInCurrentByte)

        // Add to result
        result = (result << bitsInCurrentByte) | I(extracted)

        bitsRemaining -= bitsInCurrentByte
        currentByteIndex += 1
        currentBitOffset = 0
    }

    // The result is already right-aligned and masked by construction
    return result
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
    fieldBits: some FixedWidthInteger,
    fieldRequestedBitCount: Int,
) throws -> T {
    let typeBitCount = T.bitCount
    if fieldRequestedBitCount < typeBitCount {
        throw BitmaskParsableError.insufficientBitsAvailable
    } else if fieldRequestedBitCount > typeBitCount {
        let adjustedBits = fieldBits >> (fieldRequestedBitCount - typeBitCount)
        return try T(bits: T.RawBitsInteger(truncatingIfNeeded: adjustedBits))
    } else {
        return try T(bits: T.RawBitsInteger(truncatingIfNeeded: fieldBits))
    }
}

/// Fallback overload for types that only conform to ExpressibleByRawBits.
@inlinable
func __createFromBits<T: ExpressibleByRawBits>(
    _: T.Type,
    fieldBits: some FixedWidthInteger,
    fieldRequestedBitCount _: Int,
) throws -> T {
    try T(bits: T.RawBitsInteger(truncatingIfNeeded: fieldBits))
}

/// Specialized overload for fields that also conform to BitCountProviding - enables bit count validation.
@inlinable
public func __maskParsing<Parent: ExpressibleByRawBits, Field: ExpressibleByRawBits & BitCountProviding>(
    from bits: Parent.RawBitsInteger,
    parentType _: Parent.Type,
    fieldType: Field.Type,
    fieldRequestedBitCount: Int,
    at bitPosition: Int,
) throws -> Field {
    let shift = Parent.RawBitsInteger.bitWidth - bitPosition - fieldRequestedBitCount
    let mask: Parent.RawBitsInteger = (1 << fieldRequestedBitCount) &- 1
    let fieldBits: Parent.RawBitsInteger = (bits >> shift) & mask

    return try __createFromBits(fieldType, fieldBits: fieldBits, fieldRequestedBitCount: fieldRequestedBitCount)
}

/// Fallback overload for fields that only conform to ExpressibleByRawBits.
@inlinable
public func __maskParsing<Parent: ExpressibleByRawBits, Field: ExpressibleByRawBits>(
    from bits: Parent.RawBitsInteger,
    parentType _: Parent.Type,
    fieldType: Field.Type,
    fieldRequestedBitCount: Int,
    at bitPosition: Int,
) throws -> Field {
    let shift = Parent.RawBitsInteger.bitWidth - bitPosition - fieldRequestedBitCount
    let mask: Parent.RawBitsInteger = (1 << fieldRequestedBitCount) &- 1
    let fieldBits: Parent.RawBitsInteger = (bits >> shift) & mask

    return try __createFromBits(fieldType, fieldBits: fieldBits, fieldRequestedBitCount: fieldRequestedBitCount)
}

/// Specialized overload for fields that also conform to BitCountProviding - enables bit count validation.
@inlinable
public func __maskParsing<Field: ExpressibleByRawBits & BitCountProviding>(
    from span: borrowing BinaryParsing.ParserSpan,
    fieldType: Field.Type,
    fieldRequestedBitCount: Int,
    at bitOffset: Int,
) throws -> Field {
    let fieldBits = try __extractBitsAsInteger(
        UInt64.self,
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
    let fieldBits = try __extractBitsAsInteger(
        UInt64.self,
        from: span,
        offset: bitOffset,
        count: fieldRequestedBitCount,
    )
    return try __createFromBits(fieldType, fieldBits: fieldBits, fieldRequestedBitCount: fieldRequestedBitCount)
}
