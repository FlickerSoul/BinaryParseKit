//
//  TestStructParsing.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 7/17/25.
//

import BinaryParseKit
import BinaryParsing
import Foundation
import Testing

@Suite
struct StructParsingTest {
    @ParseStruct
    struct DataLargerParseBE {
        @parse(byteCount: 4, endianness: .big)
        let first: Int16

        @parse(byteCount: 2, endianness: .big)
        let second: Int16
    }

    @Test("Data instance is larger than needed (BE)")
    func bigEndianDataLargeParse() {
        #expect(throws: ParsingError.self) {
            _ = try DataLargerParseBE(parsing: Data([1, 2, 3, 4, 5, 6]))
        }
    }

    @ParseStruct
    struct DataLargerParseLE {
        @parse(byteCount: 4, endianness: .little)
        let first: Int16

        @parse(byteCount: 2, endianness: .little)
        let second: Int16
    }

    @Test("Data instance is larger than needed (LE)")
    func littleEndianDataLargeParse() {
        #expect(throws: ParsingError.self) {
            _ = try DataLargerParseLE(parsing: Data([1, 2, 3, 4, 5, 6]))
        }
    }

    @ParseStruct
    struct DataExactParseBE {
        @parse(byteCount: 4, endianness: .big)
        let first: Int32

        @parse(byteCount: 2, endianness: .big)
        let second: Int16
    }

    @Test("Data instance is exactly sized (BE)")
    func bigEndianDataExactParse() {
        #expect(throws: Never.self) {
            let parsed = try DataExactParseBE(parsing: Data([1, 2, 3, 4, 5, 6]))
            #expect(parsed.first == 0x0102_0304)
            #expect(parsed.second == 0x0506)
        }
    }

    @ParseStruct
    struct DataExactParseLE {
        @parse(byteCount: 4, endianness: .little)
        let first: Int32

        @parse(byteCount: 2, endianness: .little)
        let second: Int16
    }

    @Test("Data instance is exactly sized (LE)")
    func littleEndianDataExactParse() {
        #expect(throws: Never.self) {
            let parsed = try DataExactParseLE(parsing: Data([1, 2, 3, 4, 5, 6]))
            #expect(parsed.first == 0x0403_0201)
            #expect(parsed.second == 0x0605)
        }
    }

    @ParseStruct
    struct BigEndiannessMixedEndianParse {
        @parse(byteCount: 2, endianness: .big)
        let first: Int16

        @parse(byteCount: 2, endianness: .little)
        let second: Int16

        @parse(byteCount: 2, endianness: .big)
        let third: UInt16
    }

    @Test("Mixed endianness (BE, LE)")
    func mixedEndianness_BE_LE() {
        #expect(throws: Never.self) {
            let parsed = try BigEndiannessMixedEndianParse(parsing: Data([1, 2, 3, 4, 5, 6]))
            #expect(parsed.first == 0x0102)
            #expect(parsed.second == 0x0403)
            #expect(parsed.third == 0x0506)
        }
    }

    @ParseStruct
    struct LittleEndianMixedEndianParse {
        @parse(byteCount: 2, endianness: .little)
        let first: Int16

        @parse(byteCount: 2, endianness: .big)
        let second: Int16

        @parse(byteCount: 2, endianness: .little)
        let third: UInt16
    }

    @Test("Mixed endianness (LE, BE)")
    func mixedEndianness_LE_BE() {
        #expect(throws: Never.self) {
            let parsed = try LittleEndianMixedEndianParse(parsing: Data([1, 2, 3, 4, 5, 6]))
            #expect(parsed.first == 0x0201)
            #expect(parsed.second == 0x0304)
            #expect(parsed.third == 0x0605)
        }
    }

    @ParseStruct
    struct BasicTypeParseBE {
        @parse(endianness: .big)
        let int8: Int8

        @parse(endianness: .big)
        let uint8: UInt8

        @parse(endianness: .big)
        let int16: Int16

        @parse(endianness: .big)
        let uint16: UInt16

        @parse(endianness: .big)
        let int32: Int32

        @parse(endianness: .big)
        let uint32: UInt32

        @parse(endianness: .big)
        let int64: Int64

        @parse(endianness: .big)
        let uint64: UInt64

        @parse(endianness: .big)
        let float16: Float16

        @parse(endianness: .big)
        let float: Float

        @parse(endianness: .big)
        let double: Double
    }

    @Test("Basic types (BE)")
    func bigEndianBasicTypeParse() {
        #expect(throws: Never.self) {
            let parsed = try BasicTypeParseBE(
                parsing: Data([
                    // int8 (1 byte)
                    0x01,
                    // uint8 (1 byte)
                    0x02,
                    // int16 (2 bytes, BE): 0x0304
                    0x03, 0x04,
                    // uint16 (2 bytes, BE): 0x0506
                    0x05, 0x06,
                    // int32 (4 bytes, BE): 0x0708090A
                    0x07, 0x08, 0x09, 0x0A,
                    // uint32 (4 bytes, BE): 0x0B0C0D0E
                    0x0B, 0x0C, 0x0D, 0x0E,
                    // int64 (8 bytes, BE): 0x0F10111213141516
                    0x0F, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16,
                    // uint64 (8 bytes, BE): 0x1718191A1B1C1D1E
                    0x17, 0x18, 0x19, 0x1A, 0x1B, 0x1C, 0x1D, 0x1E,
                    // float16 (2 bytes, BE): 1.0 encoded as 0x3C00
                    0x3C, 0x00,
                    // float (4 bytes, BE): 1.0 encoded as 0x3F800000
                    0x3F, 0x80, 0x00, 0x00,
                    // double (8 bytes, BE): 1.0 encoded as 0x3FF0000000000000
                    0x3F, 0xF0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                ]),
            )
            #expect(parsed.int8 == 0x01)
            #expect(parsed.uint8 == 0x02)
            #expect(parsed.int16 == 0x0304)
            #expect(parsed.uint16 == 0x0506)
            #expect(parsed.int32 == 0x0708_090A)
            #expect(parsed.uint32 == 0x0B0C_0D0E)
            #expect(parsed.int64 == 0x0F10_1112_1314_1516)
            #expect(parsed.uint64 == 0x1718_191A_1B1C_1D1E)
            #expect(parsed.float16 == 1.0)
            #expect(parsed.float == 1.0)
            #expect(parsed.double == 1.0)
        }
    }

    @ParseStruct
    struct BasicTypeParseLE {
        @parse(endianness: .little)
        let int8: Int8

        @parse(endianness: .little)
        let uint8: UInt8

        @parse(endianness: .little)
        let int16: Int16

        @parse(endianness: .little)
        let uint16: UInt16

        @parse(endianness: .little)
        let int32: Int32

        @parse(endianness: .little)
        let uint32: UInt32

        @parse(endianness: .little)
        let int64: Int64

        @parse(endianness: .little)
        let uint64: UInt64

        @parse(endianness: .little)
        let float16: Float16

        @parse(endianness: .little)
        let float: Float

        @parse(endianness: .little)
        let double: Double
    }

    @available(iOS 14.0, *)
    @Test("Basic types (LE)")
    func littleEndianBasicTypeParse() {
        #expect(throws: Never.self) {
            let parsed = try BasicTypeParseLE(
                parsing: Data([
                    // int8 (1 byte)
                    0x01,
                    // uint8 (1 byte)
                    0x02,
                    // int16 (2 bytes, LE): bytes reversed from BE's [0x03, 0x04] -> [0x04, 0x03] equals 0x0304
                    0x04, 0x03,
                    // uint16 (2 bytes, LE): [0x06, 0x05] equals 0x0506
                    0x06, 0x05,
                    // int32 (4 bytes, LE): [0x0A, 0x09, 0x08, 0x07] equals 0x0708090A
                    0x0A, 0x09, 0x08, 0x07,
                    // uint32 (4 bytes, LE): [0x0E, 0x0D, 0x0C, 0x0B] equals 0x0B0C0D0E
                    0x0E, 0x0D, 0x0C, 0x0B,
                    // int64 (8 bytes, LE): [0x16, 0x15, 0x14, 0x13, 0x12, 0x11, 0x10, 0x0F] equals 0x0F10111213141516
                    0x16, 0x15, 0x14, 0x13, 0x12, 0x11, 0x10, 0x0F,
                    // uint64 (8 bytes, LE): [0x1E, 0x1D, 0x1C, 0x1B, 0x1A, 0x19, 0x18, 0x17] equals 0x1718191A1B1C1D1E
                    0x1E, 0x1D, 0x1C, 0x1B, 0x1A, 0x19, 0x18, 0x17,
                    // float16 (2 bytes, LE): [0x00, 0x3C] equals 0x3C00 which represents 1.0
                    0x00, 0x3C,
                    // float (4 bytes, LE): [0x00, 0x00, 0x80, 0x3F] equals 0x3F800000 which represents 1.0
                    0x00, 0x00, 0x80, 0x3F,
                    // double (8 bytes, LE): [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF0, 0x3F] equals 0x3FF0000000000000
                    // which represents 1.0
                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF0, 0x3F,
                ]),
            )
            #expect(parsed.int8 == 0x01)
            #expect(parsed.uint8 == 0x02)
            #expect(parsed.int16 == 0x0304)
            #expect(parsed.uint16 == 0x0506)
            #expect(parsed.int32 == 0x0708_090A)
            #expect(parsed.uint32 == 0x0B0C_0D0E)
            #expect(parsed.int64 == 0x0F10_1112_1314_1516)
            #expect(parsed.uint64 == 0x1718_191A_1B1C_1D1E)
            #expect(parsed.float16 == 1.0)
            #expect(parsed.float == 1.0)
            #expect(parsed.double == 1.0)
        }
    }

    @ParseStruct
    struct ParseStructSkipBE {
        @skip(byteCount: 4, because: "redundant header")
        @parse(byteCount: 2, endianness: .big)
        var int16: Int16

        @parse(byteCount: 1, endianness: .big)
        var int8: Int8

        @skip(byteCount: 2, because: "padding")
        @parse(endianness: .big)
        var float16: Float16
    }

    @Test("Skip bytes (BE)")
    func bigEndianSkip() {
        #expect(throws: Never.self) {
            let parsed = try ParseStructSkipBE(
                parsing: Data([
                    0x01, 0x02, 0x03, 0x04, // skip
                    0x05, 0x06, // int16
                    0x17, // int8
                    0x08, 0x09, // skip
                    0x3C, 0x00, // float16
                ]),
            )

            #expect(parsed.int16 == 0x0506)
            #expect(parsed.int8 == 0x17)
            #expect(parsed.float16 == 1.0)
        }
    }

    @ParseStruct
    struct ParseStructSkipLE {
        @skip(byteCount: 4, because: "redundant header")
        @parse(byteCount: 2, endianness: .little)
        var int16: Int16

        @parse(byteCount: 1, endianness: .little)
        var int8: Int8

        @skip(byteCount: 2, because: "padding")
        @parse(endianness: .little)
        var float16: Float16
    }

    @available(iOS 14.0, *)
    @Test("Skip bytes (LE)")
    func littleEndianSkip() {
        #expect(throws: Never.self) {
            let parsed = try ParseStructSkipLE(
                parsing: Data([
                    0x01, 0x02, 0x03, 0x04, // skip
                    0x05, 0x06, // int16
                    0x17, // int8
                    0x08, 0x09, // skip
                    0x00, 0x3C, // float16
                ]),
            )

            #expect(parsed.int16 == 0x0605)
            #expect(parsed.int8 == 0x17)
            #expect(parsed.float16 == 1.0)
        }
    }

    @ParseStruct
    struct ParseStructInputShortThrowBE {
        @skip(byteCount: 2, because: "padding")
        @parse(byteCount: 4, endianness: .big)
        let words: Int32

        @parse(byteCount: 1, endianness: .big)
        let byte: UInt8
    }

    @Test("Input data is too short (BE)", arguments: [
        Data([]),
        Data([0x01, 0x02, 0x03]),
        Data([0x01, 0x02, 0x03, 0x04, 0x05, 0x06]),
    ])
    func bigEndianInputShortThrow(data: Data) {
        #expect(throws: ParsingError.self) {
            _ = try ParseStructInputShortThrowBE(parsing: data)
        }
    }

    @ParseStruct
    struct ParseStructInputShortThrowLE {
        @skip(byteCount: 2, because: "padding")
        @parse(byteCount: 4, endianness: .little)
        let words: Int32

        @parse(byteCount: 1, endianness: .little)
        let byte: UInt8
    }

    @Test("Input data is too short (LE)", arguments: [
        Data([]),
        Data([0x01, 0x02, 0x03]),
        Data([0x01, 0x02, 0x03, 0x04, 0x05, 0x06]),
    ])
    func littleEndianInputShortThrow(data: Data) {
        #expect(throws: ParsingError.self) {
            _ = try ParseStructInputShortThrowLE(parsing: data)
        }
    }

    @ParseStruct
    struct ParseStructRestBE {
        @skip(byteCount: 2, because: "padding")
        @parse(byteCount: 4, endianness: .big)
        let word: Int32

        @parseRest
        let words: String
    }

    @Test("Parse rest (BE)")
    func bigEndianParseRest() {
        #expect(throws: Never.self) {
            let parsed = try ParseStructRestBE(
                parsing: Data([
                    0x01, 0x02, // skip
                    0x03, 0x04, 0x05, 0x06, // word,
                    0x68, 0x65, 0x6C, 0x6C, 0x6F, 0x20, 0x77, 0x6F, 0x72, 0x6C, 0x64, // words
                ]),
            )

            #expect(parsed.word == 0x0304_0506)
            #expect(parsed.words == "hello world")
        }
    }

    @ParseStruct
    struct ParseStructRestLE {
        @skip(byteCount: 2, because: "padding")
        @parse(byteCount: 4, endianness: .little)
        let word: Int32

        @parseRest
        let words: String
    }

    @Test("Parse rest (LE)")
    func littleEndianParseRest() {
        #expect(throws: Never.self) {
            let parsed = try ParseStructRestLE(
                parsing: Data([
                    0x01, 0x02, // skip
                    0x03, 0x04, 0x05, 0x06, // word,
                    0x68, 0x65, 0x6C, 0x6C, 0x6F, 0x20, 0x77, 0x6F, 0x72, 0x6C, 0x64, // words
                ]),
            )

            #expect(parsed.word == 0x0605_0403)
            #expect(parsed.words == "hello world")
        }
    }

    @ParseStruct
    struct ParseStructRestNoRestBE {
        @skip(byteCount: 2, because: "padding")
        @parse(byteCount: 2, endianness: .big)
        let word: Int16

        @parseRest
        let words: String
    }

    @Test("Parse rest with no rest (BE)")
    func bigEndianParseRestNoRest() {
        #expect(throws: Never.self) {
            let parsed = try ParseStructRestNoRestBE(
                parsing: Data([
                    0x01, 0x02, // skip
                    0x03, 0x04,
                ]),
            )

            #expect(parsed.word == 0x0304)
            #expect(parsed.words == "")
        }
    }

    @ParseStruct
    struct ParseStructRestNoRestLE {
        @skip(byteCount: 2, because: "padding")
        @parse(byteCount: 2, endianness: .little)
        let word: Int16

        @parseRest
        let words: String
    }

    @Test("Parse rest with no rest (LE)")
    func littleEndianParseRestNoRest() {
        #expect(throws: Never.self) {
            let parsed = try ParseStructRestNoRestLE(
                parsing: Data([
                    0x01, 0x02, // skip
                    0x03, 0x04,
                ]),
            )

            #expect(parsed.word == 0x0403)
            #expect(parsed.words == "")
        }
    }

    @ParseStruct
    struct ParseRestInputShortThrowBE {
        @skip(byteCount: 2, because: "padding")
        @parse(byteCount: 1, endianness: .big)
        let word: Int8

        @parseRest()
        let words: String
    }

    @Test("Parse rest with input data too short (BE)", arguments: [
        Data([]),
        Data([0x01]),
        Data([0x01, 0x02]),
    ])
    func bigEndianParseRestInputShortThrow(data: Data) {
        #expect(throws: ParsingError.self) {
            _ = try ParseRestInputShortThrowBE(parsing: data)
        }
    }

    @ParseStruct
    struct ParseRestInputShortThrowLE {
        @skip(byteCount: 2, because: "padding")
        @parse(byteCount: 1, endianness: .little)
        let word: Int8

        @parseRest()
        let words: String
    }

    @Test("Parse rest with input data too short (LE)", arguments: [
        Data([]),
        Data([0x01]),
        Data([0x01, 0x02]),
    ])
    func littleEndianParseRestInputShortThrow(data: Data) {
        #expect(throws: ParsingError.self) {
            _ = try ParseRestInputShortThrowLE(parsing: data)
        }
    }

    @ParseStruct
    struct ParseBytesOfVariable {
        @skip(byteCount: 2, because: "padding")
        @parse(byteCount: 1, endianness: .little)
        let count: Int8

        @parse(byteCountOf: \Self.count)
        let words: String
    }

    @Test("Parse variable based on another field")
    func parseBytesOfVariable() throws {
        let parsed = try ParseBytesOfVariable(parsing: [
            0x01, 0x00, // skip
            0x0C,
            0x68, 0x65, 0x6C, 0x6C, 0x6F, 0x20, 0x77, 0x6F, 0x72, 0x6C, 0x64, // "hello world"
            0x21, 0x21, 0x21, // !!!
        ])

        #expect(parsed.count == 0x0C)
        #expect(parsed.words == "hello world!")
    }
}

