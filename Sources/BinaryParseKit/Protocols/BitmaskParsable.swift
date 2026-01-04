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
    /// The bit pattern is invalid for the target type.
    case invalidBitPattern
    /// Not enough bits available in the buffer.
    case insufficientBits
}

// MARK: - Core Protocols

/// A protocol for types that can be initialized from a bit sequence.
///
/// Types conforming to this protocol can be constructed from raw bits,
/// enabling bit-level parsing within binary data structures.
///
/// Example:
/// ```swift
/// struct Priority: ExpressibleByRawBits {
///     let value: UInt8
///
///     init(bits: RawBits) throws {
///         guard bits.size <= 8 else {
///             throw BitmaskParsableError.unsupportedBitCount
///         }
///         self.value = UInt8(bits.extractBits(from: 0, count: bits.size))
///     }
/// }
/// ```
public protocol ExpressibleByRawBits {
    /// Creates an instance from a bit sequence.
    ///
    /// - Parameter bits: The raw bits to parse
    /// - Throws: An error if the bits cannot be converted to this type
    init(bits: RawBits) throws
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
