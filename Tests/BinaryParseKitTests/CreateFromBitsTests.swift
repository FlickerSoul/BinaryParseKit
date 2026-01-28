//
//  CreateFromBitsTests.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 1/7/26.
//

@testable import BinaryParseKit
import Foundation
import Testing

@Suite("__createFromBits Tests")
struct CreateFromBitsTests {
    // MARK: - Test Types

    /// Type with BitCountProviding, requires exactly 6 bits
    struct Strict6Bit: ExpressibleByRawBits, BitCountProviding, Equatable {
        static let bitCount = 6
        let value: UInt8

        init(bits: borrowing RawBitsSpan) throws {
            value = try bits.load(as: UInt8.self)
        }
    }

    /// Type with BitCountProviding, requires exactly 4 bits
    struct Strict4Bit: ExpressibleByRawBits, BitCountProviding, Equatable {
        static let bitCount = 4
        let value: UInt8

        init(bits: borrowing RawBitsSpan) throws {
            value = try bits.load(as: UInt8.self)
        }
    }

    /// Type with BitCountProviding, requires exactly 1 bit
    struct Strict1Bit: ExpressibleByRawBits, BitCountProviding, Equatable {
        static let bitCount = 1
        let value: UInt8

        init(bits: borrowing RawBitsSpan) throws {
            let intValue: UInt8 = try bits.load()
            value = (intValue & 1)
        }
    }

    /// Type WITHOUT BitCountProviding - should always pass through
    struct Flexible8Bit: ExpressibleByRawBits, Equatable {
        let value: UInt8

        init(bits: borrowing RawBitsSpan) throws {
            value = try bits.load(as: UInt8.self)
        }
    }

    /// Type with BitCountProviding using UInt16 as RawBitsInteger
    struct Strict12Bit: ExpressibleByRawBits, BitCountProviding, Equatable {
        static let bitCount = 12
        let value: UInt16

        init(bits: borrowing RawBitsSpan) throws {
            value = try bits.load(as: UInt16.self)
        }
    }

    // MARK: - Insufficient bits (fieldBitCount < Type.bitCount)