extension String: SizedParsable {
    public init(parsing input: inout BinaryParsing.ParserSpan, byteCount: Int) throws {
        try self.init(parsingUTF8: &input, count: byteCount)
    }
}

extension String: Printable {
    public func printerIntel() -> PrinterIntel {
        .builtIn(
            .init(
                bytes: .init(data(using: .utf8) ?? Data()),
                fixedEndianness: true,
            ),
        )
    }
}

// MARK: - @mask Integration Tests

@Suite
struct StructMaskParsingTest {
    // MARK: - Custom Types for Bitmask Testing

    /// A simple flag type that conforms to BitmaskParsable with 1 bit.
    struct Flag: ExpressibleByRawBits, BitCountProviding, RawBitsConvertible, Equatable {
        static var bitCount: Int { 1 }
        let value: Bool

        init(value: Bool) {
            self.value = value
        }

        init(bits: RawBits) throws {
            guard bits.size >= 1 else {
                throw BitmaskParsableError.insufficientBits
            }
            value = bits.bit(at: 0)
        }

        func toRawBits(bitCount: Int) throws -> RawBits {
            try value.toRawBits(bitCount: bitCount)
        }
    }

    /// A 4-bit nibble type that conforms to BitmaskParsable.
    struct Nibble: ExpressibleByRawBits, BitCountProviding, RawBitsConvertible, Equatable {
        static var bitCount: Int { 4 }
        let value: UInt8

