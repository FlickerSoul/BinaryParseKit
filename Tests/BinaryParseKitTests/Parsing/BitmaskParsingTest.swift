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
        typealias RawBitsInteger = UInt8

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
        let flags = try BasicFlags(bits: 0xA3)
        #expect(flags.flag1 == 1)
        #expect(flags.value == 2)
        #expect(flags.nibble == 3)
    }

    @Test("Basic bitmask struct - all zeros")
    func basicBitmaskAllZeros() throws {
        let flags = try BasicFlags(bits: 0x00)
        #expect(flags.flag1 == 0)
        #expect(flags.value == 0)
        #expect(flags.nibble == 0)
    }

    @Test("Basic bitmask struct - all ones")
    func basicBitmaskAllOnes() throws {
        let flags = try BasicFlags(bits: 0xFF)
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
        typealias RawBitsInteger = UInt8

        @mask(bitCount: 1)
        var flag: UInt8
    }

    @Test("Single field bitmask")
    func singleFieldBitmask() throws {
        let flag1 = try SingleFlag(bits: 0x80)
        #expect(flag1.flag == 1)

        let flag0 = try SingleFlag(bits: 0x00)
        #expect(flag0.flag == 0)
    }

    @Test("SingleFlag bitCount is correct")
    func singleFlagBitCount() {
        #expect(SingleFlag.bitCount == 1)
    }

    // MARK: - Multi-Byte Bitmask

    @ParseBitmask
    struct WideBitmask {
        typealias RawBitsInteger = UInt16

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
        let wide = try WideBitmask(bits: 0xAB34)
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
        typealias RawBitsInteger = UInt32

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
        let mixed = try MixedIntegerTypes(bits: 0x1234_5678)
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
        typealias RawBitsInteger = UInt8

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
        let bitmask = try BitmaskWithComputed(bits: 0xA0)
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
        typealias RawBitsInteger = UInt8

        static let defaultValue: UInt8 = 0

        @mask(bitCount: 8)
        var value: UInt8
    }

    @Test("Static properties are ignored in bitmask")
    func bitmaskIgnoresStatic() throws {
        let bitmask = try BitmaskWithStatic(bits: 0x42)
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
        typealias RawBitsInteger = UInt16

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
        let bitmask = try NonByteAligned(bits: 0xACC0)
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
        typealias RawBitsInteger = UInt32

        @mask(bitCount: 32)
        var large: UInt32
    }

    @Test("Large 32-bit bitmask value")
    func largeBitmaskValue() throws {
        let bitmask = try LargeValueBitmask(bits: 0x1234_5678)
        #expect(bitmask.large == 0x1234_5678)
    }

    @Test("LargeValueBitmask bitCount is correct")
    func largeValueBitmaskBitCount() {
        #expect(LargeValueBitmask.bitCount == 32)
    }

    // MARK: - Logic Tests (Insufficient & Excess Bits)

    struct Strict6Bit: ExpressibleByRawBits, BitCountProviding, RawBitsConvertible, Equatable {
        typealias RawBitsInteger = UInt8
        static let bitCount = 6
        let value: UInt8

        init(bits: UInt8) {
            value = bits
        }

        func toRawBits(bitCount: Int) throws -> RawBits {
            try value.toRawBits(bitCount: bitCount)
        }
    }

    @ParseBitmask
    struct InsufficientBitsStruct {
        typealias RawBitsInteger = UInt8
        @mask(bitCount: 5)
        var field: ParsingTests.BitmaskParsingTest.Strict6Bit
    }

    @Test("Throws error when bitCount < Type.bitCount")
    func insufficientBits() {
        #expect(throws: BitmaskParsableError.insufficientBitsAvailable) {
            try InsufficientBitsStruct(bits: 0xFF)
        }
    }

    @ParseBitmask
    struct SameBitCountBitsStruct {
        typealias RawBitsInteger = UInt16
        @mask(bitCount: 6)
        var field: ParsingTests.BitmaskParsingTest.Strict6Bit
    }

    @Test("Exact bitCount equal to Type.bitCount")
    func sameBitCountBits() throws {
        let input: UInt16 = 0b1011_0101_0000_0000
        let parsed = try SameBitCountBitsStruct(bits: input)
        #expect(parsed.field.value == 0b101101)
    }

    @ParseBitmask
    struct SufficientBitsStruct {
        typealias RawBitsInteger = UInt16
        @mask(bitCount: 7)
        var field: ParsingTests.BitmaskParsingTest.Strict6Bit
    }

    @Test("Exact bitCount equal to Type.bitCount")
    func sufficientBits() throws {
        let input: UInt16 = 0b1011_0101_0000_0000
        let parsed = try SufficientBitsStruct(bits: input)
        #expect(parsed.field.value == 0b101101)
    }

    @ParseBitmask
    struct ExcessBitsStruct {
        typealias RawBitsInteger = UInt16
        @mask(bitCount: 15)
        var field: ParsingTests.BitmaskParsingTest.Strict6Bit
    }

    @Test("Takes MSB when bitCount > Type.bitCount")
    func excessBits() throws {
        let input: UInt16 = 0b1111_0000_1111_0010
        let parsed = try ExcessBitsStruct(bits: input)
        #expect(parsed.field.value == 0b111100)
    }
}
