//
//  BitmaskUtils.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 12/23/25.
//

// MARK: - Bit Extraction Utility

/// Extracts a range of bits from a raw integer value.
///
/// This function is used by the `@ParseBitmask` macro to extract individual
/// fields from a bitmask integer. It handles both MSB-first and LSB-first
/// bit ordering.
///
/// - Warning: This function is used by `@ParseBitmask` macro and should not be used directly.
///
/// - Parameters:
///   - rawValue: The source integer containing the bitmask.
///   - startBit: The starting bit position for extraction (0-indexed from the field order).
///   - bitCount: The number of bits to extract.
///   - totalBitCount: The total number of bits in the bitmask.
///   - bitOrder: The bit ordering (MSB-first or LSB-first).
///
/// - Returns: The extracted bits as the target integer type.
@inlinable
public func __extractBits<Source: BinaryInteger, Target: BinaryInteger>(
    from rawValue: Source,
    startBit: Int,
    bitCount: Int,
    totalBitCount: Int,
    bitOrder: BitOrder,
) -> Target {
    // Calculate the actual bit position based on bit order
    let shiftAmount: Int = switch bitOrder {
    case .msbFirst:
        // MSB-first: first field is at the high bits
        // For a 16-bit value with startBit=0, bitCount=4:
        // We want bits 15-12, so shift right by (16 - 0 - 4) = 12
        totalBitCount - startBit - bitCount
    case .lsbFirst:
        // LSB-first: first field is at the low bits
        // For a 16-bit value with startBit=0, bitCount=4:
        // We want bits 3-0, so shift right by 0
        startBit
    }

    // Create a mask with `bitCount` bits set to 1
    let mask: Source = (1 << bitCount) - 1

    // Shift the raw value and apply the mask
    let extracted = (rawValue >> shiftAmount) & mask

    return Target(extracted)
}

// MARK: - ExpressibleByBitmask Assertion Utility

/// Asserts that the given type conforms to `ExpressibleByBitmask`.
///
/// - Warning: This function is used by `@ParseBitmask` macro and should not be used directly.
@inlinable
public func __assertExpressibleByBitmask(_: (some ExpressibleByBitmask).Type) {}