        init(value: UInt8) {
            precondition(value <= 0x0F, "Nibble value must be 0-15")
            self.value = value
        }

        init(bits: RawBits) throws {
            guard bits.size <= 4 else {
                throw BitmaskParsableError.unsupportedBitCount
            }
            value = UInt8(bits.extractBits(from: 0, count: bits.size))
        }

        func toRawBits(bitCount: Int) throws -> RawBits {
            try value.toRawBits(bitCount: bitCount)
        }
    }

    /// A 3-bit value type for testing.
    struct ThreeBit: ExpressibleByRawBits, BitCountProviding, RawBitsConvertible, Equatable {
        static var bitCount: Int { 3 }
        let value: UInt8

        init(value: UInt8) {
            precondition(value <= 0x07, "ThreeBit value must be 0-7")
            self.value = value
        }

        init(bits: RawBits) throws {
            guard bits.size <= 3 else {
                throw BitmaskParsableError.unsupportedBitCount
            }
            value = UInt8(bits.extractBits(from: 0, count: bits.size))
        }

        func toRawBits(bitCount: Int) throws -> RawBits {
            try value.toRawBits(bitCount: bitCount)
        }
    }

    // MARK: - Basic Mask Fields with Explicit Bit Count

    @ParseStruct
    struct BasicBitmaskExplicit {
        @mask(bitCount: 1)
        var flag1: UInt8

