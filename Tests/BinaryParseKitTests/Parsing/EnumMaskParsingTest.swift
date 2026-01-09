//
//  EnumMaskParsingTest.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/8/25.
//

import BinaryParseKit
import BinaryParsing
import Foundation
import Testing

extension ParsingTests { @Suite struct EnumMaskParsingTest {} }

// MARK: - @mask Integration Tests for Enums

extension ParsingTests.EnumMaskParsingTest {
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
        let flags = try BasicEnumWithMask(parsing: Data([0x01, 0b1011_0100]))
        #expect(flags == .flags(0b1, 0b0110100))

        // Simple case still works
        let simple = try BasicEnumWithMask(parsing: Data([0x02, 0x12, 0x34]))
        #expect(simple == .simple(0x1234))
    }

    @Test("Enum with mask - all zeros")
    func enumWithMaskAllZeros() throws {
        let flags = try BasicEnumWithMask(parsing: Data([0x01, 0b0000_0000]))
        #expect(flags == .flags(0b0, 0b0000000))
    }

    @Test("Enum with mask - all ones")
    func enumWithMaskAllOnes() throws {
        // 1 1111111 = 0xFF
        let flags = try BasicEnumWithMask(parsing: Data([0x01, 0b1111_1111]))
        #expect(flags == .flags(0b1, 0b1111111))
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
        let mixed = try MixedParseAndMask(parsing: Data([0x01, 0x12, 0x34, 0b1010_0101]))
        #expect(mixed == .mixed(0x1234, nibble1: 0b1010, nibble2: 0b0101))

        // Single mask case
        let single = try MixedParseAndMask(parsing: Data([0x02, 0b0100_0010]))
        #expect(single == .singleMask(0b0100_0010))
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
        let complex = try MultipleMaskGroups(parsing: Data([0x01, 0b1101_0110, 0xFF, 0b1010_0101]))
        #expect(complex == .complex(
            group1a: 0b11,
            group1b: 0b010110,
            separator: 0xFF,
            group2a: 0b1010,
            group2b: 0b0101,
        ))
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
        let result = try MaskWithSkip(parsing: Data([0x01, 0xFF, 0xFF, 0b1100_0011]))
        #expect(result == .withPadding(0b1100, 0b0011))
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
        let known = try MaskWithDefault(parsing: Data([0x01, 0b1010_1011]))
        #expect(known == .known(0b1010, 0b1011))

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
        let result = try MultiByteMask(parsing: Data([0x01, 0b1010_1011, 0b0011_0100]))
        #expect(result == .wide(0b1010_1011_0011, 0b0100))
    }

    // MARK: - Logic Tests (Insufficient & Excess Bits)

    /// A type with bitCount = 6 and RawBitsInteger = UInt8 for testing bit count logic.
    struct Strict6Bit: ExpressibleByRawBits, BitCountProviding, RawBitsConvertible, Equatable {
        static let bitCount = 6
        let value: UInt8

        init(bits: borrowing RawBitsSpan) throws {
            value = try bits.load(as: UInt8.self)
        }

        init(value: UInt8) {
            self.value = value
        }

        func toRawBits(bitCount: Int) throws -> RawBits {
            try value.toRawBits(bitCount: bitCount)
        }
    }

    @ParseEnum
    enum InsufficientBitsEnum: Equatable {
        @matchAndTake(byte: 0x01)
        @mask(bitCount: 5)
        case test(ParsingTests.EnumMaskParsingTest.Strict6Bit)
    }

    @Test("Throws error when bitCount < Type.bitCount")
    func insufficientBits() {
        #expect(throws: BitmaskParsableError.insufficientBitsAvailable) {
            try InsufficientBitsEnum(parsing: Data([0x01, 0b1111_1111]))
        }
    }

    @ParseEnum
    enum SameBitCountEnum: Equatable {
        @matchAndTake(byte: 0x01)
        @mask(bitCount: 6)
        case test(ParsingTests.EnumMaskParsingTest.Strict6Bit)
    }

    @Test("Exact bitCount equal to Type.bitCount")
    func sameBitCountBits() throws {
        let value = try SameBitCountEnum(parsing: Data([0x01, 0b1011_0100]))
        #expect(value == .test(Strict6Bit(value: 0b101101)))
    }

    @ParseEnum
    enum SufficientBitsEnum: Equatable {
        @matchAndTake(byte: 0x01)
        @mask(bitCount: 7)
        case test(ParsingTests.EnumMaskParsingTest.Strict6Bit)
    }

    @Test("Takes MSB when bitCount > Type.bitCount (7 > 6)")
    func sufficientBits() throws {
        let value = try SufficientBitsEnum(parsing: Data([0x01, 0b1011_0101]))
        #expect(value == .test(Strict6Bit(value: 0b101101)))
    }

    @ParseEnum
    enum ExcessBitsEnum: Equatable {
        @matchAndTake(byte: 0x01)
        @mask(bitCount: 15)
        case test(ParsingTests.EnumMaskParsingTest.Strict6Bit)
    }

    @Test("Takes MSB when bitCount > Type.bitCount (15 > 6)")
    func excessBits() throws {
        let value = try ExcessBitsEnum(parsing: Data([0x01, 0b1111_0000, 0b1111_0010]))
        #expect(value == .test(Strict6Bit(value: 0b111100)))
    }
}

