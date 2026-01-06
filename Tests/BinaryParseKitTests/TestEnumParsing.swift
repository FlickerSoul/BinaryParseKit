//
//  TestEnumParsing.swift
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

extension Matchable where Self: RawRepresentable, Self.RawValue == UInt16 {
    func bytesToMatch() -> [UInt8] {
        [
            UInt8((rawValue & 0xFF00) >> 8),
            UInt8(rawValue & 0x00FF),
        ]
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

// MARK: - @mask Integration Tests for Enums

@Suite
struct EnumMaskParsingTest {
    // MARK: - Basic Mask in Enum Associated Values

    @ParseEnum
    enum BasicEnumWithMask: Equatable {
        @matchAndTake(byte: 0x01)
        @mask(bitCount: 1)
        @mask(bitCount: 7)
        case flags(UInt8, UInt8)

        @matchAndTake(byte: 0x02)
        @parse(endianness: .big)
        case simple(UInt16)
    }

    @Test("Enum with mask associated values")
    func enumWithMaskValues() throws {
        // Match byte 0x01 (consumed), then parse: 1 0110100 = 0xB4
        // First mask: 1 (1 bit) -> 1
        // Second mask: 0110100 (7 bits) -> 52
        let flags = try BasicEnumWithMask(parsing: Data([0x01, 0b1011_0100]))
        #expect(flags == .flags(1, 52))

        // Simple case still works
        let simple = try BasicEnumWithMask(parsing: Data([0x02, 0x12, 0x34]))
        #expect(simple == .simple(0x1234))
    }

    @Test("Enum with mask - all zeros")
    func enumWithMaskAllZeros() throws {
        let flags = try BasicEnumWithMask(parsing: Data([0x01, 0x00]))
        #expect(flags == .flags(0, 0))
    }

    @Test("Enum with mask - all ones")
    func enumWithMaskAllOnes() throws {
        // 1 1111111 = 0xFF
        let flags = try BasicEnumWithMask(parsing: Data([0x01, 0b1111_1111]))
        #expect(flags == .flags(1, 127))
    }

    // MARK: - Mixed Parse and Mask

    @ParseEnum
    enum MixedParseAndMask: Equatable {
        @matchAndTake(byte: 0x01)
        @parse(endianness: .big)
        @mask(bitCount: 4)
        @mask(bitCount: 4)
        case mixed(UInt16, nibble1: UInt8, nibble2: UInt8)

        @matchAndTake(byte: 0x02)
        @mask(bitCount: 8)
        case singleMask(UInt8)
    }

    @Test("Enum with mixed @parse and @mask")
    func enumMixedParseAndMask() throws {
        // Match 0x01 (consumed), then parse UInt16 BE (0x1234), then parse mask byte: 1010 0101 = 0xA5
        let mixed = try MixedParseAndMask(parsing: Data([0x01, 0x12, 0x34, 0xA5]))
        #expect(mixed == .mixed(0x1234, nibble1: 10, nibble2: 5))

        // Single mask case
        let single = try MixedParseAndMask(parsing: Data([0x02, 0x42]))
        #expect(single == .singleMask(0x42))
    }

    // MARK: - Multiple Mask Groups in Same Case

    @ParseEnum
    enum MultipleMaskGroups: Equatable {
        @matchAndTake(byte: 0x01)
        @mask(bitCount: 2)
        @mask(bitCount: 6)
        @parse(endianness: .big)
        @mask(bitCount: 4)
        @mask(bitCount: 4)
        case complex(group1a: UInt8, group1b: UInt8, separator: UInt8, group2a: UInt8, group2b: UInt8)
    }

    @Test("Enum with multiple separate mask groups")
    func enumMultipleMaskGroups() throws {
        // Match 0x01 (consumed)
        // First mask group: 11 010110 = 0xD6 -> group1a=3, group1b=22
        // Separator: 0xFF
        // Second mask group: 1010 0101 = 0xA5 -> group2a=10, group2b=5
        let complex = try MultipleMaskGroups(parsing: Data([0x01, 0xD6, 0xFF, 0xA5]))
        #expect(complex == .complex(group1a: 3, group1b: 22, separator: 0xFF, group2a: 10, group2b: 5))
    }

    // MARK: - Mask with Skip

    @ParseEnum
    enum MaskWithSkip: Equatable {
        @matchAndTake(byte: 0x01)
        @skip(byteCount: 2, because: "reserved")
        @mask(bitCount: 4)
        @mask(bitCount: 4)
        case withPadding(UInt8, UInt8)
    }

    @Test("Enum with skip before mask fields")
    func enumMaskWithSkip() throws {
        // Match 0x01 (consumed), skip 2 bytes, then parse mask: 1100 0011 = 0xC3
        let result = try MaskWithSkip(parsing: Data([0x01, 0xFF, 0xFF, 0xC3]))
        #expect(result == .withPadding(12, 3))
    }

    // MARK: - Mask with matchDefault

    @ParseEnum
    enum MaskWithDefault: Equatable {
        @matchAndTake(byte: 0x01)
        @mask(bitCount: 4)
        @mask(bitCount: 4)
        case known(UInt8, UInt8)

        @matchDefault
        case unknown
    }

    @Test("Enum with mask and default case")
    func enumMaskWithDefault() throws {
        // Known case
        let known = try MaskWithDefault(parsing: Data([0x01, 0xAB]))
        #expect(known == .known(10, 11))

        // Unknown case (fallback)
        let unknown = try MaskWithDefault(parsing: Data([0xFF]))
        #expect(unknown == .unknown)
    }

    // MARK: - Multi-byte Mask in Enum

    @ParseEnum
    enum MultiByteMask: Equatable {
        @matchAndTake(byte: 0x01)
        @mask(bitCount: 12)
        @mask(bitCount: 4)
        case wide(UInt16, UInt8)
    }

    @Test("Enum with multi-byte mask field")
    func enumMultiByteMask() throws {
        // Match 0x01 (consumed), then parse 16 bits: 1010 1011 0011 0100 = 0xAB34
        // First 12 bits: 1010 1011 0011 = 0xAB3 = 2739
        // Last 4 bits: 0100 = 4
        let result = try MultiByteMask(parsing: Data([0x01, 0b1010_1011, 0b0011_0100]))
        #expect(result == .wide(0b1010_1011_0011_0000, 0b0100))
    }
}

// MARK: - @ParseEnum Mask Printing Integration Tests

@Suite
struct EnumMaskPrintingTest {
    // MARK: - Basic Mask Round-Trip Tests

    @ParseEnum
    enum BasicEnumWithMask: Equatable {
        @matchAndTake(byte: 0x01)
        @mask(bitCount: 1)
        @mask(bitCount: 7)
        case flags(UInt8, UInt8)

        @matchAndTake(byte: 0x02)
        @parse(endianness: .big)
        case simple(UInt16)
    }

    @Test("Enum with mask round-trip")
    func enumWithMaskRoundTrip() throws {
        // Match byte 0x01 (consumed), then parse: 1 0110100 = 0xB4
        let originalData = Data([0x01, 0b1011_0100])
        let parsed = try BasicEnumWithMask(parsing: originalData)

        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == originalData)
    }

    @Test("Enum with mask round-trip all zeros")
    func enumWithMaskRoundTripAllZeros() throws {
        let originalData = Data([0x01, 0x00])
        let parsed = try BasicEnumWithMask(parsing: originalData)

        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == originalData)
    }

