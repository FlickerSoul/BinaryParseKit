//
//  FloatingPointExtensions.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 7/16/25.
//
import BinaryParsing

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

    var bitPattern: BitPattern { get }
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
