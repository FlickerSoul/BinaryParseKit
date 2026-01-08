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
    struct BasicFlags {
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
        #expect(flags.flag1 == 1)
        #expect(flags.value == 2)
        #expect(flags.nibble == 3)
    }

    @Test("Basic bitmask struct - all zeros")
    func basicBitmaskAllZeros() throws {
        let data = Data([0x00])
        let flags = try data.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 8)
            return try BasicFlags(bits: rawBits)
        }
        #expect(flags.flag1 == 0)
        #expect(flags.value == 0)
        #expect(flags.nibble == 0)
    }

    @Test("Basic bitmask struct - all ones")
    func basicBitmaskAllOnes() throws {
        // Binary: 1 111 1111 = 0xFF
        let data = Data([0xFF])
        let flags = try data.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 8)
            return try BasicFlags(bits: rawBits)
        }
        #expect(flags.flag1 == 1)
        #expect(flags.value == 7)
        #expect(flags.nibble == 15)
    }

    @Test("BasicFlags bitCount is correct")
    func basicBitmaskBitCount() {
        #expect(BasicFlags.bitCount == 8)
    }

    // MARK: - Single Field Bitmask

    @ParseBitmask
    struct SingleFlag {
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
        #expect(flag1.flag == 1)

        let data0 = Data([0x00])
        let flag0 = try data0.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 1)
            return try SingleFlag(bits: rawBits)
        }
        #expect(flag0.flag == 0)
    }

    @Test("SingleFlag bitCount is correct")
    func singleFlagBitCount() {
        #expect(SingleFlag.bitCount == 1)
    }

    // MARK: - Multi-Byte Bitmask

    @ParseBitmask
    struct WideBitmask {
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
        #expect(wide.high == 10) // 0b1010
        #expect(wide.middle == 179) // 0b10110011
        #expect(wide.low == 4) // 0b0100
    }

    @Test("WideBitmask bitCount is correct")
    func wideBitmaskBitCount() {
        #expect(WideBitmask.bitCount == 16)
    }

    // MARK: - Different Integer Types

    @ParseBitmask
    struct MixedIntegerTypes {
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
        #expect(mixed.byte == 0x12)
        #expect(mixed.word == 0x3456)
        #expect(mixed.signed == 0x78)
    }

    @Test("MixedIntegerTypes bitCount is correct")
    func mixedIntegerTypesBitCount() {
        #expect(MixedIntegerTypes.bitCount == 32)
    }

    // MARK: - Bitmask with Computed Properties (Ignored)

    @ParseBitmask
    struct BitmaskWithComputed {
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
        #expect(bitmask.value == 10)
        #expect(bitmask.computedDouble == 20)
        #expect(bitmask.computedWithGetSet == 10)
    }

    @Test("BitmaskWithComputed bitCount only counts @mask fields")
    func bitmaskWithComputedBitCount() {
        #expect(BitmaskWithComputed.bitCount == 4)
    }

    // MARK: - Bitmask with Static Properties (Ignored)

    @ParseBitmask
    struct BitmaskWithStatic {
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
        #expect(bitmask.value == 0x42)
        #expect(BitmaskWithStatic.defaultValue == 0)
    }

    @Test("BitmaskWithStatic bitCount only counts instance @mask fields")
    func bitmaskWithStaticBitCount() {
        #expect(BitmaskWithStatic.bitCount == 8)
    }

    // MARK: - Non-Byte-Aligned Bitmask

    @ParseBitmask
    struct NonByteAligned {
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
        #expect(bitmask.first == 5) // 0b101
        #expect(bitmask.second == 12) // 0b01100
        #expect(bitmask.third == 3) // 0b11
    }

    @Test("NonByteAligned bitCount is correct")
    func nonByteAlignedBitCount() {
        #expect(NonByteAligned.bitCount == 10)
    }

    // MARK: - Large Value Bitmask

    @ParseBitmask
    struct LargeValueBitmask {
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
        #expect(bitmask.large == 0x1234_5678)
    }

    @Test("LargeValueBitmask bitCount is correct")
    func largeValueBitmaskBitCount() {
        #expect(LargeValueBitmask.bitCount == 32)
    }

    // MARK: - Logic Tests (Insufficient & Excess Bits)

    struct Strict6Bit: ExpressibleByRawBits, BitCountProviding, RawBitsConvertible, Equatable {
        static let bitCount = 6
        let value: UInt8

        init(bits: borrowing RawBitsSpan) throws {
            value = try bits.load()
        }

        func toRawBits(bitCount: Int) throws -> RawBits {
            try value.toRawBits(bitCount: bitCount)
        }
    }

    @ParseBitmask
    struct InsufficientBitsStruct {
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
    struct SameBitCountBitsStruct {
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
        #expect(parsed.field.value == 0b101101)
    }

    @ParseBitmask
    struct SufficientBitsStruct {
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
        #expect(parsed.field.value == 0b101101)
    }

    @ParseBitmask
    struct ExcessBitsStruct {
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
        #expect(parsed.field.value == 0b111100)
    }
}
