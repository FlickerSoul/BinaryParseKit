//
//  BitmaskParsable.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/28/25.
//

import BinaryParsing

/// Error type for bitmask parsing operations.
public enum BitmaskParsableError: Error {
    /// The bit count is not supported for the target type.
    case unsupportedBitCount

    /// There are insufficient bits available for parsing.
    case insufficientBits(required: Int, available: Int)
}

/// A protocol for types that can be initialized from raw bits.
///
/// Types conforming to this protocol can be constructed from a `RawBits` instance,
/// which provides access to a sequence of bits.
///
/// Use this protocol when you need to specify an explicit bit count with `@mask(bitCount:)`.
public protocol ExpressibleByRawBits {
    /// Initializes a value from raw bits.
    ///
    /// - Parameter bits: The raw bits to construct the value from
    /// - Throws: An error if the bits cannot be converted to this type
    init(from bits: borrowing RawBits) throws
}

/// A protocol for types that can be parsed as bitmasks with a known bit count.
///
/// Types conforming to this protocol can be used with `@parseBitmask` and `@mask`
/// attributes. They must specify their bit count and provide an initializer
/// that constructs the type from raw bits.
///
/// Use this protocol when the type has a fixed, known bit width.
public protocol BitmaskParsable: ExpressibleByRawBits {
    /// The number of bits this type consumes when parsing.
    static var bitCount: Int { get }
}
