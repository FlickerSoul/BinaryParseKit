//
//  EnumParsingTest.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/8/25.
//
import BinaryParseKit
import BinaryParsing
import Foundation
import Testing

@Suite
struct EnumParsingTest {
    // MARK: - Basic Enum Matching Tests

    @ParseEnum
    enum BasicEnumBE {
        @match(byte: 0x01)
        case first

        @match(bytes: [0x02, 0x03])
        case second

        @match(byte: 0x04)
        case third
    }

    @Test
    func `basic enum matching (BE)`() throws {
        let first = try BasicEnumBE(parsing: Data([0x01]))
        #expect(first == .first)

        let second = try BasicEnumBE(parsing: Data([0x02, 0x03]))
        #expect(second == .second)

        let third = try BasicEnumBE(parsing: Data([0x04]))
        #expect(third == .third)
    }

    @Test
    func `basic enum no match throws error`() {
        #expect(throws: BinaryParserKitError.self) {
            _ = try BasicEnumBE(parsing: Data([0xFF]))
        }
    }

    @Test
    func `basic enum no match because of insufficient data`() {
        #expect(throws: BinaryParserKitError.self) {
            _ = try BasicEnumBE(parsing: Data([0x02]))
        }
    }

    // MARK: - Raw Representable Enum Tests

    @ParseEnum
    enum RawRepresentableUInt8: UInt8, Matchable {
        @match
        case first = 0x10

        @match
        case second = 0x20

        @match
        case third = 0x30
    }

    @Test
    func `raw representable UInt8 enum`() throws {
        let first = try RawRepresentableUInt8(parsing: Data([0x10]))
        #expect(first == .first)

        let second = try RawRepresentableUInt8(parsing: Data([0x20]))
        #expect(second == .second)

        let third = try RawRepresentableUInt8(parsing: Data([0x30]))
        #expect(third == .third)
    }

    @Test
    func `raw representable enum no match`() {
        #expect(throws: BinaryParserKitError.self) {
            _ = try RawRepresentableUInt8(parsing: Data([0xFF]))
        }
    }

    @ParseEnum
    enum RawRepresentableUInt16: UInt16, Matchable {
        @match
        case value1 = 0x0102
        @match
        case value2 = 0x0304
    }

    @Test
    func `raw representable Matchable enum`() throws {
        let value1 = try RawRepresentableUInt16(parsing: Data([0x01, 0x02]))
        #expect(value1 == .value1)

        let value2 = try RawRepresentableUInt16(parsing: Data([0x03, 0x04]))
        #expect(value2 == .value2)
    }

    // MARK: - Enum with Associated Values Tests (match)

    @ParseEnum
    enum EnumWithValuesMatchBE: Equatable {
        @match(byte: 0x01)
        @parse(endianness: .big)
        case withInt16(Int16)

        @match(byte: 0x02)
        @parse(endianness: .big)
        case withUInt32(UInt32)

        @match(byte: 0x03)
        @parse(endianness: .big)
        @parse(endianness: .big)
        case withTwoValues(Int16, UInt16)
    }

    @Test
    func `enum with associated values by match (BE)`() throws {
        try #expect(EnumWithValuesMatchBE(parsing: Data([0x01, 0x12])) == .withInt16(0x0112))

        try #expect(EnumWithValuesMatchBE(parsing: Data([0x02, 0x12, 0x34, 0x56])) == .withUInt32(0x0212_3456))

        try #expect(EnumWithValuesMatchBE(parsing: Data([0x03, 0x12, 0x34, 0x56])) == .withTwoValues(0x0312, 0x3456))
    }

    @ParseEnum
    enum EnumWithValuesMatchLE: Equatable {
        @match(byte: 0x01)
        @parse(endianness: .little)
        case withInt16(Int16)

        @match(byte: 0x02)
        @parse(endianness: .little)
        case withUInt32(UInt32)

        @match(byte: 0x03)
        @parse(endianness: .little)
        @parse(endianness: .little)
        case withTwoValues(Int16, UInt16)
    }

    @Test
    func `enum with associated values by match (LE)`() throws {
        try #expect(EnumWithValuesMatchLE(parsing: Data([0x01, 0x34])) == .withInt16(0x3401))

        try #expect(EnumWithValuesMatchLE(parsing: Data([0x02, 0x78, 0x56, 0x34])) == .withUInt32(0x3456_7802))

        try #expect(EnumWithValuesMatchLE(parsing: Data([0x03, 0x34, 0x12, 0x78])) == .withTwoValues(0x3403, 0x7812))
    }

    // MARK: - Enum with Associated Values Tests (matchAndTake)

    @ParseEnum
    enum EnumWithValuesMatchAndTakeBE: Equatable {
        @matchAndTake(byte: 0x01)
        @parse(endianness: .big)
        case withInt16(Int16)

        @matchAndTake(byte: 0x02)
        @parse(endianness: .big)
        case withUInt32(UInt32)

        @matchAndTake(byte: 0x03)
        @parse(endianness: .big)
        @parse(endianness: .big)
        case withTwoValues(Int16, UInt16)
    }

    @Test
    func `enum with associated values by matchAndTake (BE)`() throws {
        try #expect(EnumWithValuesMatchAndTakeBE(parsing: Data([0x01, 0x12, 0x34])) == .withInt16(0x1234))

        try #expect(EnumWithValuesMatchAndTakeBE(parsing: Data([0x02, 0x12, 0x34, 0x56, 0x78])) ==
            .withUInt32(0x1234_5678))

        try #expect(EnumWithValuesMatchAndTakeBE(parsing: Data([0x03, 0x12, 0x34, 0x56, 0x78])) == .withTwoValues(
            0x1234,
            0x5678,
        ))
    }

    @ParseEnum
    enum EnumWithValuesMatchAndTakeLE: Equatable {
        @matchAndTake(byte: 0x01)
        @parse(endianness: .little)
        case withInt16(Int16)

        @matchAndTake(byte: 0x02)
        @parse(endianness: .little)
        case withUInt32(UInt32)

        @matchAndTake(byte: 0x03)
        @parse(endianness: .little)
        @parse(endianness: .little)
        case withTwoValues(Int16, UInt16)
    }

    @Test
    func `enum with associated values matchAndTake (LE)`() throws {
        try #expect(EnumWithValuesMatchAndTakeLE(parsing: Data([0x01, 0x34, 0x12])) == .withInt16(0x1234))

        try #expect(EnumWithValuesMatchAndTakeLE(parsing: Data([0x02, 0x78, 0x56, 0x34, 0x12])) ==
            .withUInt32(0x1234_5678))

        try #expect(EnumWithValuesMatchAndTakeLE(parsing: Data([0x03, 0x34, 0x12, 0x78, 0x56])) == .withTwoValues(
            0x1234,
            0x5678,
        ))
    }

    @ParseEnum
    enum EnumWithMixedEndiannessMatchAndTake: Equatable {
        @matchAndTake(byte: 0x01)
        @parse(endianness: .big)
        @parse(endianness: .little)
        case mixed(Int16, Int16)

        @matchAndTake(byte: 0x02)
        @parse(endianness: .little)
        @parse(endianness: .big)
        case reversed(UInt16, UInt16)
    }

    @Test
    func `enum with mixed endianness`() throws {
        try #expect(EnumWithMixedEndiannessMatchAndTake(parsing: Data([0x01, 0x12, 0x34, 0x56, 0x78])) == .mixed(
            0x1234,
            0x7856,
        ))

        try #expect(EnumWithMixedEndiannessMatchAndTake(parsing: Data([0x02, 0x12, 0x34, 0x56, 0x78])) == .reversed(
            0x3412,
            0x5678,
        ))
    }

    @ParseEnum
    enum EnumWithNamedValues: Equatable {
        @matchAndTake(byte: 0x01)
        @parse(endianness: .big)
        @parse(endianness: .big)
        case data(header: Int16, value: UInt32)

        @matchAndTake(byte: 0x02)
        @parse(endianness: .little)
        case simple(count: UInt8)
    }

    @Test
    func `enum with named associated values`() throws {
        try #expect(EnumWithNamedValues(parsing: Data([0x01, 0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC])) == .data(
            header: 0x1234,
            value: 0x5678_9ABC,
        ))

        try #expect(EnumWithNamedValues(parsing: Data([0x02, 0x42])) == .simple(count: 0x42))
    }

    // MARK: - matchDefault Tests

    @ParseEnum
    enum EnumWithDefault {
        @match(byte: 0x01)
        case first

        @match(byte: 0x02)
        case second

        @matchDefault
        case other
    }

    @Test
    func `enum with default case`() throws {
        let case1 = try EnumWithDefault(parsing: Data([0x01]))
        #expect(case1 == .first)

        let case2 = try EnumWithDefault(parsing: Data([0x02]))
        #expect(case2 == .second)

        // Default case should match any other value
        let case3 = try EnumWithDefault(parsing: Data([0xFF]))
        #expect(case3 == .other)

        let case4 = try EnumWithDefault(parsing: Data([0x42]))
        #expect(case4 == .other)
    }

    @ParseEnum
    enum EnumWithDefaultAndValues: Equatable {
        @matchAndTake(byte: 0x01)
        @parse(endianness: .big)
        case known(UInt16)

        @matchDefault
        @parse(endianness: .little)
        case unknown(UInt16)
    }

    @Test
    func `enum with default case and values`() throws {
        try #expect(EnumWithDefaultAndValues(parsing: Data([0x01, 0x12, 0x34])) == .known(0x1234))
        try #expect(EnumWithDefaultAndValues(parsing: Data([0xFF, 0x12])) == .unknown(0x12FF))
    }

    // MARK: - Skip Tests

    @ParseEnum
    enum EnumWithSkipBE: Equatable {
        @matchAndTake(byte: 0x01)
        @skip(byteCount: 2, because: "padding")
        @parse(endianness: .big)
        case withPadding(Int16)

        @matchAndTake(byte: 0x02)
        @parse(endianness: .big)
        @skip(byteCount: 1, because: "reserved")
        @parse(endianness: .big)
        case withMiddleSkip(UInt8, UInt16)

        @match(byte: 0x03)
        case skipOnly
    }

    @Test
    func `enum with skip (BE)`() throws {
        try #expect(EnumWithSkipBE(parsing: Data([0x01, 0xFF, 0xFF, 0x12, 0x34])) == .withPadding(0x1234))
        try #expect(EnumWithSkipBE(parsing: Data([0x02, 0x42, 0xFF, 0x56, 0x78])) == .withMiddleSkip(0x42, 0x5678))
        try #expect(EnumWithSkipBE(parsing: Data([0x03, 0xFF, 0xFF, 0xFF, 0xFF])) == .skipOnly)
    }

    @ParseEnum
    enum EnumWithSkipLE: Equatable {
        @matchAndTake(byte: 0x01)
        @skip(byteCount: 2, because: "padding")
        @parse(endianness: .little)
        case withPadding(Int16)

        @matchAndTake(byte: 0x02)
        @parse(endianness: .little)
        @skip(byteCount: 1, because: "reserved")
        @parse(endianness: .little)
        case withMiddleSkip(UInt8, UInt16)
    }

    @Test
    func `enum with skip (LE)`() throws {
        try #expect(EnumWithSkipLE(parsing: Data([0x01, 0xFF, 0xFF, 0x34, 0x12])) == .withPadding(0x1234))
        try #expect(EnumWithSkipLE(parsing: Data([0x02, 0x42, 0xFF, 0x78, 0x56])) == .withMiddleSkip(0x42, 0x5678))
    }

    // MARK: - byteCount Tests

    @ParseEnum
    enum EnumWithByteCount: Equatable {
        @matchAndTake(byte: 0x01)
        @parse(byteCount: 3, endianness: .big)
        case largerThanType(Int32)

        @matchAndTake(byte: 0x02)
        @parse(byteCount: 2, endianness: .little)
        case smallerThanType(Int64)
    }

    @Test
    func `enum with byteCount`() throws {
        try #expect(EnumWithByteCount(parsing: Data([0x01, 0x12, 0x34, 0x56])) == .largerThanType(0x123456))
        try #expect(EnumWithByteCount(parsing: Data([0x02, 0x12, 0x34])) == .smallerThanType(0x3412))
    }

    // MARK: - Error Handling Tests

    @ParseEnum
    enum EnumForErrorTests {
        @matchAndTake(byte: 0x01)
        @parse(endianness: .big)
        case needsValue(UInt32)

        @matchAndTake(bytes: [0x02, 0x03])
        @parse(endianness: .big)
        @parse(endianness: .big)
        case needsTwoValues(UInt16, UInt16)
    }

    @Test(arguments: [
        Data([0x01]), // Match but no value
        Data([0x01, 0x12]), // Match but incomplete value
        Data([0x01, 0x12, 0x34, 0x56]), // Match but incomplete value (needs 4 bytes)
        Data([0x02]), // Incomplete match pattern
        Data([0x02, 0x03]), // Match but no values
        Data([0x02, 0x03, 0x12]), // Match but incomplete first value
        Data([0x02, 0x03, 0x12, 0x34, 0x56]), // Match but incomplete second value
        Data([0xFF, 0xFF, 0xFF, 0xFF]), // No matching case
    ])
    func `enum parsing with insufficient data`(data: Data) {
        #expect(throws: ThrownParsingError.self) {
            _ = try EnumForErrorTests(parsing: data)
        }
    }

    // MARK: - Complex Combination Tests

    @ParseEnum
    enum ComplexEnum: Equatable {
        @match(byte: 0x01)
        case simple

        @matchAndTake(bytes: [0x02, 0x03])
        @skip(byteCount: 2, because: "reserved")
        @parse(endianness: .big)
        case withSkip(UInt16)

        @matchAndTake(byte: 0x04)
        @parse(endianness: .big)
        @skip(byteCount: 1, because: "padding")
        @parse(endianness: .little)
        @parse(endianness: .big)
        case complex(header: Int16, flags: UInt8, value: UInt32)

        @matchDefault
        case unknown
    }

    @Test
    func `complex enum with multiple features`() throws {
        // Test simple case
        try #expect(ComplexEnum(parsing: Data([0x01])) == .simple)

        // Test withSkip case
        try #expect(ComplexEnum(parsing: Data([0x02, 0x03, 0xFF, 0xFF, 0x12, 0x34])) == .withSkip(0x1234))

        // Test complex case
        try #expect(ComplexEnum(parsing: Data([
            0x04, // match
            0x12, 0x34, // header (BE)
            0xFF, // skip
            0x42, // flags (LE, but single byte)
            0x78, 0x56, 0x34, 0x12, // value (BE)
        ])) == .complex(header: 0x1234, flags: 0x42, value: 0x7856_3412))

        // Test default case
        try #expect(ComplexEnum(parsing: Data([0xFF])) == .unknown)
    }
}

