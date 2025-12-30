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