        @mask(bitCount: 3)
        var value: UInt8

        @mask(bitCount: 4)
        var nibble: UInt8
    }

    @Test("Basic bitmask parsing with explicit bit counts - all bits from single byte")
    func basicBitmaskExplicitParsing() throws {
        // Binary: 1 010 0011 = 0xA3
        // flag1 = 1 (bit 0) -> 1
        // value = 010 (bits 1-3) -> 2
        // nibble = 0011 (bits 4-7) -> 3
        let parsed = try BasicBitmaskExplicit(parsing: Data([0xA3]))
        #expect(parsed.flag1 == 1)
        #expect(parsed.value == 2)
        #expect(parsed.nibble == 3)
    }

    @Test("Basic bitmask parsing - all zeros")
    func basicBitmaskExplicitAllZeros() throws {
        let parsed = try BasicBitmaskExplicit(parsing: Data([0x00]))
        #expect(parsed.flag1 == 0)
        #expect(parsed.value == 0)
        #expect(parsed.nibble == 0)
    }

    @Test("Basic bitmask parsing - all ones")
    func basicBitmaskExplicitAllOnes() throws {
        // Binary: 1 111 1111 = 0xFF
        let parsed = try BasicBitmaskExplicit(parsing: Data([0xFF]))
        #expect(parsed.flag1 == 1)
        #expect(parsed.value == 7) // 0b111 = 7
        #expect(parsed.nibble == 15) // 0b1111 = 15
    }

