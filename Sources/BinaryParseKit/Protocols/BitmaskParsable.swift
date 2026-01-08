//
//  BitmaskParsable.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/28/25.
//
import BinaryParsing

/// Errors that can occur during bitmask parsing.
public enum BitmaskParsableError: Error, Sendable {
    /// The bit count is not supported for the target type.
    case unsupportedBitCount
    /// The specified bit count is less than what the type requires (Type.bitCount).
    case insufficientBitsAvailable
}

// MARK: - Core Protocols

/// A protocol for types that can be initialized from a bit sequence.
///
/// Types conforming to this protocol can be constructed from raw bits,
/// enabling bit-level parsing within binary data structures.
///
/// The bits passed to `init(bits:)` are represented as a `RawBitsSpan`,
/// which provides a view into a contiguous sequence of bytes. The bits are:
/// - **MSB-first extracted**: The first bits in the source become the most significant bits
/// - **Starting at index 0**: The bits start from the beginning of the underlying byte span
/// - **Limited by bitCount**: Only `bitCount` bits from the span are considered valid
///
/// For example, extracting 3 bits `0b011` from input `[0b0110_0000]` yields
/// a `RawBitsSpan` where `_bytes` contains `[0b0110_0000]` and `bitCount = 3`.
///
/// - Note: Callee assumes that `bits` contain sufficient bits for the type. For instance,
/// if the type requires 5 bits, the caller must ensure that `bits.bitCount >= 5`.
///
/// Example:
/// ```swift
/// struct Priority: ExpressibleByRawBits {
///     let value: UInt8
///
///     init(bits: borrowing RawBitsSpan) throws {
///         // Extract the value from the bits
///         self.value = bits._bytes.unsafeLoad(fromByteOffset: 0, as: UInt8.self) >> (8 - bits.bitCount)
///     }
/// }
/// ```
public protocol ExpressibleByRawBits {
    /// Creates an instance from extracted bits.
    ///
    /// - Parameter bits: The extracted bits as a span, with bits in MSB-first order
    ///   starting from index 0, and `bitCount` indicating the number of valid bits.
    /// - Throws: An error if the bits cannot be converted to this type
    init(bits: borrowing RawBitsSpan) throws
}

/// A protocol for types that declare their bit width.
///
/// Types conforming to this protocol specify how many bits they occupy
/// when parsed from a bit sequence. This enables automatic bit count
/// calculation in `@mask()` without explicit `bitCount:` parameter.
///
/// Example:
/// ```swift
/// struct Priority: BitCountProviding {
///     static var bitCount: Int { 3 }
/// }
/// ```
public protocol BitCountProviding {
    /// The number of bits this type occupies.
    static var bitCount: Int { get }
}

/// A protocol for types that can be converted to a bit sequence.
///
/// Types conforming to this protocol can produce raw bits representation,
/// enabling bit-level printing/serialization of binary data structures.
/// This is the inverse of ``ExpressibleByRawBits``.
///
/// The returned `RawBits` must have exactly `bitCount` bits, properly padded
/// in MSB-first order. For values smaller than `bitCount` bits, the value
/// should be placed in the most significant bits of the result.
///
/// Example:
/// ```swift
/// struct Priority: RawBitsConvertible {
///     let value: UInt8
///
///     func toRawBits(bitCount: Int) throws -> RawBits {
///         // Value is placed in MSB position, e.g., for 3 bits:
///         // value=5 (0b101) becomes 0b10100000 in the byte
///         let byte = value << (8 - bitCount)
///         return RawBits(data: Data([byte]), size: bitCount)
///     }
/// }
/// ```
public protocol RawBitsConvertible {
    /// Converts this instance to a bit sequence.
    ///
    /// - Parameter bitCount: The number of bits to produce. The returned
    ///   `RawBits` must have exactly this many bits, padded appropriately.
    /// - Returns: The raw bits representation of this value with proper padding
    /// - Throws: An error if the conversion cannot be performed
    func toRawBits(bitCount: Int) throws -> RawBits
}