    @Test("Throws insufficientBitsAvailable when fieldBitCount < typeBitCount (5 < 6)")
    func throwsWhenInsufficientBits5vs6() {
        #expect(throws: BitmaskParsableError.insufficientBitsAvailable) {
            let bitsInteger: UInt8 = 0b11111
            _ = try bitsInteger.withParserSpan { parserSpan in
                let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 5)
                return try __createFromBits(Strict6Bit.self, fieldBits: rawBits, fieldRequestedBitCount: 5)
            }
        }
    }

    @Test("Throws insufficientBitsAvailable when fieldBitCount < typeBitCount (3 < 4)")
    func throwsWhenInsufficientBits3vs4() {
        #expect(throws: BitmaskParsableError.insufficientBitsAvailable) {
            let bitsInteger: UInt8 = 0b111
            _ = try bitsInteger.withParserSpan { parserSpan in
                let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 3)
                return try __createFromBits(Strict4Bit.self, fieldBits: rawBits, fieldRequestedBitCount: 3)
            }
        }
    }

    @Test("Throws insufficientBitsAvailable when fieldBitCount < typeBitCount (0 < 1)")
    func throwsWhenInsufficientBits0vs1() {
        #expect(throws: BitmaskParsableError.insufficientBitsAvailable) {
            let bitsInteger: UInt8 = 0
            _ = try bitsInteger.withParserSpan { parserSpan in
                let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 0)
                return try __createFromBits(Strict1Bit.self, fieldBits: rawBits, fieldRequestedBitCount: 0)
            }
        }
    }

    @Test("Throws insufficientBitsAvailable when fieldBitCount < typeBitCount (11 < 12)")
    func throwsWhenInsufficientBits11vs12() {
        #expect(throws: BitmaskParsableError.insufficientBitsAvailable) {
            let bitsInteger: UInt16 = 0x7FF
            _ = try bitsInteger.withParserSpan { parserSpan in
                let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 11)
                return try __createFromBits(Strict12Bit.self, fieldBits: rawBits, fieldRequestedBitCount: 11)
            }
        }
    }

    // MARK: - Exact match (fieldBitCount == Type.bitCount)

    @Test("Exact match: fieldBitCount == typeBitCount (6 == 6)")
    func exactMatch6Bits() throws {
        // fieldBits = 0b101101 = 45 positioned at MSB of byte
        // 0b101101_00 = 0xB4
        let bitsInteger: UInt8 = 0b1011_0100
        let result = try bitsInteger.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 6)
            return try __createFromBits(Strict6Bit.self, fieldBits: rawBits, fieldRequestedBitCount: 6)
        }
        #expect(result.value == 0b101101)
    }

    @Test("Exact match: fieldBitCount == typeBitCount (4 == 4)")
    func exactMatch4Bits() throws {
        // 0b1010 positioned at MSB of byte = 0b1010_0000 = 0xA0
        let bitsInteger: UInt8 = 0b1010_0000
        let result = try bitsInteger.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 4)
            return try __createFromBits(Strict4Bit.self, fieldBits: rawBits, fieldRequestedBitCount: 4)
        }
        #expect(result.value == 0b1010)
    }

    @Test("Exact match: fieldBitCount == typeBitCount (1 == 1)")
    func exactMatch1Bit() throws {
        // 1 bit = 1 at MSB = 0b1000_0000 = 0x80
        let bitsInteger1: UInt8 = 0b1000_0000
        let result1 = try bitsInteger1.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 1)
            return try __createFromBits(Strict1Bit.self, fieldBits: rawBits, fieldRequestedBitCount: 1)
        }
        #expect(result1.value == 1)

        // 1 bit = 0 at MSB = 0b0000_0000 = 0x00
        let bitsInteger0: UInt8 = 0b0000_0000
        let result0 = try bitsInteger0.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 1)
            return try __createFromBits(Strict1Bit.self, fieldBits: rawBits, fieldRequestedBitCount: 1)
        }
        #expect(result0.value == 0)
    }

    @Test("Exact match: fieldBitCount == typeBitCount (12 == 12)")
    func exactMatch12Bits() throws {
        // 0xABC (12 bits) positioned at MSB of 16-bit value
        // 0xABC << 4 = 0xABC0
        let bitsInteger: UInt16 = 0xABC0
        let result = try bitsInteger.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 12)
            return try __createFromBits(Strict12Bit.self, fieldBits: rawBits, fieldRequestedBitCount: 12)
        }
        #expect(result.value == 0xABC)
    }

    // MARK: - Excess bits (fieldBitCount > Type.bitCount) - takes MSB

    @Test("Excess bits: takes MSB when fieldBitCount > typeBitCount (8 > 6)")
    func excessBits8vs6() throws {
        // fieldBits = 0b10110100 (8 bits)
        // typeBitCount = 6, so shift right by 2
        // Result = 0b101101 = 45
        let bitsInteger: UInt8 = 0b1011_0100
        let result = try bitsInteger.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 8)
            return try __createFromBits(Strict6Bit.self, fieldBits: rawBits, fieldRequestedBitCount: 8)
        }
        #expect(result.value == 0b101101)
    }

    @Test("Excess bits: takes MSB when fieldBitCount > typeBitCount (7 > 6)")
    func excessBits7vs6() throws {
        // fieldBits = 7 bits positioned at MSB: 1011010_0 = 0b1011_0100
        // typeBitCount = 6, so takes first 6 bits = 0b101101 = 45
        let bitsInteger: UInt8 = 0b1011_0100
        let result = try bitsInteger.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 7)
            return try __createFromBits(Strict6Bit.self, fieldBits: rawBits, fieldRequestedBitCount: 7)
        }
        #expect(result.value == 0b101101)
    }

    @Test("Excess bits: takes MSB when fieldBitCount > typeBitCount (8 > 4)")
    func excessBits8vs4() throws {
        // fieldBits = 0b11010101 (8 bits)
        // typeBitCount = 4, so shift right by 4
        // Result = 0b1101 = 13
        let bitsInteger: UInt8 = 0b1101_0101
        let result = try bitsInteger.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 8)
            return try __createFromBits(Strict4Bit.self, fieldBits: rawBits, fieldRequestedBitCount: 8)
        }
        #expect(result.value == 0b1101)
    }

    @Test("Excess bits: takes MSB when fieldBitCount > typeBitCount (3 > 1)")
    func excessBits3vs1() throws {
        // fieldBits = 3 bits positioned at MSB: 101_00000 = 0b1010_0000
        // typeBitCount = 1, so takes first 1 bit = 0b1 = 1
        let bitsInteger1: UInt8 = 0b1010_0000
        let result = try bitsInteger1.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 3)
            return try __createFromBits(Strict1Bit.self, fieldBits: rawBits, fieldRequestedBitCount: 3)
        }
        #expect(result.value == 1)

        // fieldBits = 3 bits positioned at MSB: 011_00000 = 0b0110_0000
        // Takes first 1 bit = 0b0 = 0
        let bitsInteger2: UInt8 = 0b0110_0000
        let result2 = try bitsInteger2.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 3)
            return try __createFromBits(Strict1Bit.self, fieldBits: rawBits, fieldRequestedBitCount: 3)
        }
        #expect(result2.value == 0)
    }

    @Test("Excess bits: takes MSB when fieldBitCount > typeBitCount (16 > 12)")
    func excessBits16vs12() throws {
        // fieldBits = 0xABCD (16 bits)
        // typeBitCount = 12, so shift right by 4
        // Result = 0xABC
        let bitsInteger: UInt16 = 0xABCD
        let result = try bitsInteger.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 16)
            return try __createFromBits(Strict12Bit.self, fieldBits: rawBits, fieldRequestedBitCount: 16)
        }
        #expect(result.value == 0xABC)
    }

    // MARK: - Type without BitCountProviding (pass-through)

    @Test("Type without BitCountProviding: passes through bits directly")
    func flexibleTypePassThrough() throws {
        let bitsInteger: UInt8 = 0xAB
        let result = try bitsInteger.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 8)
            return try __createFromBits(Flexible8Bit.self, fieldBits: rawBits, fieldRequestedBitCount: 8)
        }
        #expect(result.value == 0xAB)
    }

    @Test("Type without BitCountProviding: passes through even with small fieldBitCount")
    func flexibleTypeSmallBitCount() throws {
        // 0b1010 positioned at MSB = 0b1010_0000
        // Reading 4 bits gives 0b1010 = 10
        let bitsInteger: UInt8 = 0b1010_0000
        let result = try bitsInteger.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 4)
            return try __createFromBits(Flexible8Bit.self, fieldBits: rawBits, fieldRequestedBitCount: 4)
        }
        #expect(result.value == 0b1010)
    }

    @Test("Type without BitCountProviding: passes through with large fieldBitCount")
    func flexibleTypeLargeBitCount() throws {
        let bitsInteger: UInt8 = 0xFF
        let result = try bitsInteger.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 8)
            return try __createFromBits(Flexible8Bit.self, fieldBits: rawBits, fieldRequestedBitCount: 16)
        }
        #expect(result.value == 0xFF)
    }

    // MARK: - Edge cases with truncation

    @Test("Truncation when fieldBits integer is wider than expected")
    func truncationWiderInteger() throws {
        // Using UInt16 value but reading as UInt8
        // Value 0x1234 - reading first byte from big-endian
        let bitsInteger: UInt16 = 0x1234
        let result = try bitsInteger.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 16)
            return try __createFromBits(Flexible8Bit.self, fieldBits: rawBits, fieldRequestedBitCount: 16)
        }
        #expect(result.value == 0x12) // Reading the first byte from big-endian
    }

    @Test("Truncation after MSB adjustment")
    func truncationAfterMSBAdjustment() throws {
        // fieldBits = 0x1234 (16 bits), fieldBitCount = 16
        // Strict6Bit.bitCount = 6, so adjust to take first 6 bits
        // 0x1234 in binary: 0001 0010 0011 0100
        // First 6 bits: 000100 = 0x04
        let bitsInteger: UInt16 = 0x1234
        let result = try bitsInteger.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 16)
            return try __createFromBits(Strict6Bit.self, fieldBits: rawBits, fieldRequestedBitCount: 16)
        }
        #expect(result.value == 0x04)
    }

    // MARK: - Zero values

    @Test("Zero fieldBits with exact match")
    func zeroFieldBitsExactMatch() throws {
        let bitsInteger: UInt8 = 0
        let result = try bitsInteger.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 6)
            return try __createFromBits(Strict6Bit.self, fieldBits: rawBits, fieldRequestedBitCount: 6)
        }
        #expect(result.value == 0)
    }

    @Test("Zero fieldBits with excess bits")
    func zeroFieldBitsExcessBits() throws {
        let bitsInteger: UInt8 = 0
        let result = try bitsInteger.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 8)
            return try __createFromBits(Strict4Bit.self, fieldBits: rawBits, fieldRequestedBitCount: 8)
        }
        #expect(result.value == 0)
    }

    // MARK: - Maximum values

    @Test("Maximum fieldBits with exact match")
    func maxFieldBitsExactMatch() throws {
        // 6 bits max = 0b111111 = 63
        let bitsInteger: UInt8 = 0b1111_1100
        let result = try bitsInteger.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 6)
            return try __createFromBits(Strict6Bit.self, fieldBits: rawBits, fieldRequestedBitCount: 6)
        }
        #expect(result.value == 63)
    }

    @Test("Maximum fieldBits with excess bits takes MSB")
    func maxFieldBitsExcessTakesMSB() throws {
        // 8 bits all ones = 0xFF
        // Take first 6 bits = 0b111111 = 63
        let bitsInteger: UInt8 = 0xFF
        let result = try bitsInteger.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 8)
            return try __createFromBits(Strict6Bit.self, fieldBits: rawBits, fieldRequestedBitCount: 8)
        }
        #expect(result.value == 63)
    }
}