// MARK: - Little Endian (LSB) Enum Mask Integration Tests

extension ParsingTests.EnumMaskParsingTest {
    // MARK: - Basic Little Endian Mask in Enum

    @ParseEnum(bitEndian: .little)
    enum LittleEndianBasicEnumWithMask: Equatable {
        @matchAndTake(byte: 0x01)
        @mask(bitCount: 1)
        @mask(bitCount: 7)
        case flags(UInt8, UInt8)

        @matchAndTake(byte: 0x02)
        @parse(endianness: .big)
        case simple(UInt16)
    }

    @Test("Little endian enum with mask associated values")
    func littleEndianEnumWithMaskValues() throws {
        let flags = try LittleEndianBasicEnumWithMask(parsing: Data([0x01, 0b1011_0100]))
        #expect(flags == .flags(0b0, 0b1011010))

        // Simple case still works (parse is not affected by bitEndian)
        let simple = try LittleEndianBasicEnumWithMask(parsing: Data([0x02, 0x12, 0x34]))
        #expect(simple == .simple(0x1234))
    }

    @Test("Little endian enum with mask - all zeros")
    func littleEndianEnumWithMaskAllZeros() throws {
        let flags = try LittleEndianBasicEnumWithMask(parsing: Data([0x01, 0b0000_0000]))
        #expect(flags == .flags(0b0, 0b0000000))
    }

    @Test("Little endian enum with mask - all ones")
    func littleEndianEnumWithMaskAllOnes() throws {
        let flags = try LittleEndianBasicEnumWithMask(parsing: Data([0x01, 0b1111_1111]))
        #expect(flags == .flags(0b1, 0b1111111))
    }

    // MARK: - Big vs Little Endian Enum Comparison

    @ParseEnum(bitEndian: .little)
    enum LittleEndianEnumComparison: Equatable {
        @matchAndTake(byte: 0x01)
        @mask(bitCount: 3)
        case value(UInt8)
    }

    @Test("Big vs Little endian enum comparison - same data, different results")
    func bigVsLittleEndianEnumComparison() throws {
        let littleEndian = try LittleEndianEnumComparison(parsing: Data([0x01, 0b1011_0011]))
        #expect(littleEndian == .value(0b011)) // 011 from LSB
    }

    // MARK: - Little Endian Mixed Parse and Mask

    @ParseEnum(bitEndian: .little)
    enum LittleEndianMixedParseAndMask: Equatable {
        @matchAndTake(byte: 0x01)
        @parse(endianness: .big)
        @mask(bitCount: 4)
        @mask(bitCount: 4)
        case mixed(UInt16, nibble1: UInt8, nibble2: UInt8)