    // MARK: - Inferred Bit Count with Custom Types

    @ParseStruct
    struct BitmaskInferred {
        @mask
        var flag1: StructMaskParsingTest.Flag

        @mask
        var flag2: StructMaskParsingTest.Flag

        @mask(bitCount: 6)
        var value: UInt8
    }

    @Test("Inferred bitCount from BitmaskParsable type")
    func inferredBitmaskParsing() throws {
        // Binary: 1 0 000101 = 0x85
        // flag1 = 1 (bit 0) -> Flag(true)
        // flag2 = 0 (bit 1) -> Flag(false)
        // value = 000101 (bits 2-7) -> 5
        let parsed = try BitmaskInferred(parsing: Data([0x85]))
        #expect(parsed.flag1 == Flag(value: true))
        #expect(parsed.flag2 == Flag(value: false))
        #expect(parsed.value == 5)
    }

    @ParseStruct
    struct BitmaskAllInferred {
        @mask
        var first: StructMaskParsingTest.Flag

        @mask
        var second: StructMaskParsingTest.Nibble

        @mask
        var third: StructMaskParsingTest.ThreeBit
    }

    @Test("All fields with inferred bit counts")
    func allInferredBitmaskParsing() throws {
        // Binary: 1 1010 011 = 0xD3
        // first = 1 -> Flag(true)
        // second = 1010 -> Nibble(10)
        // third = 011 -> ThreeBit(3)
        let parsed = try BitmaskAllInferred(parsing: Data([0xD3]))
        #expect(parsed.first == Flag(value: true))
        #expect(parsed.second == Nibble(value: 10))
        #expect(parsed.third == ThreeBit(value: 3))
    }

    // MARK: - Multi-Byte Bitmask

    @ParseStruct
    struct MultiBytesBitmask {
        @mask(bitCount: 4)
        var high: UInt8

        @mask(bitCount: 8)
        var middle: UInt8

        @mask(bitCount: 4)
        var low: UInt8
    }

    @Test("Multi-byte bitmask spanning 2 bytes")
    func multiBytesBitmaskParsing() throws {
        // Binary: 1010 10110011 0100
        // Bytes: [0xAB, 0x34]
        // high = 1010 (bits 0-3) -> 10
        // middle = 10110011 (bits 4-11) -> 0xB3 = 179
        // low = 0100 (bits 12-15) -> 4
        let parsed = try MultiBytesBitmask(parsing: Data([0xAB, 0x34]))
        #expect(parsed.high == 10) // 0b1010
        #expect(parsed.middle == 179) // 0b10110011
        #expect(parsed.low == 4) // 0b0100
    }

    // MARK: - Mixed Parse and Mask

    @ParseStruct
    struct MixedParseMask {
        @parse(endianness: .big)
        var header: UInt8

        @mask(bitCount: 1)
        var flag: UInt8

        @mask(bitCount: 7)
        var value: UInt8

        @parse(endianness: .big)
        var footer: UInt16
    }

    @Test("Mixed @parse and @mask fields")
    func mixedParseMaskParsing() throws {
        // header = 0x42
        // Binary for mask byte: 1 0110100 = 0xB4
        // flag = 1
        // value = 0110100 = 52
        // footer = 0x1234
        let parsed = try MixedParseMask(parsing: Data([0x42, 0xB4, 0x12, 0x34]))
        #expect(parsed.header == 0x42)
        #expect(parsed.flag == 1)
        #expect(parsed.value == 52)
        #expect(parsed.footer == 0x1234)
    }

    // MARK: - Multiple Mask Groups

    @ParseStruct
    struct MultipleMaskGroups {
        @mask(bitCount: 4)
        var first: UInt8

        @mask(bitCount: 4)
        var second: UInt8

        @parse(endianness: .big)
        var separator: UInt8

        @mask(bitCount: 2)
        var third: UInt8

        @mask(bitCount: 6)
        var fourth: UInt8
    }

    @Test("Multiple separate mask groups")
    func multipleMaskGroupsParsing() throws {
        // First group: 1010 0101 = 0xA5 -> first=10, second=5
        // Separator: 0xFF
        // Second group: 11 010110 = 0xD6 -> third=3, fourth=22
        let parsed = try MultipleMaskGroups(parsing: Data([0xA5, 0xFF, 0xD6]))
        #expect(parsed.first == 10)
        #expect(parsed.second == 5)
        #expect(parsed.separator == 0xFF)
        #expect(parsed.third == 3)
        #expect(parsed.fourth == 22)
    }

    // MARK: - Error Cases

    @ParseStruct
    struct MaskWithInsufficientData {
        @mask(bitCount: 4)
        var first: UInt8

        @mask(bitCount: 12)
        var second: UInt16
    }

