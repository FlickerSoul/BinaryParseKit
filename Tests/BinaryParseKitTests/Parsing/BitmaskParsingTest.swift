//
//  BitmaskParsingTest.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 12/29/25.
//

import BinaryParseKit
import BinaryParsing
import Foundation
import Testing

extension ParsingTests { @Suite struct BitmaskParsingTest {} }

// MARK: - @ParseBitmask Integration Tests

extension ParsingTests.BitmaskParsingTest {
    // MARK: - Basic Bitmask Struct

    @ParseBitmask
    struct BasicFlags: Equatable {
        @mask(bitCount: 1)
        var flag1: UInt8

        @mask(bitCount: 3)
        var value: UInt8

        @mask(bitCount: 4)
        var nibble: UInt8
    }

    @Test("Basic bitmask struct parsing")
    func basicBitmaskParsing() throws {
        // Binary: 1 010 0011 = 0xA3
        let data = Data([0xA3])
        let flags = try data.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 8)
            return try BasicFlags(bits: rawBits)
        }
        #expect(flags == BasicFlags(flag1: 0b1, value: 0b010, nibble: 0b0011))
    }

    @Test("Basic bitmask struct - all zeros")
    func basicBitmaskAllZeros() throws {
        let data = Data([0x00])
        let flags = try data.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 8)
            return try BasicFlags(bits: rawBits)
        }
        #expect(flags == BasicFlags(flag1: 0b0, value: 0b000, nibble: 0b0000))
    }

    @Test("Basic bitmask struct - all ones")
    func basicBitmaskAllOnes() throws {
        // Binary: 1 111 1111 = 0xFF
        let data = Data([0xFF])
        let flags = try data.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 8)
            return try BasicFlags(bits: rawBits)
        }
        #expect(flags == BasicFlags(flag1: 0b1, value: 0b111, nibble: 0b1111))
    }

    @Test("BasicFlags bitCount is correct")
    func basicBitmaskBitCount() {
        #expect(BasicFlags.bitCount == 8)
    }

    // MARK: - Single Field Bitmask

    @ParseBitmask
    struct SingleFlag: Equatable {
        @mask(bitCount: 1)
        var flag: UInt8
    }

    @Test("Single field bitmask")
    func singleFieldBitmask() throws {
        let data1 = Data([0x80])
        let flag1 = try data1.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 1)
            return try SingleFlag(bits: rawBits)
        }
        #expect(flag1 == SingleFlag(flag: 0b1))

        let data0 = Data([0x00])
        let flag0 = try data0.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 1)
            return try SingleFlag(bits: rawBits)
        }
        #expect(flag0 == SingleFlag(flag: 0b0))
    }

    @Test("SingleFlag bitCount is correct")
    func singleFlagBitCount() {
        #expect(SingleFlag.bitCount == 1)
    }

    // MARK: - Multi-Byte Bitmask

    @ParseBitmask
    struct WideBitmask: Equatable {
        @mask(bitCount: 4)
        var high: UInt8

        @mask(bitCount: 8)
        var middle: UInt8

        @mask(bitCount: 4)
        var low: UInt8
    }

    @Test("Multi-byte bitmask spanning 2 bytes")
    func multiByteBitmask() throws {
        // Binary: 1010 10110011 0100
        // Bytes: [0xAB, 0x34] = 0xAB34
        let data = Data([0xAB, 0x34])
        let wide = try data.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 16)
            return try WideBitmask(bits: rawBits)
        }
        #expect(wide == WideBitmask(high: 0b1010, middle: 0b1011_0011, low: 0b0100))
    }

    @Test("WideBitmask bitCount is correct")
    func wideBitmaskBitCount() {
        #expect(WideBitmask.bitCount == 16)
    }

    // MARK: - Different Integer Types

    @ParseBitmask
    struct MixedIntegerTypes: Equatable {
        @mask(bitCount: 8)
        var byte: UInt8

        @mask(bitCount: 16)
        var word: UInt16

        @mask(bitCount: 8)
        var signed: Int8
    }

    @Test("Bitmask with different integer types")
    func mixedIntegerTypes() throws {
        // 0x12 | 0x3456 | 0x78 = 0x12345678
        let data = Data([0x12, 0x34, 0x56, 0x78])
        let mixed = try data.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 32)
            return try MixedIntegerTypes(bits: rawBits)
        }
        #expect(mixed == MixedIntegerTypes(byte: 0x12, word: 0x3456, signed: 0x78))
    }

    @Test("MixedIntegerTypes bitCount is correct")
    func mixedIntegerTypesBitCount() {
        #expect(MixedIntegerTypes.bitCount == 32)
    }

    // MARK: - Bitmask with Computed Properties (Ignored)

    @ParseBitmask
    struct BitmaskWithComputed: Equatable {
        @mask(bitCount: 4)
        var value: UInt8

        var computedDouble: Int {
            Int(value) * 2
        }

        var computedWithGetSet: Int {
            get { Int(value) }
            set { value = UInt8(newValue & 0x0F) }
        }
    }

    @Test("Computed properties are ignored in bitmask")
    func bitmaskIgnoresComputed() throws {
        // 1010 = 10, in MSB position: 0xA0
        let data = Data([0xA0])
        let bitmask = try data.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 4)
            return try BitmaskWithComputed(bits: rawBits)
        }
        #expect(bitmask == BitmaskWithComputed(value: 0b1010))
        #expect(bitmask.computedDouble == 20)
        #expect(bitmask.computedWithGetSet == 10)
    }

    @Test("BitmaskWithComputed bitCount only counts @mask fields")
    func bitmaskWithComputedBitCount() {
        #expect(BitmaskWithComputed.bitCount == 4)
    }

    // MARK: - Bitmask with Static Properties (Ignored)

    @ParseBitmask
    struct BitmaskWithStatic: Equatable {
        static let defaultValue: UInt8 = 0

        @mask(bitCount: 8)
        var value: UInt8
    }

    @Test("Static properties are ignored in bitmask")
    func bitmaskIgnoresStatic() throws {
        let data = Data([0x42])
        let bitmask = try data.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 8)
            return try BitmaskWithStatic(bits: rawBits)
        }
        #expect(bitmask == BitmaskWithStatic(value: 0x42))
        #expect(BitmaskWithStatic.defaultValue == 0)
    }

    @Test("BitmaskWithStatic bitCount only counts instance @mask fields")
    func bitmaskWithStaticBitCount() {
        #expect(BitmaskWithStatic.bitCount == 8)
    }

    // MARK: - Non-Byte-Aligned Bitmask

    @ParseBitmask
    struct NonByteAligned: Equatable {
        @mask(bitCount: 3)
        var first: UInt8

        @mask(bitCount: 5)
        var second: UInt8

        @mask(bitCount: 2)
        var third: UInt8
    }

    @Test("Non-byte-aligned bitmask (10 bits)")
    func nonByteAlignedBitmask() throws {
        // Binary: 101 01100 11 = 10 bits
        // As 16-bit integer (right-aligned in 10 bits): 0b10101100_11 = 0x2B3
        // But we need it MSB-aligned: 0xACC0 >> 6 = 0x2B3
        // Actually: 0xACC0 as full 16-bit, then shift
        // Let's calculate: 101 01100 11 in MSB position of 16 bits = 10101100_11000000 = 0xACC0
        // The init expects MSB-aligned input
        let data = Data([0xAC, 0xC0])
        let bitmask = try data.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 10)
            return try NonByteAligned(bits: rawBits)
        }
        #expect(bitmask == NonByteAligned(first: 0b101, second: 0b01100, third: 0b11))
    }

    @Test("NonByteAligned bitCount is correct")
    func nonByteAlignedBitCount() {
        #expect(NonByteAligned.bitCount == 10)
    }

    // MARK: - Large Value Bitmask

    @ParseBitmask
    struct LargeValueBitmask: Equatable {
        @mask(bitCount: 32)
        var large: UInt32
    }

    @Test("Large 32-bit bitmask value")
    func largeBitmaskValue() throws {
        let data = Data([0x12, 0x34, 0x56, 0x78])
        let bitmask = try data.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 32)
            return try LargeValueBitmask(bits: rawBits)
        }
        #expect(bitmask == LargeValueBitmask(large: 0x1234_5678))
    }

    @Test("LargeValueBitmask bitCount is correct")
    func largeValueBitmaskBitCount() {
        #expect(LargeValueBitmask.bitCount == 32)
    }

    // MARK: - Logic Tests (Insufficient & Excess Bits)

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

    @ParseBitmask
    struct InsufficientBitsStruct: Equatable {
        @mask(bitCount: 5)
        var field: ParsingTests.BitmaskParsingTest.Strict6Bit
    }

    @Test("Throws error when bitCount < Type.bitCount")
    func insufficientBits() {
        #expect(throws: BitmaskParsableError.insufficientBitsAvailable) {
            let data = Data([0xFF])
            try data.withParserSpan { parserSpan in
                let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 5)
                _ = try InsufficientBitsStruct(bits: rawBits)
            }
        }
    }

    @ParseBitmask
    struct SameBitCountBitsStruct: Equatable {
        @mask(bitCount: 6)
        var field: ParsingTests.BitmaskParsingTest.Strict6Bit
    }

    @Test("Exact bitCount equal to Type.bitCount")
    func sameBitCountBits() throws {
        let data = Data([0b1011_0101, 0b0000_0000])
        let parsed = try data.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 6)
            return try SameBitCountBitsStruct(bits: rawBits)
        }
        #expect(parsed == SameBitCountBitsStruct(field: Strict6Bit(value: 0b101101)))
    }

    @ParseBitmask
    struct SufficientBitsStruct: Equatable {
        @mask(bitCount: 7)
        var field: ParsingTests.BitmaskParsingTest.Strict6Bit
    }

    @Test("Exact bitCount equal to Type.bitCount")
    func sufficientBits() throws {
        let data = Data([0b1011_0101, 0b0000_0000])
        let parsed = try data.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 7)
            return try SufficientBitsStruct(bits: rawBits)
        }
        #expect(parsed == SufficientBitsStruct(field: Strict6Bit(value: 0b101101)))
    }

    @ParseBitmask
    struct ExcessBitsStruct: Equatable {
        @mask(bitCount: 15)
        var field: ParsingTests.BitmaskParsingTest.Strict6Bit
    }

    @Test("Takes MSB when bitCount > Type.bitCount")
    func excessBits() throws {
        let data = Data([0b1111_0000, 0b1111_0010])
        let parsed = try data.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 15)
            return try ExcessBitsStruct(bits: rawBits)
        }
        #expect(parsed == ExcessBitsStruct(field: Strict6Bit(value: 0b111100)))
    }
}

