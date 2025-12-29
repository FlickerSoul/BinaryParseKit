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

/// A protocol combining `ExpressibleByRawBits` and `BitCountProviding`.
///
/// Types conforming to this protocol can be fully parsed from bits
/// with a known, fixed width. Use this for types that have a
/// compile-time-known bit size.
///
/// This protocol enables the use of `@mask()` without explicit bit count:
/// ```swift
/// @ParseStruct
/// struct Header {
///     @mask() var priority: Priority  // Uses Priority.bitCount
///     @mask() var enabled: Bool       // Uses Bool.bitCount (1)
/// }
/// ```
public protocol BitmaskParsable: ExpressibleByRawBits, BitCountProviding {}

// MARK: - Bool Conformance

extension Bool: ExpressibleByRawBits {
    public init(bits: RawBits) throws {
        guard bits.size >= 1 else {
            throw BitmaskParsableError.insufficientBits
        }
        self = bits.bit(at: 0)
    }
}

extension Bool: BitCountProviding {
    public static var bitCount: Int { 1 }
}

extension Bool: BitmaskParsable {}

// MARK: - Integer Conformances

extension UInt8: ExpressibleByRawBits {
    public init(bits: RawBits) throws {
        guard bits.size <= 8 else {
            throw BitmaskParsableError.unsupportedBitCount
        }
        self = UInt8(bits.extractBits(from: 0, count: bits.size))
    }
}

extension UInt8: BitCountProviding {
    public static var bitCount: Int { 8 }
}

extension UInt8: BitmaskParsable {}

extension UInt16: ExpressibleByRawBits {
    public init(bits: RawBits) throws {
        guard bits.size <= 16 else {
            throw BitmaskParsableError.unsupportedBitCount
        }
        self = UInt16(bits.extractBits(from: 0, count: bits.size))
    }
}

extension UInt16: BitCountProviding {
    public static var bitCount: Int { 16 }
}

extension UInt16: BitmaskParsable {}

extension UInt32: ExpressibleByRawBits {
    public init(bits: RawBits) throws {
        guard bits.size <= 32 else {
            throw BitmaskParsableError.unsupportedBitCount
        }
        self = UInt32(bits.extractBits(from: 0, count: bits.size))
    }
}

extension UInt32: BitCountProviding {
    public static var bitCount: Int { 32 }
}

extension UInt32: BitmaskParsable {}

extension UInt64: ExpressibleByRawBits {
    public init(bits: RawBits) throws {
        guard bits.size <= 64 else {
            throw BitmaskParsableError.unsupportedBitCount
        }
        self = bits.extractBits(from: 0, count: bits.size)
    }
}

extension UInt64: BitCountProviding {
    public static var bitCount: Int { 64 }
}

extension UInt64: BitmaskParsable {}

extension Int8: ExpressibleByRawBits {
    public init(bits: RawBits) throws {
        guard bits.size <= 8 else {
            throw BitmaskParsableError.unsupportedBitCount
        }
        self = Int8(bitPattern: UInt8(bits.extractBits(from: 0, count: bits.size)))
    }
}

extension Int8: BitCountProviding {
    public static var bitCount: Int { 8 }
}

extension Int8: BitmaskParsable {}

extension Int16: ExpressibleByRawBits {
    public init(bits: RawBits) throws {
        guard bits.size <= 16 else {
            throw BitmaskParsableError.unsupportedBitCount
        }
        self = Int16(bitPattern: UInt16(bits.extractBits(from: 0, count: bits.size)))
    }
}

extension Int16: BitCountProviding {
    public static var bitCount: Int { 16 }
}

extension Int16: BitmaskParsable {}

extension Int32: ExpressibleByRawBits {
    public init(bits: RawBits) throws {
        guard bits.size <= 32 else {
            throw BitmaskParsableError.unsupportedBitCount
        }
        self = Int32(bitPattern: UInt32(bits.extractBits(from: 0, count: bits.size)))
    }
}

extension Int32: BitCountProviding {
    public static var bitCount: Int { 32 }
}

extension Int32: BitmaskParsable {}

extension Int64: ExpressibleByRawBits {
    public init(bits: RawBits) throws {
        guard bits.size <= 64 else {
            throw BitmaskParsableError.unsupportedBitCount
        }
        self = Int64(bitPattern: bits.extractBits(from: 0, count: bits.size))
    }
}

extension Int64: BitCountProviding {
    public static var bitCount: Int { 64 }
}

extension Int64: BitmaskParsable {}