        @matchAndTake(byte: 0x02)
        @mask(bitCount: 8)
        case singleMask(UInt8)
    }

    @Test("Little endian enum with mixed @parse and @mask")
    func littleEndianEnumMixedParseAndMask() throws {
        let mixed = try LittleEndianMixedParseAndMask(parsing: Data([0x01, 0x12, 0x34, 0b1010_0101]))
        #expect(mixed == .mixed(0x1234, nibble1: 0b0101, nibble2: 0b1010))

        // Single mask case - full byte
        let single = try LittleEndianMixedParseAndMask(parsing: Data([0x02, 0b0100_0010]))
        #expect(single == .singleMask(0b0100_0010))
    }

    // MARK: - Little Endian Multiple Mask Groups

    @ParseEnum(bitEndian: .little)
    enum LittleEndianMultipleMaskGroups: Equatable {
        @matchAndTake(byte: 0x01)
        @mask(bitCount: 2)
        @mask(bitCount: 5)
        @parse(endianness: .big)
        @mask(bitCount: 5)
        @mask(bitCount: 4)
        @mask(bitCount: 2)
        @parse(endianness: .big)
        @mask(bitCount: 4)
        @mask(bitCount: 3)
        case complex(
            group1a: UInt8,
            group1b: UInt8,
            separator1: UInt8,
            group2a: UInt8,
            group2b: UInt8,
            group2c: UInt8,
            separator2: UInt8,
            group3a: UInt8,
            group3c: UInt8,
        )
    }