// MARK: - Length-Based Matching Tests

@Suite
struct LengthMatchingTest {
    @ParseEnum
    enum VariableSizePayload: Equatable {
        @match(length: 4)
        @parse(endianness: .big)
        case shortPayload(UInt32)

        @match(length: 8)
        @parse(endianness: .big)
        case longPayload(UInt64)

        @matchDefault
        case unknown
    }

    @Test
    func `length matching with exact sizes`() throws {
        // 4 bytes matches shortPayload
        try #expect(VariableSizePayload(parsing: Data([0x12, 0x34, 0x56, 0x78])) == .shortPayload(0x1234_5678))

        // 8 bytes matches longPayload
        try #expect(VariableSizePayload(parsing: Data([
            0x12, 0x34, 0x56, 0x78,
            0x9A, 0xBC, 0xDE, 0xF0,
        ])) == .longPayload(0x1234_5678_9ABC_DEF0))
    }

    @Test
    func `length matching falls back to default`() throws {
        // 0 bytes - falls back to unknown
        try #expect(VariableSizePayload(parsing: Data([])) == .unknown)

        // 2 bytes - doesn't match 4 or 8, falls back to unknown
        try #expect(VariableSizePayload(parsing: Data([0x12, 0x34])) == .unknown)

        // 6 bytes - doesn't match 4 or 8, falls back to unknown
        try #expect(VariableSizePayload(parsing: Data([0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC])) == .unknown)

        // 10 bytes - doesn't match 4 or 8, falls back to unknown
        try #expect(VariableSizePayload(parsing: Data([0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC, 0xDE, 0xF0, 0x11, 0x22])) ==
            .unknown)
    }

    @ParseEnum
    enum StrictLengthPayload: Equatable {
        @match(length: 2)
        @parse(endianness: .big)
        case twoBytes(UInt16)

        @match(length: 4)
        @parse(endianness: .little)
        case fourBytes(UInt32)
    }

    @Test
    func `length matching without default throws on mismatch`() throws {
        // Exact match works
        try #expect(StrictLengthPayload(parsing: Data([0x12, 0x34])) == .twoBytes(0x1234))
        try #expect(StrictLengthPayload(parsing: Data([0x78, 0x56, 0x34, 0x12])) == .fourBytes(0x1234_5678))
    }

    @Test
    func `length matching without default throws on size mismatch`() {
        // 3 bytes - no match, no default
        #expect(throws: BinaryParserKitError.self) {
            _ = try StrictLengthPayload(parsing: Data([0x12, 0x34, 0x56]))
        }

        // 0 bytes - no match, no default
        #expect(throws: BinaryParserKitError.self) {
            _ = try StrictLengthPayload(parsing: Data([]))
        }
    }

    @ParseEnum
    enum LengthWithMultipleFields: Equatable {
        @match(length: 6)
        @parse(endianness: .big)
        @parse(endianness: .little)
        case split(UInt32, UInt16)

        @match(length: 3)
        @parse(endianness: .big)
        @parse(endianness: .big)
        @parse(endianness: .big)
        case triple(UInt8, UInt8, UInt8)
    }

    @Test
    func `length matching with multiple associated values`() throws {
        try #expect(LengthWithMultipleFields(parsing: Data([
            0x12, 0x34, 0x56, 0x78, // UInt32 BE
            0xBC, 0x9A, // UInt16 LE
        ])) == .split(0x1234_5678, 0x9ABC))

        try #expect(LengthWithMultipleFields(parsing: Data([0x11, 0x22, 0x33])) == .triple(0x11, 0x22, 0x33))
    }
}
