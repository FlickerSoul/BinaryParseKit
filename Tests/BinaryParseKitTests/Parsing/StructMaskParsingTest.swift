//
//  StructMaskParsingTest.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 7/17/25.
//

import BinaryParseKit
import BinaryParsing
import Foundation
import Testing

extension ParsingTests { @Suite struct StructMaskParsingTest {} }

// MARK: - @mask Integration Tests

extension ParsingTests.StructMaskParsingTest {
    // MARK: - Custom Types for Bitmask Testing

    /// A simple flag type that conforms to BitmaskParsable with 1 bit.
    struct Flag: ExpressibleByRawBits, BitCountProviding, RawBitsConvertible, Equatable {
        static var bitCount: Int {
            1
        }

        let value: Bool

        init(value: Bool) {
            self.value = value
        }

        init(bits: borrowing RawBitsSpan) throws {
            let intValue: UInt8 = try bits.load()
            value = intValue & 1 == 1
        }

        func toRawBits(bitCount: Int) throws -> RawBits {
            try value.toRawBits(bitCount: bitCount)
        }
    }

    /// A 4-bit nibble type that conforms to BitmaskParsable.
    struct Nibble: ExpressibleByRawBits, BitCountProviding, RawBitsConvertible, Equatable {
        static var bitCount: Int {
            4
        }

        let value: UInt8

        init(value: UInt8) {
            precondition(value <= 0b1111, "Nibble value must be 0-15")
            self.value = value
        }

        init(bits: borrowing RawBitsSpan) throws {
            value = try bits.load()
        }

        func toRawBits(bitCount: Int) throws -> RawBits {
            try value.toRawBits(bitCount: bitCount)
        }
    }

    /// A 3-bit value type for testing.
    struct ThreeBit: ExpressibleByRawBits, BitCountProviding, RawBitsConvertible, Equatable {
        static var bitCount: Int {
            3
        }

        let value: UInt8

        init(value: UInt8) {
            precondition(value <= 0b111, "ThreeBit value must be 0-7")
            self.value = value
        }

        init(bits: borrowing RawBitsSpan) throws {
            value = try bits.load()
        }

        func toRawBits(bitCount: Int) throws -> RawBits {
            try value.toRawBits(bitCount: bitCount)
        }
    }

    // MARK: - Basic Mask Fields with Explicit Bit Count

    @ParseStruct
    struct BasicBitmaskExplicit: Equatable {
        @mask(bitCount: 1)
        var flag1: UInt8

        @mask(bitCount: 3)
        var value: UInt8

        @mask(bitCount: 4)
        var nibble: UInt8
    }

    @Test("Basic bitmask parsing with explicit bit counts - all bits from single byte")
    func basicBitmaskExplicitParsing() throws {
        let parsed = try BasicBitmaskExplicit(parsing: Data([0b1010_0011]))
        #expect(parsed == BasicBitmaskExplicit(flag1: 0b1, value: 0b010, nibble: 0b0011))
    }

    @Test("Basic bitmask parsing - all zeros")
    func basicBitmaskExplicitAllZeros() throws {
        let parsed = try BasicBitmaskExplicit(parsing: Data([0b0000_0000]))
        #expect(parsed == BasicBitmaskExplicit(flag1: 0, value: 0, nibble: 0))
    }

    @Test("Basic bitmask parsing - all ones")
    func basicBitmaskExplicitAllOnes() throws {
        // Binary: 1 111 1111 = 0xFF
        let parsed = try BasicBitmaskExplicit(parsing: Data([0b1111_1111]))
        #expect(parsed == BasicBitmaskExplicit(flag1: 0b1, value: 0b111, nibble: 0b1111))
    }

    // MARK: - Inferred Bit Count with Custom Types

    @ParseStruct
    struct BitmaskInferred: Equatable {
        @mask
        var flag1: ParsingTests.StructMaskParsingTest.Flag

        @mask
        var flag2: ParsingTests.StructMaskParsingTest.Flag

        @mask(bitCount: 6)
        var value: UInt8
    }

    @Test("Inferred bitCount from BitmaskParsable type")
    func inferredBitmaskParsing() throws {
        let parsed = try BitmaskInferred(parsing: Data([0b1000_0101]))
        #expect(parsed == BitmaskInferred(flag1: Flag(value: true), flag2: Flag(value: false), value: 0b000101))
    }

    @ParseStruct
    struct BitmaskAllInferred: Equatable {
        @mask
        var first: ParsingTests.StructMaskParsingTest.Flag