    @Test("Mask parsing with insufficient data throws")
    func maskInsufficientDataThrows() {
        // Needs 16 bits (2 bytes) but only 1 byte provided
        #expect(throws: ParsingError.self) {
            _ = try MaskWithInsufficientData(parsing: Data([0x12]))
        }
    }

    // MARK: - Skip with Mask

    @ParseStruct
    struct SkipWithMask {
        @skip(byteCount: 2, because: "header padding")
        @mask(bitCount: 4)
        var value: UInt8

        @mask(bitCount: 4)
        var flags: UInt8
    }

    @Test("Skip before mask fields")
    func skipBeforeMaskParsing() throws {
        // Skip 2 bytes, then parse mask byte: 1100 0011 = 0xC3
        let parsed = try SkipWithMask(parsing: Data([0xFF, 0xFF, 0xC3]))
        #expect(parsed.value == 12) // 0b1100
        #expect(parsed.flags == 3) // 0b0011
    }
}

// MARK: - @ParseStruct Mask Printing Integration Tests

@Suite
struct StructMaskPrintingTest {
    // MARK: - Basic Mask Round-Trip Tests

    @ParseStruct
    struct BasicBitmask {
        @mask(bitCount: 1)
        var flag1: UInt8

        @mask(bitCount: 3)
        var value: UInt8

        @mask(bitCount: 4)
        var nibble: UInt8
    }

