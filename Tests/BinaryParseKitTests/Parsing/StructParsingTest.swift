//
//  StructParsingTest.swift
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
