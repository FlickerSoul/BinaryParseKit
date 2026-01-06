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
        // First 12 bits: 1010 1011 0011 = 0xAB3 = 2739 (right-aligned)
        // Last 4 bits: 0100 = 4
        let result = try MultiByteMask(parsing: Data([0x01, 0b1010_1011, 0b0011_0100]))
        #expect(result == .wide(0b1010_1011_0011, 0b0100))
    }
}