    @Test("Basic bitmask struct round-trip")
    func basicBitmaskRoundTrip() throws {
        // Binary: 1 010 0011 = 0xA3
        let originalData = Data([0xA3])
        let parsed = try BasicBitmask(parsing: originalData)

        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == originalData)
    }

    @Test("Basic bitmask struct round-trip all zeros")
    func basicBitmaskRoundTripAllZeros() throws {
        let originalData = Data([0x00])
        let parsed = try BasicBitmask(parsing: originalData)

        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == originalData)
    }

    @Test("Basic bitmask struct round-trip all ones")
    func basicBitmaskRoundTripAllOnes() throws {
        let originalData = Data([0xFF])
        let parsed = try BasicBitmask(parsing: originalData)

        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == originalData)
    }

    // MARK: - Mixed Parse and Mask Round-Trip Tests

    @ParseStruct
    struct MixedParseMask {
        @parse(endianness: .big)
        var header: UInt8

        @mask(bitCount: 1)
        var flag: UInt8

        @mask(bitCount: 7)
        var value: UInt8

        @parse(endianness: .big)
        var footer: UInt16
    }

    @Test("Mixed @parse and @mask round-trip")
    func mixedParseMaskRoundTrip() throws {
        // header = 0x42
        // Binary for mask byte: 1 0110100 = 0xB4
        // footer = 0x1234
        let originalData = Data([0x42, 0xB4, 0x12, 0x34])
        let parsed = try MixedParseMask(parsing: originalData)

        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == originalData)
    }

    // MARK: - Multiple Mask Groups Round-Trip Tests

    @ParseStruct
    struct MultipleMaskGroups {
        @mask(bitCount: 4)
        var first: UInt8

        @mask(bitCount: 4)
        var second: UInt8

        @parse(endianness: .big)
        var separator: UInt8

        @mask(bitCount: 2)
        var third: UInt8

        @mask(bitCount: 6)
        var fourth: UInt8
    }

    @Test("Multiple mask groups round-trip")
    func multipleMaskGroupsRoundTrip() throws {
        // First group: 1010 0101 = 0xA5 -> first=10, second=5
        // Separator: 0xFF
        // Second group: 11 010110 = 0xD6 -> third=3, fourth=22
        let originalData = Data([0xA5, 0xFF, 0xD6])
        let parsed = try MultipleMaskGroups(parsing: originalData)

        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == originalData)
    }

    // MARK: - Multi-Byte Bitmask Round-Trip Tests

    @ParseStruct
    struct MultiBytesBitmask {
        @mask(bitCount: 4)
        var high: UInt8

        @mask(bitCount: 8)
        var middle: UInt8

        @mask(bitCount: 4)
        var low: UInt8
    }

    @Test("Multi-byte bitmask round-trip")
    func multiBytesBitmaskRoundTrip() throws {
        // Binary: 1010 10110011 0100 = 0xAB 0x34
        let originalData = Data([0xAB, 0x34])
        let parsed = try MultiBytesBitmask(parsing: originalData)

        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == originalData)
    }

    // MARK: - Skip with Mask Round-Trip Tests

    @ParseStruct
    struct SkipWithMask {
        @skip(byteCount: 2, because: "header padding")
        @mask(bitCount: 4)
        var value: UInt8

        @mask(bitCount: 4)
        var flags: UInt8
    }

    @Test("Skip with mask round-trip")
    func skipWithMaskRoundTrip() throws {
        // Skip 2 bytes, then parse mask byte: 1100 0011 = 0xC3
        let originalData = Data([0xFF, 0xFF, 0xC3])
        let parsed = try SkipWithMask(parsing: originalData)

        let printedBytes = try parsed.printParsed(printer: .data)
        // Skip bytes become zeros in output, mask byte preserved
        #expect(printedBytes == Data([0x00, 0x00, 0xC3]))
    }

    // MARK: - Edge Case Tests: Padding and Interleaving

    /// Mask fields totaling 10 bits (not divisible by 8)
    @ParseStruct
    struct NonByteAlignedMask: Equatable {
        @mask(bitCount: 3)
        var first: UInt8

        @mask(bitCount: 5)
        var second: UInt8

        @mask(bitCount: 2)
        var third: UInt8
    }

    @Test("Non-byte-aligned mask (10 bits) round-trip")
    func nonByteAlignedMaskRoundTrip() throws {
        // 101 01100 11 = 10 bits -> first=5, second=12, third=3
        // Byte representation: 10101100 11000000 = 0xAC 0xC0
        let originalData = Data([0b1010_1100, 0b1100_0000])
        let parsed = try NonByteAlignedMask(parsing: originalData)
        #expect(parsed == NonByteAlignedMask(first: 0b101, second: 0b01100, third: 0b11))
        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == originalData)
    }

    /// Mask fields totaling 13 bits
    @ParseStruct
    struct ThirteenBitMask: Equatable {
        @mask(bitCount: 5)
        var highBits: UInt8

        @mask(bitCount: 4)
        var middleBits: UInt8

        @mask(bitCount: 4)
        var lowBits: UInt8
    }

    @Test("13-bit mask round-trip")
    func thirteenBitMaskRoundTrip() throws {
        // 10101 1100 0011 000 (padded to 16 bits) -> highBits=21, middleBits=12, lowBits=3
        // Bytes: 10101110 00011000 = 0xAE 0x18
        let originalData = Data([0b1010_1110, 0b0001_1000])
        let parsed = try ThirteenBitMask(parsing: originalData)
        #expect(parsed == ThirteenBitMask(highBits: 0b10101, middleBits: 0b1100, lowBits: 0b0011))
        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == originalData)
    }

    /// Complex interleaving: Parse -> Mask -> Skip -> Mask -> Parse
    @ParseStruct
    struct InterleavedParseMaskSkipMaskParse: Equatable {
        @parse(endianness: .big)
        var header: UInt8

        @mask(bitCount: 4)
        var nibble1: UInt8

        @mask(bitCount: 4)
        var nibble2: UInt8

        @skip(byteCount: 2, because: "reserved padding")

        @mask(bitCount: 2)
        var twobit: UInt8

        @mask(bitCount: 6)
        var sixbit: UInt8

        @parse(endianness: .big)
        var footer: UInt16
    }

    @Test("Interleaved parse-mask-skip-mask-parse round-trip")
    func interleavedParseMaskSkipMaskParseRoundTrip() throws {
        // header: 0x42
        // mask1: 1010 0101 = 0xA5 -> nibble1=10, nibble2=5
        // skip: 0xFF 0xFF
        // mask2: 11 010110 = 0xD6 -> twobit=3, sixbit=22
        // footer: 0x1234
        let originalData = Data([0x42, 0b1010_0101, 0xFF, 0xFF, 0b1101_0110, 0x12, 0x34])
        let parsed = try InterleavedParseMaskSkipMaskParse(parsing: originalData)
        #expect(parsed == InterleavedParseMaskSkipMaskParse(
            header: 0x42, nibble1: 0b1010, nibble2: 0b0101,
            twobit: 0b11, sixbit: 0b010110, footer: 0x1234,
        ))
        // Skip bytes become zeros
        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == Data([0x42, 0b1010_0101, 0x00, 0x00, 0b1101_0110, 0x12, 0x34]))
    }

    /// Skip -> Mask -> Skip -> Parse pattern
    @ParseStruct
    struct SkipMaskSkipParse: Equatable {
        @skip(byteCount: 1, because: "header padding")
        @mask(bitCount: 8)
        var flags: UInt8

        @skip(byteCount: 2, because: "reserved")

        @parse(endianness: .little)
        var value: UInt16
    }

    @Test("Skip-mask-skip-parse round-trip")
    func skipMaskSkipParseRoundTrip() throws {
        // skip: 0xFF
        // mask: 0xAB -> flags=0xAB
        // skip: 0xFF 0xFF
        // parse LE: 0x34 0x12 -> value=0x1234
        let originalData = Data([0xFF, 0xAB, 0xFF, 0xFF, 0x34, 0x12])
        let parsed = try SkipMaskSkipParse(parsing: originalData)
        #expect(parsed == SkipMaskSkipParse(flags: 0xAB, value: 0x1234))
        // Skip bytes become zeros
        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == Data([0x00, 0xAB, 0x00, 0x00, 0x34, 0x12]))
    }

    /// Multiple separate non-byte-aligned mask groups
    @ParseStruct
    struct MultipleNonByteAlignedMaskGroups: Equatable {
        @mask(bitCount: 3)
        var group1High: UInt8

        @mask(bitCount: 3)
        var group1Mid: UInt8

        @mask(bitCount: 2)
        var group1Low: UInt8

        @parse(endianness: .big)
        var separator: UInt8

        @mask(bitCount: 5)
        var group2High: UInt8

        @mask(bitCount: 5)
        var group2Mid: UInt8

        @mask(bitCount: 6)
        var group2Low: UInt8
    }

    @Test("Multiple non-byte-aligned mask groups round-trip")
    func multipleNonByteAlignedMaskGroupsRoundTrip() throws {
        // First group (8 bits): 101 011 10 -> group1High=5, group1Mid=3, group1Low=2
        // separator: 0xFF
        // Second group (16 bits): 10101 01100 001100 -> group2High=21, group2Mid=12, group2Low=12
        let originalData = Data([0b1010_1110, 0xFF, 0b1010_1011, 0b0000_1100])
        let parsed = try MultipleNonByteAlignedMaskGroups(parsing: originalData)

        #expect(parsed == MultipleNonByteAlignedMaskGroups(
            group1High: 0b101,
            group1Mid: 0b011,
            group1Low: 0b10,
            separator: 0xFF,
            group2High: 0b10101,
            group2Mid: 0b01100,
            group2Low: 0b1100,
        ))

        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == originalData)
    }

    /// Eight single-bit mask fields
    @ParseStruct
    struct SingleBitMasks: Equatable {
        @mask(bitCount: 1)
        var bit0: UInt8

        @mask(bitCount: 1)
        var bit1: UInt8

        @mask(bitCount: 1)
        var bit2: UInt8

        @mask(bitCount: 1)
        var bit3: UInt8

        @mask(bitCount: 1)
        var bit4: UInt8

        @mask(bitCount: 1)
        var bit5: UInt8

        @mask(bitCount: 1)
        var bit6: UInt8

        @mask(bitCount: 1)
        var bit7: UInt8
    }

    @Test("Eight single-bit masks round-trip")
    func eightSingleBitMasksRoundTrip() throws {
        // 10101010 -> bit0=1, bit1=0, bit2=1, bit3=0, bit4=1, bit5=0, bit6=1, bit7=0
        let originalData = Data([0b1010_1010])
        let parsed = try SingleBitMasks(parsing: originalData)
        #expect(parsed == SingleBitMasks(bit0: 1, bit1: 0, bit2: 1, bit3: 0, bit4: 1, bit5: 0, bit6: 1, bit7: 0))
        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == originalData)
    }

    @Test("Eight single-bit masks all ones round-trip")
    func eightSingleBitMasksAllOnesRoundTrip() throws {
        let originalData = Data([0xFF])
        let parsed = try SingleBitMasks(parsing: originalData)
        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == originalData)
    }

    @Test("Eight single-bit masks all zeros round-trip")
    func eightSingleBitMasksAllZerosRoundTrip() throws {
        let originalData = Data([0x00])
        let parsed = try SingleBitMasks(parsing: originalData)
        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == originalData)
    }

    /// Large mask fields spanning multiple bytes
    @ParseStruct
    struct LargeMaskFields: Equatable {
        @mask(bitCount: 20)
        var large: UInt32

        @mask(bitCount: 12)
        var medium: UInt16
    }

    @Test("Large mask fields (32 bits total) round-trip")
    func largeMaskFieldsRoundTrip() throws {
        // 20 bits: 0001 0010 0011 0100 0101 -> large=0x12345
        // 12 bits: 0110 0111 1000 -> medium=0x678
        // Combined 32 bits: 00010010 00110100 01010110 01111000 = 0x12345678
        let originalData = Data([0x12, 0x34, 0x56, 0x78])
        let parsed = try LargeMaskFields(parsing: originalData)
        #expect(parsed == LargeMaskFields(large: 0x1234_5000, medium: 0x6780))
        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == originalData)
    }

    /// Mask -> Parse -> Mask pattern
    @ParseStruct
    struct MaskParseMask: Equatable {
        @mask(bitCount: 4)
        var firstNibble: UInt8

        @mask(bitCount: 4)
        var secondNibble: UInt8

        @parse(endianness: .big)
        var middleWord: UInt16

        @mask(bitCount: 3)
        var threeBit: UInt8

        @mask(bitCount: 5)
        var fiveBit: UInt8
    }

    @Test("Mask-parse-mask pattern round-trip")
    func maskParseMaskRoundTrip() throws {
        // First mask byte: 1010 0101 -> firstNibble=10, secondNibble=5
        // Parse word BE: 0x1234
        // Second mask byte: 111 01100 -> threeBit=7, fiveBit=12
        let originalData = Data([0b1010_0101, 0x12, 0x34, 0b1110_1100])
        let parsed = try MaskParseMask(parsing: originalData)
        #expect(parsed == MaskParseMask(
            firstNibble: 0b1010, secondNibble: 0b0101,
            middleWord: 0x1234, threeBit: 0b111, fiveBit: 0b01100,
        ))
        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == originalData)
    }

    /// Three separate mask groups with different separators
    @ParseStruct
    struct ThreeMaskGroups: Equatable {
        @mask(bitCount: 4)
        var group1a: UInt8

        @mask(bitCount: 4)
        var group1b: UInt8

        @parse(endianness: .big)
        var sep1: UInt8

        @mask(bitCount: 2)
        var group2a: UInt8

        @mask(bitCount: 6)
        var group2b: UInt8

        @parse(endianness: .little)
        var sep2: UInt16

        @mask(bitCount: 1)
        var group3a: UInt8

        @mask(bitCount: 7)
        var group3b: UInt8
    }

    @Test("Three separate mask groups round-trip")
    func threeMaskGroupsRoundTrip() throws {
        // Group1: 1100 0011 -> group1a=12, group1b=3
        // sep1: 0xAA
        // Group2: 10 110011 -> group2a=2, group2b=51
        // sep2 LE: 0x34 0x12 -> sep2=0x1234
        // Group3: 1 0101010 -> group3a=1, group3b=42
        let originalData = Data([0b1100_0011, 0xAA, 0b1011_0011, 0x34, 0x12, 0b1010_1010])
        let parsed = try ThreeMaskGroups(parsing: originalData)
        #expect(parsed == ThreeMaskGroups(
            group1a: 0b1100, group1b: 0b0011, sep1: 0xAA,
            group2a: 0b10, group2b: 0b110011, sep2: 0x1234,
            group3a: 1, group3b: 0b0101010,
        ))
        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == originalData)
    }
}
