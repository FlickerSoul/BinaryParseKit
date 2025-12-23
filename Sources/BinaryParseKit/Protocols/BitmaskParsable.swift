//
//  BitmaskParsable.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/28/25.
//
import BinaryParsing

// MARK: - BitOrder

/// Defines bit ordering options within bytes for bitmask parsing.
///
/// When parsing bitmasks, the bit order determines which bit position
/// corresponds to the first field in the bitmask struct.
public enum BitOrder: Sendable {
    /// Most significant bit comes first (bit 7 of byte 0 is the first field).
    ///
    /// This is the default and matches typical protocol documentation where
    /// the first field listed corresponds to the high bits.
    case msbFirst

    /// Least significant bit comes first (bit 0 of byte 0 is the first field).
    ///
    /// Use this when the protocol specifies that fields start from the
    /// low bit positions.
    case lsbFirst
}

// MARK: - BitmaskParsableError

public enum BitmaskParsableError: Error {
    case unsupportedBitCount
    case invalidEnumRawValue
    case missingEndianness
    case unexpectedError(description: String)
}

// MARK: - ExpressibleByBitmask Protocol

/// A protocol for types that can be constructed from a bitmask integer.
///
/// Types conforming to this protocol can be initialized by extracting
/// bits from a raw integer value.
public protocol ExpressibleByBitmask {
    associatedtype RawValue: BinaryInteger & BitwiseCopyable

    /// Creates an instance by extracting bits from the given raw value.
    ///
    /// - Parameter bitmask: The raw integer value containing the bitmask bits.
    /// - Throws: `BitmaskParsableError` if the bitmask contains invalid data.
    init(bitmask: RawValue) throws(BitmaskParsableError)
}

// MARK: - BitmaskParsable Protocol

/// A protocol that combines `Parsable`, `SizedParsable`, and `ExpressibleByBitmask`
/// for types that parse binary bitmasks.
///
/// Types conforming to this protocol can parse binary data into structured
/// bitmask fields with configurable bit ordering and endianness.
public protocol BitmaskParsable: Parsable, SizedParsable, ExpressibleByBitmask {
    /// The total number of bits in this bitmask.
    static var bitCount: Int { get }

    /// The byte order for multi-byte bitmasks.
    ///
    /// This should be `nil` for single-byte bitmasks (8 bits or fewer).
    /// For multi-byte bitmasks, this must be specified.
    static var endianness: Endianness? { get }

    /// The bit ordering within bytes.
    ///
    /// Defaults to `.msbFirst` (most significant bit first).
    static var bitOrder: BitOrder { get }
}

// MARK: - Default Implementations

public extension BitmaskParsable {
    /// Default bit order is MSB-first.
    static var bitOrder: BitOrder { .msbFirst }

    /// Default endianness is `nil` (for single-byte bitmasks).
    static var endianness: Endianness? { nil }

    /// Computes the byte count from the bit count, rounding up to the next byte boundary.
    static var byteCount: Int { (bitCount + 7) / 8 }
}

// MARK: - BitmaskParsable Parsing Implementation

public extension BitmaskParsable where RawValue: FixedWidthInteger {
    init(parsing span: inout ParserSpan) throws(ThrownParsingError) {
        try self.init(parsing: &span, byteCount: Self.byteCount)
    }

    init(parsing span: inout ParserSpan, byteCount: Int) throws(ThrownParsingError) {
        let bitCount = Self.bitCount
        let requiredBytes = (bitCount + 7) / 8

        // Validate endianness for multi-byte bitmasks
        if requiredBytes > 1, Self.endianness == nil {
            throw BitmaskParsableError.missingEndianness
        }

        // Read the raw bytes into an integer
        let rawValue: RawValue
        if requiredBytes == 1 {
            // Single byte: read directly
            let byte = try UInt8(parsing: &span)
            rawValue = RawValue(byte)
        } else {
            // Multi-byte: use endianness
            guard let endianness = Self.endianness else {
                throw BitmaskParsableError.missingEndianness
            }

            switch endianness {
            case .big:
                rawValue = try RawValue(parsingBigEndian: &span, byteCount: byteCount)
            case .little:
                rawValue = try RawValue(parsingLittleEndian: &span, byteCount: byteCount)
            default:
                throw BitmaskParsableError.unexpectedError(description: "Unknown endianness \(endianness)")
            }
        }

        try self.init(bitmask: rawValue)
    }
}
