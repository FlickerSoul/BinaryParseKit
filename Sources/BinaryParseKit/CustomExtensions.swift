//
//  CustomExtensions.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 7/16/25.
//
import BinaryParseKitCommons
import BinaryParsing

// MARK: - Floating Point Conformances

public protocol ExpressibleByBitPattern {
    associatedtype BitPattern: FixedWidthInteger & BitwiseCopyable
    init(bitPattern: BitPattern)
}

extension Float16: ExpressibleByBitPattern {}
extension Float: ExpressibleByBitPattern {}
extension Double: ExpressibleByBitPattern {}

public extension BinaryFloatingPoint where Self: BitwiseCopyable & ExpressibleByBitPattern {
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
        endianness: BinaryParsing.Endianness
    ) throws(ParsingError) {
        try self.init(parsing: &input, endianness: endianness, byteCount: MemoryLayout<Self>.size)
    }
}

extension UInt: EndianParsable {
    public init(
        parsing input: inout BinaryParsing.ParserSpan,
        endianness: BinaryParsing.Endianness
    ) throws(ParsingError) {
        try self.init(parsing: &input, endianness: endianness, byteCount: MemoryLayout<Self>.size)
    }
}

extension Int8: EndianParsable {
    public init(
        parsing input: inout BinaryParsing.ParserSpan,
        endianness: BinaryParsing.Endianness
    ) throws(ParsingError) {
        try self.init(parsing: &input, endianness: endianness, byteCount: MemoryLayout<Self>.size)
    }
}

extension Int: EndianParsable {
    public init(
        parsing input: inout BinaryParsing.ParserSpan,
        endianness: BinaryParsing.Endianness
    ) throws(ParsingError) {
        try self.init(parsing: &input, endianness: endianness, byteCount: MemoryLayout<Self>.size)
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
