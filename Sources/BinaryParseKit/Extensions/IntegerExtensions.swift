//
//  IntegerExtensions.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 7/16/25.
//
import BinaryParsing

extension UInt8: @retroactive ExpressibleByParsing {}
extension UInt8: EndianSizedParsable {}
extension UInt16: EndianSizedParsable, EndianParsable {}
extension UInt32: EndianSizedParsable, EndianParsable {}
extension UInt: EndianSizedParsable {}
extension UInt64: EndianSizedParsable, EndianParsable {}

extension Int8: EndianSizedParsable {}
extension Int16: EndianSizedParsable, EndianParsable {}
extension Int32: EndianSizedParsable, EndianParsable {}
extension Int: EndianSizedParsable {}
extension Int64: EndianSizedParsable, EndianParsable {}

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