        @mask
        var second: ParsingTests.StructMaskParsingTest.Nibble

        @mask
        var third: ParsingTests.StructMaskParsingTest.ThreeBit
    }

    @Test("All fields with inferred bit counts")
    func allInferredBitmaskParsing() throws {
        let parsed = try BitmaskAllInferred(parsing: Data([0b1101_0011]))
        #expect(parsed == BitmaskAllInferred(
            first: Flag(value: true),
            second: Nibble(value: 0b1010),
            third: ThreeBit(value: 0b011),
        ))
    }

    // MARK: - Multi-Byte Bitmask

    @ParseStruct
    struct MultiBytesBitmask: Equatable {
        @mask(bitCount: 4)
        var high: UInt8

        @mask(bitCount: 8)
        var middle: UInt8

        @mask(bitCount: 4)
        var low: UInt8
    }

    @Test("Multi-byte bitmask spanning 2 bytes")
    func multiBytesBitmaskParsing() throws {
        let parsed = try MultiBytesBitmask(parsing: Data([0b1010_1011, 0b0011_0100]))
        #expect(parsed == MultiBytesBitmask(high: 0b1010, middle: 0b1011_0011, low: 0b0100))
    }

    // MARK: - Mixed Parse and Mask

    @ParseStruct
    struct MixedParseMask: Equatable {
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
        let parsed = try MixedParseMask(parsing: Data([0x42, 0b1011_0100, 0x12, 0x34]))
        #expect(parsed == MixedParseMask(header: 0x42, flag: 0b1, value: 0b0110100, footer: 0x1234))
    }

    // MARK: - Multiple Mask Groups

    @ParseStruct
    struct MultipleMaskGroups: Equatable {
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
        let parsed = try MultipleMaskGroups(parsing: Data([0b1010_0101, 0xFF, 0b1101_0110]))
        #expect(parsed == MultipleMaskGroups(
            first: 0b1010,
            second: 0b0101,
            separator: 0xFF,
            third: 0b11,
            fourth: 0b010110,
        ))
    }

    // MARK: - Error Cases

    @ParseStruct
    struct MaskWithInsufficientData: Equatable {
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
    struct SkipWithMask: Equatable {
        @skip(byteCount: 2, because: "header padding")
        @mask(bitCount: 4)
        var value: UInt8

        @mask(bitCount: 4)
        var flags: UInt8
    }

    @Test("Skip before mask fields")
    func skipBeforeMaskParsing() throws {
        // Skip 2 bytes, then parse mask byte: 1100 0011 = 0xC3
        let parsed = try SkipWithMask(parsing: Data([0xFF, 0xFF, 0b1100_0011]))
        #expect(parsed == SkipWithMask(value: 0b1100, flags: 0b0011))
    }

    // MARK: - Logic Tests (Insufficient & Excess Bits)

    /// A type with bitCount = 6 and RawBitsInteger = UInt8 for testing bit count logic.
    struct Strict6Bit: ExpressibleByRawBits, BitCountProviding, RawBitsConvertible, Equatable {
        static let bitCount = 6
        let value: UInt8

        init(value: UInt8) {
            self.value = value & 0b0011_1111
        }

        init(bits: borrowing RawBitsSpan) throws {
            value = try bits.load()
        }

        func toRawBits(bitCount: Int) throws -> RawBits {
            try value.toRawBits(bitCount: bitCount)
        }
    }

    @ParseStruct
    struct InsufficientBitsStruct: Equatable {
        @mask(bitCount: 5)
        var field: ParsingTests.StructMaskParsingTest.Strict6Bit
    }

    @Test("Throws error when bitCount < Type.bitCount")
    func insufficientBits() {
        #expect(throws: BitmaskParsableError.insufficientBitsAvailable) {
            try InsufficientBitsStruct(parsing: Data([0xFF]))
        }
    }

    @ParseStruct
    struct SameBitCountStruct: Equatable {
        @mask(bitCount: 6)
        var field: ParsingTests.StructMaskParsingTest.Strict6Bit
    }

    @Test("Exact bitCount equal to Type.bitCount")
    func sameBitCountBits() throws {
        // Input: 1011_0100 (first 6 bits: 101101 = 45)
        let parsed = try SameBitCountStruct(parsing: Data([0b1011_0100]))
        #expect(parsed == SameBitCountStruct(field: Strict6Bit(value: 0b101101)))
    }

    @ParseStruct
    struct SufficientBitsStruct: Equatable {
        @mask(bitCount: 7)
        var field: ParsingTests.StructMaskParsingTest.Strict6Bit
    }

    @Test("Takes MSB when bitCount > Type.bitCount (7 > 6)")
    func sufficientBits() throws {
        // Input: 1011_0101 (first 7 bits: 1011010 = 90)
        // Take MSB 6 bits: 101101 = 45
        let parsed = try SufficientBitsStruct(parsing: Data([0b1011_0101]))
        #expect(parsed == SufficientBitsStruct(field: Strict6Bit(value: 0b101101)))
    }

    @ParseStruct
    struct ExcessBitsStruct: Equatable {
        @mask(bitCount: 15)
        var field: ParsingTests.StructMaskParsingTest.Strict6Bit
    }

    @Test("Takes MSB when bitCount > Type.bitCount (15 > 6)")
    func excessBits() throws {
        let parsed = try ExcessBitsStruct(parsing: Data([0b1111_0000, 0b1111_0010]))
        #expect(parsed == ExcessBitsStruct(field: Strict6Bit(value: 0b111100)))
    }
}