    @Test("Little endian enum with multiple separate mask groups")
    func littleEndianEnumMultipleMaskGroups() throws {
        let complex = try LittleEndianMultipleMaskGroups(parsing: Data([
            0x01,
            0b1101_0110,
            0xFF,
            0b0101_1010,
            0b1011_1010,
            0xFF,
            0b1010_0101,
        ]))
        #expect(
            complex == .complex(
                group1a: 0b10,
                group1b: 0b10101,
                separator1: 0xFF,
                group2a: 0b11010,
                group2b: 0b0101,
                group2c: 0b01,
                separator2: 0xFF,
                group3a: 0b0101,
                group3c: 0b010,
            ),
        )
    }

    // MARK: - Little Endian with Skip

    @ParseEnum(bitEndian: .little)
    enum LittleEndianMaskWithSkip: Equatable {
        @matchAndTake(byte: 0x01)
        @skip(byteCount: 2, because: "reserved")
        @mask(bitCount: 4)
        @mask(bitCount: 4)
        case withPadding(UInt8, UInt8)
    }

    @Test("Little endian enum with skip before mask fields")
    func littleEndianEnumMaskWithSkip() throws {
        let result = try LittleEndianMaskWithSkip(parsing: Data([0x01, 0xFF, 0xFF, 0b1100_0011]))
        #expect(result == .withPadding(0b0011, 0b1100))
    }

    // MARK: - Little Endian 1 bit

    @ParseEnum(bitEndian: .little)
    enum LittleEndianSingleBitEnum: Equatable {
        @matchAndTake(byte: 0x01)
        @mask(bitCount: 1)
        case flag(UInt8)
    }

    @Test("Little endian enum single bit - LSB is 1")
    func littleEndianEnumSingleBitOne() throws {
        let result = try LittleEndianSingleBitEnum(parsing: Data([0x01, 0b0000_0001]))
        #expect(result == .flag(0b1))
    }

    @Test("Little endian enum single bit - LSB is 0")
    func littleEndianEnumSingleBitZero() throws {
        let result = try LittleEndianSingleBitEnum(parsing: Data([0x01, 0b1000_0000]))
        #expect(result == .flag(0b0))
    }

    @Test("Little endian enum single bit - 0xFE has LSB 0")
    func littleEndianEnumSingleBitFE() throws {
        let result = try LittleEndianSingleBitEnum(parsing: Data([0x01, 0b1111_1110]))
        #expect(result == .flag(0b0))
    }

    // MARK: - Little Endian with matchDefault

    @ParseEnum(bitEndian: .little)
    enum LittleEndianMaskWithDefault: Equatable {
        @matchAndTake(byte: 0x01)
        @mask(bitCount: 4)
        @mask(bitCount: 4)
        case known(UInt8, UInt8)

        @matchDefault
        case unknown
    }

    @Test("Little endian enum with mask and default case")
    func littleEndianEnumMaskWithDefault() throws {
        let known = try LittleEndianMaskWithDefault(parsing: Data([0x01, 0b1010_1011]))
        #expect(known == .known(0b1011, 0b1010))

        // Unknown case (fallback)
        let unknown = try LittleEndianMaskWithDefault(parsing: Data([0xFF]))
        #expect(unknown == .unknown)
    }

    // MARK: - Little Endian Excess Bits

    @ParseEnum(bitEndian: .little)
    enum LittleEndianExcessBitsEnum: Equatable {
        @matchAndTake(byte: 0x01)
        @mask(bitCount: 10)
        case test(ParsingTests.EnumMaskParsingTest.Strict6Bit)
    }

    @Test("Little endian takes LSB when bitCount > Type.bitCount")
    func littleEndianEnumExcessBits() throws {
        let value = try LittleEndianExcessBitsEnum(parsing: Data([0x01, 0b1111_0000, 0b1100_0100]))
        #expect(value == .test(Strict6Bit(value: 0b000100)))
    }

    // MARK: - Little Endian Unaligned Single Byte Enum

    @ParseEnum(bitEndian: .little)
    enum LittleEndianUnalignedSingleByte: Equatable {
        @matchAndTake(byte: 0x01)
        @mask(bitCount: 2)
        @mask(bitCount: 3)
        @mask(bitCount: 3)
        case threeFields(first: UInt8, second: UInt8, third: UInt8)
    }

    @Test("Little endian enum unaligned single byte")
    func littleEndianEnumUnalignedSingleByte() throws {
        let result = try LittleEndianUnalignedSingleByte(parsing: Data([0x01, 0b1101_0101]))
        #expect(
            result == .threeFields(
                first: 0b01,
                second: 0b101,
                third: 0b110,
            ),
        )
    }

    // MARK: - Little Endian Three Byte Crossing Enum

    @ParseEnum(bitEndian: .little)
    enum LittleEndianThreeByteCrossing: Equatable {
        @matchAndTake(byte: 0x01)
        @mask(bitCount: 5)
        @mask(bitCount: 11)
        @mask(bitCount: 8)
        case wideFields(first: UInt8, second: UInt16, third: UInt8)
    }

    @Test("Little endian enum spanning 3 bytes")
    func littleEndianEnumThreeByteCrossing() throws {
        let result = try LittleEndianThreeByteCrossing(parsing: Data([
            0x01,
            0b1101_0101, 0b1011_0011, 0b1111_0000,
        ]))
        #expect(
            result == .wideFields(
                first: 0b010000,
                second: 0b101_1001_1111,
                third: 0b1101_0101,
            ),
        )
    }

    // MARK: - Little Endian Single Bit Fields Enum

    @ParseEnum(bitEndian: .little)
    enum LittleEndianSingleBitFieldsEnum: Equatable {
        @matchAndTake(byte: 0x01)
        @mask(bitCount: 1)
        @mask(bitCount: 1)
        @mask(bitCount: 1)
        @mask(bitCount: 1)
        @mask(bitCount: 1)
        @mask(bitCount: 1)
        @mask(bitCount: 1)
        @mask(bitCount: 1)
        case eightBits(
            b0: UInt8, b1: UInt8, b2: UInt8, b3: UInt8,
            b4: UInt8, b5: UInt8, b6: UInt8, b7: UInt8,
        )
    }

    @Test("Little endian enum single bit fields")
    func littleEndianEnumSingleBitFields() throws {
        let result = try LittleEndianSingleBitFieldsEnum(parsing: Data([0x01, 0b1010_1010]))
        #expect(
            result == .eightBits(
                b0: 0b0,
                b1: 0b1,
                b2: 0b0,
                b3: 0b1,
                b4: 0b0,
                b5: 0b1,
                b6: 0b0,
                b7: 0b1,
            ),
        )
    }

    // MARK: - Little Endian Non-Power-of-Two Enum

    @ParseEnum(bitEndian: .little)
    enum LittleEndianNonPowerOfTwoEnum: Equatable {
        @matchAndTake(byte: 0x01)
        @mask(bitCount: 3)
        @mask(bitCount: 5)
        @mask(bitCount: 7)
        @mask(bitCount: 9)
        case nonPowerOfTwo(three: UInt8, five: UInt8, seven: UInt8, nine: UInt16)
    }

    @Test("Little endian enum with non-power-of-two fields")
    func littleEndianEnumNonPowerOfTwo() throws {
        let result = try LittleEndianNonPowerOfTwoEnum(parsing: Data([
            0x01,
            0b1111_1010, 0b1001_0101, 0b1011_0011,
        ]))
        #expect(
            result == .nonPowerOfTwo(
                three: 0b011,
                five: 0b10110,
                seven: 0b0010101,
                nine: 0b1_1111_0101,
            ),
        )
    }

    // MARK: - Big vs Little Endian Enum Comparison

    @ParseEnum(bitEndian: .big)
    enum BigEndianEnumComparison: Equatable {
        @matchAndTake(byte: 0x01)
        @mask(bitCount: 3)
        @mask(bitCount: 5)
        case values(first: UInt8, second: UInt8)
    }

    @ParseEnum(bitEndian: .little)
    enum LittleEndianEnumComparisonFull: Equatable {
        @matchAndTake(byte: 0x01)
        @mask(bitCount: 3)
        @mask(bitCount: 5)
        case values(first: UInt8, second: UInt8)
    }

    @Test("Big vs Little endian enum - same data produces different values")
    func bigVsLittleEndianEnumComparisonFull() throws {
        let data = Data([0x01, 0b1011_0011])
        let bigResult = try BigEndianEnumComparison(parsing: data)
        #expect(
            bigResult == .values(
                first: 0b101,
                second: 0b10011,
            ),
        )

        let littleResult = try LittleEndianEnumComparisonFull(parsing: data)
        #expect(
            littleResult == .values(
                first: 0b011,
                second: 0b10110,
            ),
        )
    }

    // MARK: - Little Endian Multiple Mask Groups with Multiple Separators

    @ParseEnum(bitEndian: .little)
    enum LittleEndianMultipleSeparators: Equatable {
        @matchAndTake(byte: 0x01)
        @mask(bitCount: 3)
        @mask(bitCount: 5)
        @parse(endianness: .big)
        @mask(bitCount: 4)
        @mask(bitCount: 4)
        @parse(endianness: .big)
        @mask(bitCount: 2)
        @mask(bitCount: 6)
        case complex(
            g1a: UInt8,
            g1b: UInt8,
            sep1: UInt8,
            g2a: UInt8,
            g2b: UInt8,
            sep2: UInt16,
            g3a: UInt8,
            g3b: UInt8,
        )
    }

    @Test("Little endian enum with multiple parse separators")
    func littleEndianEnumMultipleSeparators() throws {
        let result = try LittleEndianMultipleSeparators(parsing: Data([
            0x01, // match
            0b1101_0101, // mask group 1 (3+5=8 bits)
            0xAA, // sep1
            0b1011_0011, // mask group 2 (4+4=8 bits)
            0x12, 0x34, // sep2 (UInt16 big endian)
            0b1110_0010, // mask group 3 (2+6=8 bits)
        ]))
        #expect(
            result == .complex(
                g1a: 0b101, // bits[0-2]
                g1b: 0b11010, // bits[3-7]
                sep1: 0xAA,
                g2a: 0b0011, // bits[0-3]
                g2b: 0b1011, // bits[4-7]
                sep2: 0x1234,
                g3a: 0b10, // bits[0-1]
                g3b: 0b111000, // bits[2-7]
            ),
        )
    }

    // MARK: - Little Endian Maximum Values Enum

    @ParseEnum(bitEndian: .little)
    enum LittleEndianMaxValuesEnum: Equatable {
        @matchAndTake(byte: 0x01)
        @mask(bitCount: 3)
        @mask(bitCount: 6)
        @mask(bitCount: 7)
        case maxValues(three: UInt8, six: UInt8, seven: UInt8)
    }

    @Test("Little endian enum maximum values")
    func littleEndianEnumMaxValues() throws {
        // All ones
        let result = try LittleEndianMaxValuesEnum(parsing: Data([0x01, 0b1111_1111, 0b1111_1111]))
        #expect(
            result == .maxValues(
                three: 0b111,
                six: 0b111111,
                seven: 0b1111111,
            ),
        )
    }

    // MARK: - Little Endian All Zeros Enum

    @Test("Little endian enum all zeros")
    func littleEndianEnumAllZeros() throws {
        let result = try LittleEndianMaxValuesEnum(parsing: Data([0x01, 0x00, 0x00]))
        #expect(
            result == .maxValues(
                three: 0b0,
                six: 0b0,
                seven: 0b0,
            ),
        )
    }

    // MARK: - Little Endian Wide Bitmask Enum

    @ParseEnum(bitEndian: .little)
    enum LittleEndianWideBitmaskEnum: Equatable {
        @matchAndTake(byte: 0x01)
        @mask(bitCount: 12)
        @mask(bitCount: 20)
        case wideValues(twelve: UInt16, twenty: UInt32)
    }

    @Test("Little endian enum wide bitmask fields")
    func littleEndianEnumWideBitmask() throws {
        let result = try LittleEndianWideBitmaskEnum(parsing: Data([
            0x01,
            0b1101_0101, 0b1011_0011, 0b1111_0000, 0b1010_1010,
        ]))
        #expect(
            result == .wideValues(
                twelve: 0b0000_1010_1010,
                twenty: 0b1101_0101_1011_0011_1111,
            ),
        )
    }

    // MARK: - Little Endian Enum with Multiple Cases

    @ParseEnum(bitEndian: .little)
    enum LittleEndianMultiCaseEnum: Equatable {
        @matchAndTake(byte: 0x01)
        @mask(bitCount: 4)
        @mask(bitCount: 4)
        case caseA(low: UInt8, high: UInt8)

        @matchAndTake(byte: 0x02)
        @mask(bitCount: 2)
        @mask(bitCount: 3)
        @mask(bitCount: 3)
        case caseB(first: UInt8, second: UInt8, third: UInt8)

        @matchAndTake(byte: 0x03)
        @parse(endianness: .big)
        case caseC(value: UInt16)

        @matchDefault
        case unknown
    }

    @Test("Little endian enum with multiple cases - case A")
    func littleEndianEnumMultiCaseA() throws {
        let result = try LittleEndianMultiCaseEnum(parsing: Data([0x01, 0b1010_1111]))
        #expect(result == .caseA(low: 0b1111, high: 0b1010))
    }

    @Test("Little endian enum with multiple cases - case B")
    func littleEndianEnumMultiCaseB() throws {
        let result = try LittleEndianMultiCaseEnum(parsing: Data([0x02, 0b1101_0101]))
        #expect(result == .caseB(first: 0b01, second: 0b101, third: 0b110))
    }

    @Test("Little endian enum with multiple cases - case C (parse not affected)")
    func littleEndianEnumMultiCaseC() throws {
        let result = try LittleEndianMultiCaseEnum(parsing: Data([0x03, 0x12, 0x34]))
        #expect(result == .caseC(value: 0x1234))
    }

    @Test("Little endian enum with multiple cases - default")
    func littleEndianEnumMultiCaseDefault() throws {
        let result = try LittleEndianMultiCaseEnum(parsing: Data([0xFF]))
        #expect(result == .unknown)
    }
}
