//
//  CustomExtensions.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 7/16/25.
//
import BinaryParsing

// MARK: - Floating Point Conformances

/// A protocol for types that can be initialized from a bit pattern.
///
/// This protocol enables binary floating-point types to be parsed from
/// their underlying bit representation, allowing for precise control
/// over how floating-point values are interpreted from binary data.
public protocol ExpressibleByBitPattern {
    /// The underlying integer type that represents the bit pattern.
    associatedtype BitPattern: FixedWidthInteger & BitwiseCopyable

    /// Initializes a value from its bit pattern representation.
    ///
    /// - Parameter bitPattern: The bit pattern to interpret as this type
    init(bitPattern: BitPattern)
}

extension Float16: ExpressibleByBitPattern {}
extension Float: ExpressibleByBitPattern {}
extension Double: ExpressibleByBitPattern {}

/// Provides endian-aware parsing for binary floating-point types.
///
/// This extension enables floating-point types (Float, Double, Float16) to be parsed
/// from binary data with explicit endianness control by converting through their
/// underlying bit pattern representation.
public extension BinaryFloatingPoint where Self: BitwiseCopyable & ExpressibleByBitPattern {
    /// Initializes a floating-point value by parsing binary data with the specified endianness.
    ///
    /// - Parameters:
    ///   - input: A mutable parser span containing the binary data to parse
    ///   - endianness: The byte order to use when parsing the underlying bit pattern
    /// - Throws: `ParsingError` if parsing fails
    init(parsing input: inout BinaryParsing.ParserSpan, endianness: BinaryParsing.Endianness) throws(ParsingError) {
        let byteCount = MemoryLayout<Self>.size
        let bitPattern = try BitPattern(parsing: &input, endianness: endianness, byteCount: byteCount)
        self = Self(bitPattern: bitPattern)
    }
}

extension Float: EndianParsable {}
extension Float16: EndianParsable {}
extension Double: EndianParsable {}

// MARK: - Missing Built-In Conformances

extension UInt8: EndianParsable {
    public init(
        parsing input: inout BinaryParsing.ParserSpan,
        endianness: BinaryParsing.Endianness,
    ) throws(ParsingError) {
        try self.init(parsing: &input, endianness: endianness, byteCount: MemoryLayout<Self>.size)
    }
}

extension UInt: EndianParsable {
    public init(
        parsing input: inout BinaryParsing.ParserSpan,
        endianness: BinaryParsing.Endianness,
    ) throws(ParsingError) {
        try self.init(parsing: &input, endianness: endianness, byteCount: MemoryLayout<Self>.size)
    }
}

extension Int8: EndianParsable {
    public init(
        parsing input: inout BinaryParsing.ParserSpan,
        endianness: BinaryParsing.Endianness,
    ) throws(ParsingError) {
        try self.init(parsing: &input, endianness: endianness, byteCount: MemoryLayout<Self>.size)
    }
}

extension Int: EndianParsable {
    public init(
        parsing input: inout BinaryParsing.ParserSpan,
        endianness: BinaryParsing.Endianness,
    ) throws(ParsingError) {
        try self.init(parsing: &input, endianness: endianness, byteCount: MemoryLayout<Self>.size)
    }
}

// MARK: - MatchableRawValue

public extension MatchableRawRepresentable where Self.RawValue == UInt8 {
    func bytesToMatch() -> [UInt8] {
        [rawValue]
    }
}

// MARK: - RawRepresentable

//
// extension RawRepresentable where RawValue: Parsable {
//    init(parsing input: inout ParserSpan) throws(ThrownParsingError) {
//        let rawValue = try RawValue(parsing: &input)
//        guard let value = Self.init(rawValue: rawValue) else {
//            throw ParsingError(userError: BinaryParserKitError.failedToParse("Failed to parse \(Self.self) from raw
//            value \(rawValue)."))
//        }
//
//        self = value
//    }
// }
//
// extension RawRepresentable where RawValue: SizedParsable {
//    init(parsing input: inout ParserSpan, byteCount: Int) throws(ThrownParsingError) {
//        let rawValue = try RawValue(parsing: &input, byteCount: byteCount)
//        guard let value = Self.init(rawValue: rawValue) else {
//            throw ParsingError(userError: BinaryParserKitError.failedToParse("Failed to parse \(Self.self) from raw
//            value \(rawValue)."))
//        }
//
//        self = value
//    }
// }
//
// extension RawRepresentable where RawValue: EndianParsable {
//    public init(parsing input: inout BinaryParsing.ParserSpan, endianness: BinaryParsing.Endianness)
//    throws(ThrownParsingError) {
//        let rawValue = try RawValue(parsing: &input, endianness: endianness)
//        guard let value = Self.init(rawValue: rawValue) else {
//            throw  ParsingError(userError: BinaryParserKitError.failedToParse("Failed to parse \(Self.self) from raw
//            value \(rawValue)."))
//        }
//
//        self = value
//    }
// }
//
// extension RawRepresentable where RawValue: EndianSizedParsable {
//    init(parsing input: inout ParserSpan, endianness: Endianness, byteCount: Int) throws(ThrownParsingError) {
//        let rawValue = try RawValue(parsing: &input, endianness: endianness, byteCount: byteCount)
//        guard let value = Self.init(rawValue: rawValue) else {
//            throw ParsingError(userError: BinaryParserKitError.failedToParse("Failed to parse \(Self.self) from raw
//            value \(rawValue)."))
//        }
//
//        self = value
//    }
// }
