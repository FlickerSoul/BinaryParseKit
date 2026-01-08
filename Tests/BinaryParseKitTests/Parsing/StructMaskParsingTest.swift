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
        static var bitCount: Int { 1 }
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
        static var bitCount: Int { 4 }
        let value: UInt8

        init(value: UInt8) {
            precondition(value <= 0x0F, "Nibble value must be 0-15")
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
        static var bitCount: Int { 3 }
        let value: UInt8

        init(value: UInt8) {
            precondition(value <= 0x07, "ThreeBit value must be 0-7")
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
    struct BasicBitmaskExplicit {
        @mask(bitCount: 1)
        var flag1: UInt8

        @mask(bitCount: 3)
        var value: UInt8

        @mask(bitCount: 4)
        var nibble: UInt8
    }

    @Test("Basic bitmask parsing with explicit bit counts - all bits from single byte")
    func basicBitmaskExplicitParsing() throws {
        // Binary: 1 010 0011 = 0xA3
        // flag1 = 1 (bit 0) -> 1
        // value = 010 (bits 1-3) -> 2
        // nibble = 0011 (bits 4-7) -> 3
        let parsed = try BasicBitmaskExplicit(parsing: Data([0xA3]))
        #expect(parsed.flag1 == 1)
        #expect(parsed.value == 2)
        #expect(parsed.nibble == 3)
    }

    @Test("Basic bitmask parsing - all zeros")
    func basicBitmaskExplicitAllZeros() throws {
        let parsed = try BasicBitmaskExplicit(parsing: Data([0x00]))
        #expect(parsed.flag1 == 0)
        #expect(parsed.value == 0)
        #expect(parsed.nibble == 0)
    }

    @Test("Basic bitmask parsing - all ones")
    func basicBitmaskExplicitAllOnes() throws {
        // Binary: 1 111 1111 = 0xFF
        let parsed = try BasicBitmaskExplicit(parsing: Data([0xFF]))
        #expect(parsed.flag1 == 1)
        #expect(parsed.value == 7) // 0b111 = 7
        #expect(parsed.nibble == 15) // 0b1111 = 15
    }

    // MARK: - Inferred Bit Count with Custom Types

    @ParseStruct
    struct BitmaskInferred {
        @mask
        var flag1: ParsingTests.StructMaskParsingTest.Flag

        @mask
        var flag2: ParsingTests.StructMaskParsingTest.Flag

        @mask(bitCount: 6)
        var value: UInt8
    }

    @Test("Inferred bitCount from BitmaskParsable type")
    func inferredBitmaskParsing() throws {
        // Binary: 1 0 000101 = 0x85
        // flag1 = 1 (bit 0) -> Flag(true)
        // flag2 = 0 (bit 1) -> Flag(false)
        // value = 000101 (bits 2-7) -> 5
        let parsed = try BitmaskInferred(parsing: Data([0x85]))
        #expect(parsed.flag1 == Flag(value: true))
        #expect(parsed.flag2 == Flag(value: false))
        #expect(parsed.value == 5)
    }

    @ParseStruct
    struct BitmaskAllInferred {
        @mask
        var first: ParsingTests.StructMaskParsingTest.Flag

        @mask
        var second: ParsingTests.StructMaskParsingTest.Nibble

        @mask
        var third: ParsingTests.StructMaskParsingTest.ThreeBit
    }

    @Test("All fields with inferred bit counts")
    func allInferredBitmaskParsing() throws {
        // Binary: 1 1010 011 = 0xD3
        // first = 1 -> Flag(true)
        // second = 1010 -> Nibble(10)
        // third = 011 -> ThreeBit(3)
        let parsed = try BitmaskAllInferred(parsing: Data([0xD3]))
        #expect(parsed.first == Flag(value: true))
        #expect(parsed.second == Nibble(value: 10))
        #expect(parsed.third == ThreeBit(value: 3))
    }

    // MARK: - Multi-Byte Bitmask

    @ParseStruct
    struct MultiBytesBitmask {
        @mask(bitCount: 4)
        var high: UInt8

        @mask(bitCount: 8)
        var middle: UInt8

        @mask(bitCount: 4)
        var low: UInt8
    }

    @Test("Multi-byte bitmask spanning 2 bytes")
    func multiBytesBitmaskParsing() throws {
        // Binary: 1010 10110011 0100
        // Bytes: [0xAB, 0x34]
        // high = 1010 (bits 0-3) -> 10
        // middle = 10110011 (bits 4-11) -> 0xB3 = 179
        // low = 0100 (bits 12-15) -> 4
        let parsed = try MultiBytesBitmask(parsing: Data([0xAB, 0x34]))
        #expect(parsed.high == 10) // 0b1010
        #expect(parsed.middle == 179) // 0b10110011
        #expect(parsed.low == 4) // 0b0100
    }

    // MARK: - Mixed Parse and Mask

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

    @Test("Mixed @parse and @mask fields")
    func mixedParseMaskParsing() throws {
        // header = 0x42
        // Binary for mask byte: 1 0110100 = 0xB4
        // flag = 1
        // value = 0110100 = 52
        // footer = 0x1234
        let parsed = try MixedParseMask(parsing: Data([0x42, 0xB4, 0x12, 0x34]))
        #expect(parsed.header == 0x42)
        #expect(parsed.flag == 1)
        #expect(parsed.value == 52)
        #expect(parsed.footer == 0x1234)
    }

    // MARK: - Multiple Mask Groups

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

    @Test("Multiple separate mask groups")
    func multipleMaskGroupsParsing() throws {
        // First group: 1010 0101 = 0xA5 -> first=10, second=5
        // Separator: 0xFF
        // Second group: 11 010110 = 0xD6 -> third=3, fourth=22
        let parsed = try MultipleMaskGroups(parsing: Data([0xA5, 0xFF, 0xD6]))
        #expect(parsed.first == 10)
        #expect(parsed.second == 5)
        #expect(parsed.separator == 0xFF)
        #expect(parsed.third == 3)
        #expect(parsed.fourth == 22)
    }

    // MARK: - Error Cases

    @ParseStruct
    struct MaskWithInsufficientData {
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
    struct SkipWithMask {
        @skip(byteCount: 2, because: "header padding")
        @mask(bitCount: 4)
        var value: UInt8

        @mask(bitCount: 4)
        var flags: UInt8
    }

    @Test("Skip before mask fields")
    func skipBeforeMaskParsing() throws {
        // Skip 2 bytes, then parse mask byte: 1100 0011 = 0xC3
        let parsed = try SkipWithMask(parsing: Data([0xFF, 0xFF, 0xC3]))
        #expect(parsed.value == 12) // 0b1100
        #expect(parsed.flags == 3) // 0b0011
    }

    // MARK: - Logic Tests (Insufficient & Excess Bits)

    /// A type with bitCount = 6 and RawBitsInteger = UInt8 for testing bit count logic.
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

    @ParseStruct
    struct InsufficientBitsStruct {
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
    struct SameBitCountStruct {
        @mask(bitCount: 6)
        var field: ParsingTests.StructMaskParsingTest.Strict6Bit
    }

    @Test("Exact bitCount equal to Type.bitCount")
    func sameBitCountBits() throws {
        // Input: 1011_0100 (first 6 bits: 101101 = 45)
        let parsed = try SameBitCountStruct(parsing: Data([0b1011_0100]))
        #expect(parsed.field.value == 0b101101)
    }

    @ParseStruct
    struct SufficientBitsStruct {
        @mask(bitCount: 7)
        var field: ParsingTests.StructMaskParsingTest.Strict6Bit
    }

    @Test("Takes MSB when bitCount > Type.bitCount (7 > 6)")
    func sufficientBits() throws {
        // Input: 1011_0101 (first 7 bits: 1011010 = 90)
        // Take MSB 6 bits: 101101 = 45
        let parsed = try SufficientBitsStruct(parsing: Data([0b1011_0101]))
        #expect(parsed.field.value == 0b101101)
    }

    @ParseStruct
    struct ExcessBitsStruct {
        @mask(bitCount: 15)
        var field: ParsingTests.StructMaskParsingTest.Strict6Bit
    }

    @Test("Takes MSB when bitCount > Type.bitCount (15 > 6)")
    func excessBits() throws {
        // Input: 0b1111_0000_1111_0010 (15 bits: 111100001111001)
        // Take MSB 6 bits: 111100 = 60
        let parsed = try ExcessBitsStruct(parsing: Data([0b1111_0000, 0b1111_0010]))
        #expect(parsed.field.value == 0b111100)
    }
}
