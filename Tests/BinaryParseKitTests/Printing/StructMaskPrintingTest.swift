//
//  StructMaskPrintingTest.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 7/17/25.
//

import BinaryParseKit
import BinaryParsing
import Foundation
import Testing

extension PrintingTests { @Suite struct StructMaskPrintingTest {} }

// MARK: - @ParseStruct Mask Printing Integration Tests

extension PrintingTests.StructMaskPrintingTest {
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
        // 20 bits: 0001 0010 0011 0100 0101 -> large=0x12345 (right-aligned)
        // 12 bits: 0110 0111 1000 -> medium=0x678 (right-aligned)
        // Combined 32 bits: 00010010 00110100 01010110 01111000 = 0x12345678
        let originalData = Data([0x12, 0x34, 0x56, 0x78])
        let parsed = try LargeMaskFields(parsing: originalData)
        #expect(parsed == LargeMaskFields(large: 0x12345, medium: 0x678))
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
