//
//  TestBitmaskParsing.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 12/29/25.
//

import BinaryParseKit
import BinaryParsing
import Foundation
import Testing

// MARK: - @ParseBitmask Integration Tests

@Suite
struct BitmaskParsingTest {
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
        let bits = RawBits(data: Data([0xA3]), size: 8)
        let flags = try BasicFlags(bits: bits)
        #expect(flags.flag1 == 1)
        #expect(flags.value == 2)
        #expect(flags.nibble == 3)
    }

    @Test("Basic bitmask struct - all zeros")
    func basicBitmaskAllZeros() throws {
        let bits = RawBits(data: Data([0x00]), size: 8)
        let flags = try BasicFlags(bits: bits)
        #expect(flags.flag1 == 0)
        #expect(flags.value == 0)
        #expect(flags.nibble == 0)
    }

    @Test("Basic bitmask struct - all ones")
    func basicBitmaskAllOnes() throws {
        let bits = RawBits(data: Data([0xFF]), size: 8)
        let flags = try BasicFlags(bits: bits)
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
        let bits1 = RawBits(data: Data([0x80]), size: 1)
        let flag1 = try SingleFlag(bits: bits1)
        #expect(flag1.flag == 1)

        let bits0 = RawBits(data: Data([0x00]), size: 1)
        let flag0 = try SingleFlag(bits: bits0)
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
        // Bytes: [0xAB, 0x34]
        let bits = RawBits(data: Data([0xAB, 0x34]), size: 16)
        let wide = try WideBitmask(bits: bits)
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
        // 0x12 | 0x3456 | 0x78
        // Binary: 00010010 0011010001010110 01111000
        let bits = RawBits(data: Data([0x12, 0x34, 0x56, 0x78]), size: 32)
        let mixed = try MixedIntegerTypes(bits: bits)
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
        let bits = RawBits(data: Data([0xA0]), size: 4) // 1010 = 10
        let bitmask = try BitmaskWithComputed(bits: bits)
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
        let bits = RawBits(data: Data([0x42]), size: 8)
        let bitmask = try BitmaskWithStatic(bits: bits)
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
        // Byte representation: 10101100 11000000 = 0xAC 0xC0
        let bits = RawBits(data: Data([0xAC, 0xC0]), size: 10)
        let bitmask = try NonByteAligned(bits: bits)
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
        let bits = RawBits(data: Data([0x12, 0x34, 0x56, 0x78]), size: 32)
        let bitmask = try LargeValueBitmask(bits: bits)
        #expect(bitmask.large == 0x1234_5678)
    }

    @Test("LargeValueBitmask bitCount is correct")
    func largeValueBitmaskBitCount() {
        #expect(LargeValueBitmask.bitCount == 32)
    }
}

// MARK: - @ParseBitmask Usage in @ParseStruct

@Suite
struct BitmaskInStructTest {
    @ParseBitmask
    struct PacketFlags: Equatable {
        @mask(bitCount: 1)
        var isCompressed: UInt8

        @mask(bitCount: 1)
        var isEncrypted: UInt8

        @mask(bitCount: 2)
        var priority: UInt8

        @mask(bitCount: 4)
        var version: UInt8
    }

    @ParseStruct
    struct PacketHeader {
        @parse(endianness: .big)
        var length: UInt16

        @mask
        var flags: BitmaskInStructTest.PacketFlags

        @parse(endianness: .big)
        var sequenceNumber: UInt32
    }

    @Test("Bitmask struct used as field in ParseStruct")
    func bitmaskInParseStruct() throws {
        // length = 0x0100 = 256
        // flags = 1 1 10 0011 = 0xE3 (compressed=1, encrypted=1, priority=2, version=3)
        // sequenceNumber = 0x12345678
        let parsed = try PacketHeader(parsing: Data([
            0x01, 0x00, // length (BE)
            0xE3, // flags
            0x12, 0x34, 0x56, 0x78, // sequenceNumber (BE)
        ]))

        #expect(parsed.length == 256)
        #expect(parsed.flags.isCompressed == 1)
        #expect(parsed.flags.isEncrypted == 1)
        #expect(parsed.flags.priority == 2)
        #expect(parsed.flags.version == 3)
        #expect(parsed.sequenceNumber == 0x1234_5678)
    }

    @Test("PacketFlags bitCount is correct")
    func packetFlagsBitCount() {
        #expect(PacketFlags.bitCount == 8)
    }
}
