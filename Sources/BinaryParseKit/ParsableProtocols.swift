//
//  BinaryParsable.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 7/15/25.
//
import BinaryParsing

/// A type alias for the `ExpressibleByParsing` protocol from the BinaryParsing framework.
///
/// This provides a convenient shorthand for types that can be parsed from binary data
/// using the default parsing behavior.
public typealias Parsable = ExpressibleByParsing

/// A protocol for types that can be parsed from binary data with endianness specification.
///
/// Types conforming to this protocol can be initialized from binary data
/// with explicit control over byte order (big-endian or little-endian).
///
/// This is useful for parsing data from different platforms or network protocols
/// where byte order matters.
public protocol EndianParsable {
    /// Initializes a value by parsing binary data with the specified endianness.
    ///
    /// - Parameters:
    ///   - input: A mutable parser span containing the binary data to parse
    ///   - endianness: The byte order to use when parsing multi-byte values
    /// - Throws: `ThrownParsingError` if parsing fails
    @lifetime(&input)
    init(parsing input: inout ParserSpan, endianness: Endianness) throws(ThrownParsingError)
}

/// Default implementation providing a convenience initializer for `EndianParsable` types.
///
/// This extension provides a high-level interface for parsing endian-aware types
/// from any `RandomAccessCollection<UInt8>` (such as `Data` or `[UInt8]`).
public extension EndianParsable {
    init(
        parsing data: some RandomAccessCollection<UInt8>,
        endianness: BinaryParsing.Endianness,
    ) throws(ThrownParsingError) {
        let result: Self?

        result = try data.withParserSpanIfAvailable { span throws(ThrownParsingError) in
            try Self(parsing: &span, endianness: endianness)
        }

        guard let result else {
            throw ParsingError(
                userError: BinaryParserKitError
                    .failedToParse("Failed to parse \(Self.self) from data."),
            )
        }

        self = result
    }
}

/// A protocol for types that can be parsed from binary data with both endianness and size specification.
///
/// Types conforming to this protocol can be initialized from binary data
/// with explicit control over both byte order and the number of bytes to read.
///
/// This is useful for parsing variable-sized data or when you need to read
/// fewer bytes than the type's natural size.
public protocol EndianSizedParsable {
    /// Initializes a value by parsing a specific number of bytes with the specified endianness.
    ///
    /// - Parameters:
    ///   - input: A mutable parser span containing the binary data to parse
    ///   - endianness: The byte order to use when parsing multi-byte values
    ///   - byteCount: The number of bytes to read from the input
    /// - Throws: `ThrownParsingError` if parsing fails
    @lifetime(&input)
    init(parsing input: inout ParserSpan, endianness: Endianness, byteCount: Int) throws(ThrownParsingError)
}

/// Default implementation providing a convenience initializer for `EndianSizedParsable` types.
///
/// This extension provides a high-level interface for parsing endian and size-aware types
/// from any `RandomAccessCollection<UInt8>` (such as `Data` or `[UInt8]`).
public extension EndianSizedParsable {
    init(
        parsing data: some RandomAccessCollection<UInt8>,
        endianness: BinaryParsing.Endianness,
        byteCount: Int,
    ) throws(ThrownParsingError) {
        let result: Self?

        result = try data.withParserSpanIfAvailable { span throws(ThrownParsingError) in
            try Self(parsing: &span, endianness: endianness, byteCount: byteCount)
        }

        guard let result else {
            throw ParsingError(
                userError: BinaryParserKitError
                    .failedToParse("Failed to parse \(Self.self) from data."),
            )
        }

        self = result
    }
}

/// A protocol for types that can be parsed from binary data with size specification.
///
/// Types conforming to this protocol can be initialized from binary data
/// with explicit control over the number of bytes to read.
///
/// This is useful for parsing variable-sized data or when you need to read
/// fewer bytes than the type's natural size.
public protocol SizedParsable {
    /// Initializes a value by parsing a specific number of bytes from binary data.
    ///
    /// - Parameters:
    ///   - input: A mutable parser span containing the binary data to parse
    ///   - byteCount: The number of bytes to read from the input
    /// - Throws: `ThrownParsingError` if parsing fails
    @lifetime(&input)
    init(parsing input: inout ParserSpan, byteCount: Int) throws(ThrownParsingError)
}

/// Default implementation providing a convenience initializer for `SizedParsable` types.
///
/// This extension provides a high-level interface for parsing size-aware types
/// from any `RandomAccessCollection<UInt8>` (such as `Data` or `[UInt8]`).
public extension SizedParsable {
    init(parsing data: some RandomAccessCollection<UInt8>, byteCount: Int) throws(ThrownParsingError) {
        let result: Self?

        result = try data.withParserSpanIfAvailable { span throws(ThrownParsingError) in
            try Self(parsing: &span, byteCount: byteCount)
        }

        guard let result else {
            throw ParsingError(
                userError: BinaryParserKitError
                    .failedToParse("Failed to parse \(Self.self) from data."),
            )
        }

        self = result
    }
}