    @Test("Enum with mask round-trip all ones")
    func enumWithMaskRoundTripAllOnes() throws {
        let originalData = Data([0x01, 0xFF])
        let parsed = try BasicEnumWithMask(parsing: originalData)

        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == originalData)
    }

    @Test("Enum simple case round-trip")
    func enumSimpleCaseRoundTrip() throws {
        let originalData = Data([0x02, 0x12, 0x34])
        let parsed = try BasicEnumWithMask(parsing: originalData)

        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == originalData)
    }

    // MARK: - Mixed Parse and Mask Round-Trip Tests

    @ParseEnum
    enum MixedParseAndMask: Equatable {
        @matchAndTake(byte: 0x01)
        @parse(endianness: .big)
        @mask(bitCount: 4)
        @mask(bitCount: 4)
        case mixed(UInt16, nibble1: UInt8, nibble2: UInt8)

        @matchAndTake(byte: 0x02)
        @mask(bitCount: 8)
        case singleMask(UInt8)
    }

    @Test("Enum with mixed @parse and @mask round-trip")
    func enumMixedParseAndMaskRoundTrip() throws {
        // Match 0x01 (consumed), then parse UInt16 BE (0x1234), then parse mask byte: 1010 0101 = 0xA5
        let originalData = Data([0x01, 0x12, 0x34, 0xA5])
        let parsed = try MixedParseAndMask(parsing: originalData)

        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == originalData)
    }

    @Test("Enum single mask case round-trip")
    func enumSingleMaskCaseRoundTrip() throws {
        let originalData = Data([0x02, 0x42])
        let parsed = try MixedParseAndMask(parsing: originalData)

        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == originalData)
    }

    // MARK: - Multiple Mask Groups Round-Trip Tests

    @ParseEnum
    enum MultipleMaskGroups: Equatable {
        @matchAndTake(byte: 0x01)
        @mask(bitCount: 2)
        @mask(bitCount: 6)
        @parse(endianness: .big)
        @mask(bitCount: 4)
        @mask(bitCount: 4)
        case complex(group1a: UInt8, group1b: UInt8, separator: UInt8, group2a: UInt8, group2b: UInt8)
    }

    @Test("Enum with multiple mask groups round-trip")
    func enumMultipleMaskGroupsRoundTrip() throws {
        // Match 0x01 (consumed)
        // First mask group: 11 010110 = 0xD6 -> group1a=3, group1b=22
        // Separator: 0xFF
        // Second mask group: 1010 0101 = 0xA5 -> group2a=10, group2b=5
        let originalData = Data([0x01, 0xD6, 0xFF, 0xA5])
        let parsed = try MultipleMaskGroups(parsing: originalData)

        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == originalData)
    }

    // MARK: - Mask with Skip Round-Trip Tests

    @ParseEnum
    enum MaskWithSkip: Equatable {
        @matchAndTake(byte: 0x01)
        @skip(byteCount: 2, because: "reserved")
        @mask(bitCount: 4)
        @mask(bitCount: 4)
        case withPadding(UInt8, UInt8)
    }

    @Test("Enum with skip before mask round-trip")
    func enumMaskWithSkipRoundTrip() throws {
        // Match 0x01 (consumed), skip 2 bytes, then parse mask: 1100 0011 = 0xC3
        let originalData = Data([0x01, 0xFF, 0xFF, 0xC3])
        let parsed = try MaskWithSkip(parsing: originalData)

        let printedBytes = try parsed.printParsed(printer: .data)
        // Skip bytes become zeros in output
        #expect(printedBytes == Data([0x01, 0x00, 0x00, 0xC3]))
    }

    // MARK: - Multi-byte Mask Round-Trip Tests

    @ParseEnum
    enum MultiByteMask: Equatable {
        @matchAndTake(byte: 0x01)
        @mask(bitCount: 12)
        @mask(bitCount: 4)
        case wide(UInt16, UInt8)
    }

    @Test("Enum with multi-byte mask round-trip")
    func enumMultiByteMaskRoundTrip() throws {
        // Match 0x01 (consumed), then parse 16 bits: 1010 1011 0011 0100 = 0xAB34
        let originalData = Data([0x01, 0b1010_1011, 0b0011_0100])
        let parsed = try MultiByteMask(parsing: originalData)

        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == originalData)
    }

    // MARK: - Edge Case Tests: Padding and Interleaving

    /// Non-byte-aligned mask (10 bits total)
    @ParseEnum
    enum NonByteAlignedMask: Equatable {
        @matchAndTake(byte: 0x01)
        @mask(bitCount: 3)
        @mask(bitCount: 5)
        @mask(bitCount: 2)
        case tenBits(UInt8, UInt8, UInt8)
    }

    @Test("Enum with non-byte-aligned mask (10 bits) round-trip")
    func enumNonByteAlignedMaskRoundTrip() throws {
        // Match 0x01 (consumed)
        // 101 01100 11 = 10 bits -> first=5, second=12, third=3
        // Byte representation: 10101100 11000000 = 0xAC 0xC0
        let originalData = Data([0x01, 0b1010_1100, 0b1100_0000])
        let parsed = try NonByteAlignedMask(parsing: originalData)
        #expect(parsed == .tenBits(0b101, 0b01100, 0b11))
        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == originalData)
    }

    /// 13-bit mask fields
    @ParseEnum
    enum ThirteenBitMask: Equatable {
        @matchAndTake(byte: 0x01)
        @mask(bitCount: 5)
        @mask(bitCount: 4)
        @mask(bitCount: 4)
        case thirteenBits(highBits: UInt8, middleBits: UInt8, lowBits: UInt8)
    }

    @Test("Enum with 13-bit mask round-trip")
    func enumThirteenBitMaskRoundTrip() throws {
        // Match 0x01 (consumed)
        // 10101 1100 0011 000 (padded to 16 bits) -> highBits=21, middleBits=12, lowBits=3
        // Bytes: 10101110 00011000 = 0xAE 0x18
        let originalData = Data([0x01, 0b1010_1110, 0b0001_1000])
        let parsed = try ThirteenBitMask(parsing: originalData)
        #expect(parsed == .thirteenBits(highBits: 0b10101, middleBits: 0b1100, lowBits: 0b0011))
        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == originalData)
    }

    /// Complex interleaving: Parse -> Mask -> Skip -> Mask -> Parse
    @ParseEnum
    enum InterleavedParseMaskSkipMaskParse: Equatable {
        @matchAndTake(byte: 0x01)
        @parse(endianness: .big)
        @mask(bitCount: 4)
        @mask(bitCount: 4)
        @skip(byteCount: 2, because: "reserved")
        @mask(bitCount: 2)
        @mask(bitCount: 6)
        @parse(endianness: .big)
        case complex(header: UInt8, nibble1: UInt8, nibble2: UInt8, twobit: UInt8, sixbit: UInt8, footer: UInt16)
    }

    @Test("Enum with interleaved parse-mask-skip-mask-parse round-trip")
    func enumInterleavedParseMaskSkipMaskParseRoundTrip() throws {
        // Match 0x01 (consumed)
        // header: 0x42
        // mask1: 1010 0101 -> nibble1=10, nibble2=5
        // skip: 0xFF 0xFF
        // mask2: 11 010110 -> twobit=3, sixbit=22
        // footer: 0x1234
        let originalData = Data([0x01, 0x42, 0b1010_0101, 0xFF, 0xFF, 0b1101_0110, 0x12, 0x34])
        let parsed = try InterleavedParseMaskSkipMaskParse(parsing: originalData)
        #expect(parsed == .complex(
            header: 0x42,
            nibble1: 0b1010,
            nibble2: 0b0101,
            twobit: 0b11,
            sixbit: 0b010110,
            footer: 0x1234,
        ))
        // Skip bytes become zeros
        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == Data([0x01, 0x42, 0b1010_0101, 0x00, 0x00, 0b1101_0110, 0x12, 0x34]))
    }

    /// Skip -> Mask -> Skip -> Parse pattern
    @ParseEnum
    enum SkipMaskSkipParse: Equatable {
        @matchAndTake(byte: 0x01)
        @skip(byteCount: 1, because: "header padding")
        @mask(bitCount: 8)
        @skip(byteCount: 2, because: "reserved")
        @parse(endianness: .little)
        case data(flags: UInt8, value: UInt16)
    }

    @Test("Enum with skip-mask-skip-parse round-trip")
    func enumSkipMaskSkipParseRoundTrip() throws {
        // Match 0x01 (consumed)
        // skip: 0xFF
        // mask: 0xAB -> flags=0xAB
        // skip: 0xFF 0xFF
        // parse LE: 0x34 0x12 -> value=0x1234
        let originalData = Data([0x01, 0xFF, 0xAB, 0xFF, 0xFF, 0x34, 0x12])
        let parsed = try SkipMaskSkipParse(parsing: originalData)
        #expect(parsed == .data(flags: 0xAB, value: 0x1234))
        // Skip bytes become zeros
        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == Data([0x01, 0x00, 0xAB, 0x00, 0x00, 0x34, 0x12]))
    }

    /// Multiple separate non-byte-aligned mask groups in enum
    @ParseEnum
    enum MultipleNonByteAlignedMaskGroups: Equatable {
        @matchAndTake(byte: 0x01)
        @mask(bitCount: 3)
        @mask(bitCount: 3)
        @mask(bitCount: 2)
        @parse(endianness: .big)
        @mask(bitCount: 5)
        @mask(bitCount: 5)
        @mask(bitCount: 6)
        case groups(
            group1High: UInt8, group1Mid: UInt8, group1Low: UInt8,
            separator: UInt8,
            group2High: UInt8, group2Mid: UInt8, group2Low: UInt8,
        )
    }

    @Test("Enum with multiple non-byte-aligned mask groups round-trip")
    func enumMultipleNonByteAlignedMaskGroupsRoundTrip() throws {
        // Match 0x01 (consumed)
        // First group (8 bits): 101 011 10 -> group1High=5, group1Mid=3, group1Low=2
        // separator: 0xFF
        // Second group (16 bits): 10101 01100 001100 -> group2High=21, group2Mid=12, group2Low=12
        let originalData = Data([0x01, 0b1010_1110, 0xFF, 0b1010_1011, 0b0000_1100])
        let parsed = try MultipleNonByteAlignedMaskGroups(parsing: originalData)
        #expect(parsed == .groups(
            group1High: 0b101, group1Mid: 0b011, group1Low: 0b10,
            separator: 0xFF,
            group2High: 0b10101, group2Mid: 0b01100, group2Low: 0b001100,
        ))
        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == originalData)
    }

    /// Eight single-bit mask fields in enum
    @ParseEnum
    enum SingleBitMasks: Equatable {
        @matchAndTake(byte: 0x01)
        @mask(bitCount: 1)
        @mask(bitCount: 1)
        @mask(bitCount: 1)
        @mask(bitCount: 1)
        @mask(bitCount: 1)
        @mask(bitCount: 1)
        @mask(bitCount: 1)
        @mask(bitCount: 1)
        case bits(UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)
    }

    @Test("Enum with eight single-bit masks round-trip")
    func enumEightSingleBitMasksRoundTrip() throws {
        // Match 0x01 (consumed)
        // 10101010 -> bit0=1, bit1=0, bit2=1, bit3=0, bit4=1, bit5=0, bit6=1, bit7=0
        let originalData = Data([0x01, 0b1010_1010])
        let parsed = try SingleBitMasks(parsing: originalData)
        #expect(parsed == .bits(1, 0, 1, 0, 1, 0, 1, 0))
        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == originalData)
    }

    @Test("Enum with eight single-bit masks all ones round-trip")
    func enumEightSingleBitMasksAllOnesRoundTrip() throws {
        let originalData = Data([0x01, 0xFF])
        let parsed = try SingleBitMasks(parsing: originalData)
        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == originalData)
    }

    @Test("Enum with eight single-bit masks all zeros round-trip")
    func enumEightSingleBitMasksAllZerosRoundTrip() throws {
        let originalData = Data([0x01, 0x00])
        let parsed = try SingleBitMasks(parsing: originalData)
        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == originalData)
    }

    /// Mask -> Parse -> Mask pattern in enum
    @ParseEnum
    enum MaskParseMask: Equatable {
        @matchAndTake(byte: 0x01)
        @mask(bitCount: 4)
        @mask(bitCount: 4)
        @parse(endianness: .big)
        @mask(bitCount: 3)
        @mask(bitCount: 5)
        case data(firstNibble: UInt8, secondNibble: UInt8, middleWord: UInt16, threeBit: UInt8, fiveBit: UInt8)
    }

    @Test("Enum with mask-parse-mask pattern round-trip")
    func enumMaskParseMaskRoundTrip() throws {
        // Match 0x01 (consumed)
        // First mask byte: 1010 0101 -> firstNibble=10, secondNibble=5
        // Parse word BE: 0x1234
        // Second mask byte: 111 01100 -> threeBit=7, fiveBit=12
        let originalData = Data([0x01, 0b1010_0101, 0x12, 0x34, 0b1110_1100])
        let parsed = try MaskParseMask(parsing: originalData)
        #expect(parsed == .data(
            firstNibble: 0b1010,
            secondNibble: 0b0101,
            middleWord: 0x1234,
            threeBit: 0b111,
            fiveBit: 0b01100,
        ))
        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == originalData)
    }

    /// Three separate mask groups in enum with different separators
    @ParseEnum
    enum ThreeMaskGroups: Equatable {
        @matchAndTake(byte: 0x01)
        @mask(bitCount: 4)
        @mask(bitCount: 4)
        @parse(endianness: .big)
        @mask(bitCount: 2)
        @mask(bitCount: 6)
        @parse(endianness: .little)
        @mask(bitCount: 1)
        @mask(bitCount: 7)
        case data(
            group1a: UInt8,
            group1b: UInt8,
            sep1: UInt8,
            group2a: UInt8,
            group2b: UInt8,
            sep2: UInt16,
            group3a: UInt8,
            group3b: UInt8,
        )
    }

    @Test("Enum with three separate mask groups round-trip")
    func enumThreeMaskGroupsRoundTrip() throws {
        // Match 0x01 (consumed)
        // Group1: 1100 0011 -> group1a=12, group1b=3
        // sep1: 0xAA
        // Group2: 10 110011 -> group2a=2, group2b=51
        // sep2 LE: 0x34 0x12 -> sep2=0x1234
        // Group3: 1 0101010 -> group3a=1, group3b=42
        let originalData = Data([0x01, 0b1100_0011, 0xAA, 0b1011_0011, 0x34, 0x12, 0b1010_1010])
        let parsed = try ThreeMaskGroups(parsing: originalData)
        #expect(parsed == .data(
            group1a: 0b1100,
            group1b: 0b0011,
            sep1: 0xAA,
            group2a: 0b10,
            group2b: 0b110011,
            sep2: 0x1234,
            group3a: 1,
            group3b: 0b0101010,
        ))
        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == originalData)
    }

    /// Multiple cases with different mask patterns
    @ParseEnum
    enum MultipleCasesWithMasks: Equatable {
        @matchAndTake(byte: 0x01)
        @mask(bitCount: 4)
        @mask(bitCount: 4)
        case nibbles(UInt8, UInt8)

        @matchAndTake(byte: 0x02)
        @mask(bitCount: 3)
        @mask(bitCount: 5)
        @mask(bitCount: 2)
        @mask(bitCount: 6)
        case mixedBits(UInt8, UInt8, UInt8, UInt8)

        @matchAndTake(byte: 0x03)
        @parse(endianness: .big)
        case noMask(UInt16)
    }

    @Test("Enum multiple cases with different mask patterns round-trip - nibbles case")
    func enumMultipleCasesNibblesRoundTrip() throws {
        // 1010 0101 -> nibble1=10, nibble2=5
        let originalData = Data([0x01, 0b1010_0101])
        let parsed = try MultipleCasesWithMasks(parsing: originalData)
        #expect(parsed == .nibbles(0b1010, 0b0101))
        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == originalData)
    }

    @Test("Enum multiple cases with different mask patterns round-trip - mixedBits case")
    func enumMultipleCasesMixedBitsRoundTrip() throws {
        // 101 01100 11 010110 -> a=5, b=12, c=3, d=22
        let originalData = Data([0x02, 0b1010_1100, 0b1101_0110])
        let parsed = try MultipleCasesWithMasks(parsing: originalData)
        #expect(parsed == .mixedBits(0b101, 0b01100, 0b11, 0b010110))
        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == originalData)
    }

    @Test("Enum multiple cases with different mask patterns round-trip - noMask case")
    func enumMultipleCasesNoMaskRoundTrip() throws {
        let originalData = Data([0x03, 0x12, 0x34])
        let parsed = try MultipleCasesWithMasks(parsing: originalData)
        #expect(parsed == .noMask(0x1234))
        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == originalData)
    }

    /// Match (not take) with masks
    @ParseEnum
    enum MatchWithMasks: Equatable {
        @match(byte: 0x01)
        @mask(bitCount: 4)
        @mask(bitCount: 4)
        case withMask(UInt8, UInt8)
    }

    @Test("Enum match (not take) with masks round-trip")
    func enumMatchWithMasksRoundTrip() throws {
        // Match 0x01 (NOT consumed) - so 0x01 is still at position 0
        // and becomes the mask byte: 0000 0001 -> nibble1=0, nibble2=1
        let originalData = Data([0x01, 0xA5])
        let parsed = try MatchWithMasks(parsing: originalData)
        #expect(parsed == .withMask(0, 1))
        // When printing, match bytes are NOT included since matchPolicy is .match (peek only)
        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == Data([0x01]))
    }

    /// matchDefault with masks
    @ParseEnum
    enum MatchDefaultWithMasks: Equatable {
        @matchAndTake(byte: 0x01)
        @mask(bitCount: 4)
        @mask(bitCount: 4)
        case known(UInt8, UInt8)

        @matchDefault
        @mask(bitCount: 8)
        case unknown(UInt8)
    }

    @Test("Enum matchDefault with masks round-trip - known case")
    func enumMatchDefaultWithMasksKnownRoundTrip() throws {
        // 1010 1011 -> nibble1=10, nibble2=11
        let originalData = Data([0x01, 0b1010_1011])
        let parsed = try MatchDefaultWithMasks(parsing: originalData)
        #expect(parsed == .known(0b1010, 0b1011))
        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == originalData)
    }

    @Test("Enum matchDefault with masks round-trip - unknown case")
    func enumMatchDefaultWithMasksUnknownRoundTrip() throws {
        // Any byte that's not 0x01 triggers default
        // Default doesn't consume match bytes, so 0xFF is read as the mask
        let originalData = Data([0xFF, 0x42])
        let parsed = try MatchDefaultWithMasks(parsing: originalData)
        #expect(parsed == .unknown(0xFF))
        // For matchDefault, no match bytes are printed, only the mask data
        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == Data([0xFF]))
    }
}
