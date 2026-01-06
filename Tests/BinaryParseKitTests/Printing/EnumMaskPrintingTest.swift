//
//  EnumMaskPrintingTest.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/8/25.
//

import BinaryParseKit
import BinaryParsing
import Foundation
import Testing

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