// MARK: - Little Endian (LSB) Struct Mask Integration Tests

extension ParsingTests.StructMaskParsingTest {
    // MARK: - Basic Little Endian Mask Fields

    /// Tests that @ParseStruct(bitEndian: .little) compiles and parses successfully.
    @ParseStruct(bitEndian: .little)
    struct LittleEndianBasicMask: Equatable {
        @mask(bitCount: 1)
        var flag1: UInt8

        @mask(bitCount: 3)
        var value: UInt8

        @mask(bitCount: 4)
        var nibble: UInt8
    }

    @Test("Little endian struct mask parses without error")
    func littleEndianBasicMaskParsing() throws {
        let parsed = try LittleEndianBasicMask(parsing: Data([0b1010_0011]))
        #expect(
            parsed == .init(
                flag1: 0b1,
                value: 0b001,
                nibble: 0b1010,
            ),
        )
    }

    @Test("Little endian struct mask - all zeros")
    func littleEndianBasicMaskAllZeros() throws {
        let parsed = try LittleEndianBasicMask(parsing: Data([0x00]))
        #expect(
            parsed == .init(
                flag1: 0,
                value: 0,
                nibble: 0,
            ),
        )
    }

    @Test("Little endian struct mask - all ones")
    func littleEndianBasicMaskAllOnes() throws {
        let parsed = try LittleEndianBasicMask(parsing: Data([0xFF]))
        #expect(
            parsed == .init(
                flag1: 0b1,
                value: 0b111,
                nibble: 0b1111,
            ),
        )
    }

    // MARK: - Little Endian Mixed Parse and Mask

    @ParseStruct(bitEndian: .little)
    struct LittleEndianMixedParseMask {
        @parse(endianness: .big)
        var header: UInt8

        @mask(bitCount: 2)
        var flag: UInt8

        @mask(bitCount: 3)
        var value: UInt8

        @parse(endianness: .big)
        var footer: UInt8
    }

    @Test("Little endian mixed @parse and @mask fields")
    func littleEndianMixedParseMaskParsing() throws {
        let parsed = try LittleEndianMixedParseMask(parsing: Data([0x42, 0b1011_0101, 0x99]))
        #expect(parsed.header == 0x42)
        #expect(parsed.flag == 0b01)
        #expect(parsed.value == 0b101)
        #expect(parsed.footer == 0x99)
    }

    // MARK: - Little Endian with Custom Types

    @ParseStruct(bitEndian: .little)
    struct LittleEndianWithCustomTypes: Equatable {
        @mask
        var flag: ParsingTests.StructMaskParsingTest.Flag

        @mask
        var nibble: ParsingTests.StructMaskParsingTest.Nibble

        @mask
        var threeBit: ParsingTests.StructMaskParsingTest.ThreeBit
    }

    @Test("Little endian struct with inferred bit count custom types parses")
    func littleEndianWithCustomTypesParsing() throws {
        let parsed = try LittleEndianWithCustomTypes(parsing: Data([0b1101_1011]))
        #expect(
            parsed == .init(
                flag: .init(value: true),
                nibble: .init(value: 0b1101),
                threeBit: .init(value: 0b110),
            ),
        )
    }

    // MARK: - Little Endian Multiple Mask Groups

    @ParseStruct(bitEndian: .little)
    struct LittleEndianMultipleMaskGroups: Equatable {
        @mask(bitCount: 3)
        var first: UInt8

        @mask(bitCount: 4)
        var second: UInt8

        @mask(bitCount: 7)
        var third: UInt8

        @parse(endianness: .big)
        var separator: UInt8

        @mask(bitCount: 1)
        var fourth: UInt8

        @mask(bitCount: 6)
        var fifth: UInt8
    }

    @Test("Little endian multiple separate mask groups")
    func littleEndianMultipleMaskGroupsParsing() throws {
        let parsed = try LittleEndianMultipleMaskGroups(parsing: Data([0b1011_0100, 0b1010_0110, 0xFF, 0b1101_0110]))
        #expect(
            parsed == .init(
                first: 0b110,
                second: 0b0100,
                third: 0b1101001,
                separator: 0xFF,
                fourth: 0b0,
                fifth: 0b101011,
            ),
        )
    }

    // MARK: - Little Endian Unaligned Single Byte

    @ParseStruct(bitEndian: .little)
    struct LittleEndianUnalignedSingleByte: Equatable {
        @mask(bitCount: 2)
        var first: UInt8

        @mask(bitCount: 3)
        var second: UInt8

        @mask(bitCount: 3)
        var third: UInt8
    }

    @Test("Little endian unaligned single byte parsing")
    func littleEndianUnalignedSingleByte() throws {
        let parsed = try LittleEndianUnalignedSingleByte(parsing: Data([0b1101_0101]))
        #expect(
            parsed == .init(
                first: 0b01,
                second: 0b101,
                third: 0b110,
            ),
        )
    }

    // MARK: - Little Endian Three Byte Crossing

    @ParseStruct(bitEndian: .little)
    struct LittleEndianThreeByteCrossing: Equatable {
        @mask(bitCount: 5)
        var first: UInt8

        @mask(bitCount: 11)
        var second: UInt16

        @mask(bitCount: 8)
        var third: UInt8
    }

    @Test("Little endian struct spanning 3 bytes")
    func littleEndianThreeByteCrossingParsing() throws {
        let parsed = try LittleEndianThreeByteCrossing(parsing: Data([0b1101_0101, 0b1011_0011, 0b1111_0000]))
        #expect(
            parsed == .init(
                first: 0b10000,
                second: 0b101_1001_1111,
                third: 0b1101_0101,
            ),
        )
    }

    // MARK: - Little Endian Single Bit Fields

    @ParseStruct(bitEndian: .little)
    struct LittleEndianSingleBitFields: Equatable {
        @mask(bitCount: 1)
        var b0: UInt8
        @mask(bitCount: 1)
        var b1: UInt8
        @mask(bitCount: 1)
        var b2: UInt8
        @mask(bitCount: 1)
        var b3: UInt8
        @mask(bitCount: 1)
        var b4: UInt8
        @mask(bitCount: 1)
        var b5: UInt8
        @mask(bitCount: 1)
        var b6: UInt8
        @mask(bitCount: 1)
        var b7: UInt8
    }

    @Test("Little endian struct single bit fields")
    func littleEndianSingleBitFieldsParsing() throws {
        // Input: 0b10101010
        let parsed = try LittleEndianSingleBitFields(parsing: Data([0b1010_1010]))
        // LSB order: b0=bit0=0, b1=bit1=1, etc.
        #expect(
            parsed == .init(
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

    // MARK: - Little Endian Non-Power-of-Two Fields

    @ParseStruct(bitEndian: .little)
    struct LittleEndianNonPowerOfTwo: Equatable {
        @mask(bitCount: 3)
        var three: UInt8

        @mask(bitCount: 5)
        var five: UInt8

        @mask(bitCount: 7)
        var seven: UInt8

        @mask(bitCount: 9)
        var nine: UInt16
    }

    @Test("Little endian struct with non-power-of-two fields")
    func littleEndianNonPowerOfTwoParsing() throws {
        let parsed = try LittleEndianNonPowerOfTwo(parsing: Data([0b1111_1010, 0b1001_0101, 0b1011_0011]))
        #expect(
            parsed == .init(
                three: 0b011,
                five: 0b10110,
                seven: 0b0010101,
                nine: 0b1_1111_0101,
            ),
        )
    }

    // MARK: - Little Endian vs Big Endian Struct Comparison

    @ParseStruct(bitEndian: .big)
    struct BigEndianStructComparison: Equatable {
        @mask(bitCount: 3)
        var first: UInt8

        @mask(bitCount: 5)
        var second: UInt8
    }

    @ParseStruct(bitEndian: .little)
    struct LittleEndianStructComparison: Equatable {
        @mask(bitCount: 3)
        var first: UInt8

        @mask(bitCount: 5)
        var second: UInt8
    }

    @Test("Big vs Little endian struct - same data produces different values")
    func bigVsLittleEndianStructComparison() throws {
        // Input: 0b10110011
        let bigParsed = try BigEndianStructComparison(parsing: Data([0b1011_0011]))
        // Big endian (MSB first): first=bits[0-2]=0b101, second=bits[3-7]=0b10011
        #expect(
            bigParsed == .init(
                first: 0b101,
                second: 0b10011,
            ),
        )

        let littleParsed = try LittleEndianStructComparison(parsing: Data([0b1011_0011]))
        // Little endian (LSB first): first=bits[0-2]=0b011, second=bits[3-7]=0b10110
        #expect(
            littleParsed == .init(
                first: 0b011,
                second: 0b10110,
            ),
        )
    }

    // MARK: - Little Endian Multiple Parse Separators

    @ParseStruct(bitEndian: .little)
    struct LittleEndianMultipleParseSeparators: Equatable {
        @mask(bitCount: 3)
        var first: UInt8

        @mask(bitCount: 5)
        var second: UInt8

        @parse(endianness: .big)
        var sep1: UInt8

        @mask(bitCount: 4)
        var third: UInt8

        @mask(bitCount: 4)
        var fourth: UInt8

        @parse(endianness: .big)
        var sep2: UInt16

        @mask(bitCount: 2)
        var fifth: UInt8

        @mask(bitCount: 6)
        var sixth: UInt8
    }

    @Test("Little endian struct with multiple parse separators")
    func littleEndianMultipleParseSeparatorsParsing() throws {
        let parsed = try LittleEndianMultipleParseSeparators(parsing: Data([
            0b1101_0101, // mask group 1
            0xAA, // sep1
            0b1011_0011, // mask group 2
            0x12, 0x34, // sep2
            0b1110_0010, // mask group 3
        ]))
        #expect(
            parsed == .init(
                first: 0b101, // bits[0-2]
                second: 0b11010, // bits[3-7]
                sep1: 0xAA,
                third: 0b0011, // bits[0-3]
                fourth: 0b1011, // bits[4-7]
                sep2: 0x1234,
                fifth: 0b10, // bits[0-1]
                sixth: 0b111000, // bits[2-7]
            ),
        )
    }

    // MARK: - Little Endian with Skip

    @ParseStruct(bitEndian: .little)
    struct LittleEndianWithSkip: Equatable {
        @skip(byteCount: 2, because: "padding")
        @mask(bitCount: 4)
        var first: UInt8

        @mask(bitCount: 4)
        var second: UInt8
    }

    @Test("Little endian struct with skip before mask")
    func littleEndianWithSkipParsing() throws {
        let parsed = try LittleEndianWithSkip(parsing: Data([0xFF, 0xFF, 0b1011_0011]))
        // After skip, parse mask byte: bits[0-3]=0b0011, bits[4-7]=0b1011
        #expect(
            parsed == .init(
                first: 0b0011,
                second: 0b1011,
            ),
        )
    }

    // MARK: - Little Endian Maximum Values

    @ParseStruct(bitEndian: .little)
    struct LittleEndianMaxValues: Equatable {
        @mask(bitCount: 3)
        var three: UInt8

        @mask(bitCount: 6)
        var six: UInt8

        @mask(bitCount: 7)
        var seven: UInt8
    }

    @Test("Little endian struct maximum values")
    func littleEndianMaxValuesParsing() throws {
        // All ones
        let parsed = try LittleEndianMaxValues(parsing: Data([0b1111_1111, 0b1111_1111]))
        #expect(
            parsed == .init(
                three: 0b111,
                six: 0b111111,
                seven: 0b1111111,
            ),
        )
    }

    // MARK: - Little Endian All Zeros

    @Test("Little endian struct all zeros")
    func littleEndianAllZerosParsing() throws {
        let parsed = try LittleEndianMaxValues(parsing: Data([0x00, 0x00]))
        #expect(
            parsed == .init(
                three: 0b0,
                six: 0b0,
                seven: 0b0,
            ),
        )
    }
}