// MARK: - Little Endian (LSB) Bitmask Integration Tests

extension ParsingTests.BitmaskParsingTest {
    // MARK: - Basic Little Endian Bitmask

    /// Tests that @ParseBitmask(bitEndian: .little) compiles and parses successfully.
    @ParseBitmask(bitEndian: .little)
    struct LittleEndianBasicFlags: Equatable {
        @mask(bitCount: 1)
        var flag1: UInt8

        @mask(bitCount: 3)
        var value: UInt8

        @mask(bitCount: 4)
        var nibble: UInt8
    }

    @Test("Little endian basic bitmask parses without error")
    func littleEndianBasicParsing() throws {
        let data = Data([0b1010_0011])
        let flags = try data.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 8)
            return try LittleEndianBasicFlags(bits: rawBits)
        }
        // Verify parsing completed and values are within expected ranges
        #expect(
            flags == .init(
                flag1: 0b1,
                value: 0b001,
                nibble: 0b1010,
            ),
        )
    }

    @Test("Little endian basic bitmask - all zeros")
    func littleEndianBasicAllZeros() throws {
        let data = Data([0x00])
        let flags = try data.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 8)
            return try LittleEndianBasicFlags(bits: rawBits)
        }
        #expect(flags == .init(flag1: 0b0, value: 0b000, nibble: 0b0000))
    }

    @Test("Little endian basic bitmask - all ones")
    func littleEndianBasicAllOnes() throws {
        let data = Data([0xFF])
        let flags = try data.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 8)
            return try LittleEndianBasicFlags(bits: rawBits)
        }
        #expect(flags == .init(flag1: 0b1, value: 0b111, nibble: 0b1111))
    }

    @Test("LittleEndianBasicFlags bitCount is correct")
    func littleEndianBasicBitCount() {
        #expect(LittleEndianBasicFlags.bitCount == 8)
    }

    // MARK: - Little Endian Multi-Byte

    @ParseBitmask(bitEndian: .little)
    struct LittleEndianWideBitmask: Equatable {
        @mask(bitCount: 4)
        var low: UInt8

        @mask(bitCount: 8)
        var middle: UInt8

        @mask(bitCount: 4)
        var high: UInt8
    }

    @Test("Little endian multi-byte bitmask spanning 2 bytes")
    func littleEndianMultiByte() throws {
        let data = Data([0b1010_1011, 0b0011_0100])
        let wide = try data.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 16)
            return try LittleEndianWideBitmask(bits: rawBits)
        }

        // Verify parsing completed and values are within expected ranges
        #expect(LittleEndianWideBitmask.bitCount == 16)
        #expect(
            wide == .init(
                low: 0b0100,
                middle: 0b1011_0011,
                high: 0b1010,
            ),
        )
    }

    @ParseBitmask(bitEndian: .little)
    struct LittleEndianUnalignedWideBitmask: Equatable {
        @mask(bitCount: 2)
        var low: UInt8

        @mask(bitCount: 3)
        var middle: UInt8

        @mask(bitCount: 5)
        var high: UInt8
    }

    @Test("Little endian multi-byte bitmask spanning 2 bytes")
    func littleEndianUnalignedMultiByte() throws {
        // Input: 0b10101011 0b00110101 (16 bits, but only 10 used)
        // Fields: low(2) + middle(3) + high(5) = 10 bits
        // LSB mode slicing(last:) extracts from END of the 10-bit range:
        // Actual values: low=1, middle=5, high=25
        let data = Data([0b1010_1011, 0b0011_0101])
        let wide = try data.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 16)
            return try LittleEndianUnalignedWideBitmask(bits: rawBits)
        }
        #expect(LittleEndianUnalignedWideBitmask.bitCount == 10)
        #expect(
            wide == .init(
                low: 0b01,
                middle: 0b101,
                high: 0b11001,
            ),
        )
    }

    // MARK: - Little Endian Single Bit Field

    @ParseBitmask(bitEndian: .little)
    struct LittleEndianSingleBitBitmask: Equatable {
        @mask(bitCount: 1)
        var flag: UInt8
    }

    @Test("Little endian single bit - LSB is 1")
    func littleEndianSingleBitOne() throws {
        let data = Data([0b0000_0001])
        let parsed = try data.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 8)
            return try LittleEndianSingleBitBitmask(bits: rawBits)
        }
        #expect(parsed == .init(flag: 0b1))
    }

    @Test("Little endian single bit - LSB is 0")
    func littleEndianSingleBitZero() throws {
        let data = Data([0b1000_0000])
        let parsed = try data.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 8)
            return try LittleEndianSingleBitBitmask(bits: rawBits)
        }
        #expect(parsed == .init(flag: 0b0))
    }

    // MARK: - Little Endian 3 Bytes Crossing

    @ParseBitmask(bitEndian: .little)
    struct LittleEndianThreeByteBitmask: Equatable {
        @mask(bitCount: 5)
        var first: UInt8

        @mask(bitCount: 10)
        var second: UInt16

        @mask(bitCount: 9)
        var third: UInt16
    }

    @Test("Little endian bitmask spanning 3 bytes")
    func littleEndianThreeByteCrossing() throws {
        let data = Data([0b1101_0101, 0b1011_0011, 0b1111_0000])
        let parsed = try data.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 24)
            return try LittleEndianThreeByteBitmask(bits: rawBits)
        }
        #expect(LittleEndianThreeByteBitmask.bitCount == 24)
        #expect(
            parsed == .init(
                first: 0b10000,
                second: 0b01_1001_1111,
                third: 0b1_1010_1011,
            ),
        )
    }

    // MARK: - Little Endian Different Integer Types

    @ParseBitmask(bitEndian: .little)
    struct LittleEndianMixedTypes: Equatable {
        @mask(bitCount: 4)
        var small: UInt8

        @mask(bitCount: 12)
        var medium: UInt16

        @mask(bitCount: 16)
        var large: UInt16
    }

    @Test("Little endian bitmask with mixed integer types")
    func littleEndianMixedTypes() throws {
        let data = Data([0b1010_1111, 0b1100_1100, 0b0011_0011, 0b1111_0000])
        let parsed = try data.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 32)
            return try LittleEndianMixedTypes(bits: rawBits)
        }
        #expect(LittleEndianMixedTypes.bitCount == 32)
        #expect(
            parsed == .init(
                small: 0b0000,
                medium: 0b0011_0011_1111,
                large: 0b1010_1111_1100_1100,
            ),
        )
    }

    // MARK: - Little Endian Alternating Pattern

    @ParseBitmask(bitEndian: .little)
    struct LittleEndianAlternatingBitmask: Equatable {
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

    @Test("Little endian single bit fields extract in LSB order")
    func littleEndianAlternatingPattern() throws {
        // Input: 0b10101010
        let data = Data([0b1010_1010])
        let parsed = try data.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 8)
            return try LittleEndianAlternatingBitmask(bits: rawBits)
        }
        // LSB order: b0=bit0, b1=bit1, ..., b7=bit7
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

    @ParseBitmask(bitEndian: .little)
    struct LittleEndianNonPowerOfTwoBitmask: Equatable {
        @mask(bitCount: 3)
        var three: UInt8

        @mask(bitCount: 5)
        var five: UInt8

        @mask(bitCount: 7)
        var seven: UInt8

        @mask(bitCount: 9)
        var nine: UInt16
    }

    @Test("Little endian bitmask with non-power-of-two field sizes")
    func littleEndianNonPowerOfTwo() throws {
        // Input: 0b11111010 0b10010101 0b10110011
        // Fields: three(3) + five(5) + seven(7) + nine(9) = 24 bits
        // LSB mode slicing(last:) extracts from END:
        // Actual values: three=3, five=22, seven=21, nine=501
        let data = Data([0b1111_1010, 0b1001_0101, 0b1011_0011])
        let parsed = try data.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 24)
            return try LittleEndianNonPowerOfTwoBitmask(bits: rawBits)
        }
        #expect(LittleEndianNonPowerOfTwoBitmask.bitCount == 24)
        #expect(
            parsed == .init(
                three: 0b011,
                five: 0b10110,
                seven: 0b0010101,
                nine: 0b1_1111_0101,
            ),
        )
    }

    // MARK: - Little Endian vs Big Endian Comparison

    @ParseBitmask(bitEndian: .big)
    struct BigEndianComparisonBitmask: Equatable {
        @mask(bitCount: 3)
        var first: UInt8

        @mask(bitCount: 5)
        var second: UInt8
    }

    @ParseBitmask(bitEndian: .little)
    struct LittleEndianComparisonBitmask: Equatable {
        @mask(bitCount: 3)
        var first: UInt8

        @mask(bitCount: 5)
        var second: UInt8
    }

    @Test("Big vs Little endian - same data produces different values")
    func bigVsLittleEndianComparison() throws {
        // Input: 0b10110011
        let data = Data([0b1011_0011])

        let bigParsed = try data.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 8)
            return try BigEndianComparisonBitmask(bits: rawBits)
        }
        // Big endian (MSB first): first=bits[0-2]=0b101, second=bits[3-7]=0b10011
        #expect(
            bigParsed == .init(
                first: 0b101,
                second: 0b10011,
            ),
        )

        let littleParsed = try data.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 8)
            return try LittleEndianComparisonBitmask(bits: rawBits)
        }
        // Little endian (LSB first): first=bits[0-2]=0b011, second=bits[3-7]=0b10110
        #expect(
            littleParsed == .init(
                first: 0b011,
                second: 0b10110,
            ),
        )
    }

    // MARK: - Little Endian with Maximum Values

    @ParseBitmask(bitEndian: .little)
    struct LittleEndianMaxValuesBitmask: Equatable {
        @mask(bitCount: 3)
        var three: UInt8

        @mask(bitCount: 6)
        var six: UInt8

        @mask(bitCount: 7)
        var seven: UInt8
    }

    @Test("Little endian bitmask maximum values")
    func littleEndianMaxValues() throws {
        // All ones: 0b11111111 0b11111111
        let data = Data([0b1111_1111, 0b1111_1111])
        let parsed = try data.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 16)
            return try LittleEndianMaxValuesBitmask(bits: rawBits)
        }
        #expect(
            parsed == .init(
                three: 0b111,
                six: 0b111111,
                seven: 0b1111111,
            ),
        )
    }
}
