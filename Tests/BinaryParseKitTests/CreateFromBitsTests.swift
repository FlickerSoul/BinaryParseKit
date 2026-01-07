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
        typealias RawBitsInteger = UInt8
        static let bitCount = 6
        let value: UInt8

        init(bits: UInt8) {
            value = bits
        }
    }

    /// Type with BitCountProviding, requires exactly 4 bits
    struct Strict4Bit: ExpressibleByRawBits, BitCountProviding, Equatable {
        typealias RawBitsInteger = UInt8
        static let bitCount = 4
        let value: UInt8

        init(bits: UInt8) {
            value = bits
        }
    }

    /// Type with BitCountProviding, requires exactly 1 bit
    struct Strict1Bit: ExpressibleByRawBits, BitCountProviding, Equatable {
        typealias RawBitsInteger = UInt8
        static let bitCount = 1
        let value: Bool

        init(bits: UInt8) {
            value = (bits & 1) == 1
        }
    }

    /// Type WITHOUT BitCountProviding - should always pass through
    struct Flexible8Bit: ExpressibleByRawBits, Equatable {
        typealias RawBitsInteger = UInt8
        let value: UInt8

        init(bits: UInt8) {
            value = bits
        }
    }

    /// Type with BitCountProviding using UInt16 as RawBitsInteger
    struct Strict12Bit: ExpressibleByRawBits, BitCountProviding, Equatable {
        typealias RawBitsInteger = UInt16
        static let bitCount = 12
        let value: UInt16

        init(bits: UInt16) {
            value = bits
        }
    }

    // MARK: - Insufficient bits (fieldBitCount < Type.bitCount)

    @Test("Throws insufficientBitsAvailable when fieldBitCount < typeBitCount (5 < 6)")
    func throwsWhenInsufficientBits5vs6() {
        #expect(throws: BitmaskParsableError.insufficientBitsAvailable) {
            _ = try __createFromBits(Strict6Bit.self, fieldBits: UInt8(0b11111), fieldRequestedBitCount: 5)
        }
    }

    @Test("Throws insufficientBitsAvailable when fieldBitCount < typeBitCount (3 < 4)")
    func throwsWhenInsufficientBits3vs4() {
        #expect(throws: BitmaskParsableError.insufficientBitsAvailable) {
            _ = try __createFromBits(Strict4Bit.self, fieldBits: UInt8(0b111), fieldRequestedBitCount: 3)
        }
    }

    @Test("Throws insufficientBitsAvailable when fieldBitCount < typeBitCount (0 < 1)")
    func throwsWhenInsufficientBits0vs1() {
        #expect(throws: BitmaskParsableError.insufficientBitsAvailable) {
            _ = try __createFromBits(Strict1Bit.self, fieldBits: UInt8(0), fieldRequestedBitCount: 0)
        }
    }

    @Test("Throws insufficientBitsAvailable when fieldBitCount < typeBitCount (11 < 12)")
    func throwsWhenInsufficientBits11vs12() {
        #expect(throws: BitmaskParsableError.insufficientBitsAvailable) {
            _ = try __createFromBits(Strict12Bit.self, fieldBits: UInt16(0x7FF), fieldRequestedBitCount: 11)
        }
    }

    // MARK: - Exact match (fieldBitCount == Type.bitCount)

    @Test("Exact match: fieldBitCount == typeBitCount (6 == 6)")
    func exactMatch6Bits() throws {
        // fieldBits = 0b101101 = 45
        let result = try __createFromBits(Strict6Bit.self, fieldBits: UInt8(0b101101), fieldRequestedBitCount: 6)
        #expect(result.value == 0b101101)
    }

    @Test("Exact match: fieldBitCount == typeBitCount (4 == 4)")
    func exactMatch4Bits() throws {
        let result = try __createFromBits(Strict4Bit.self, fieldBits: UInt8(0b1010), fieldRequestedBitCount: 4)
        #expect(result.value == 0b1010)
    }

    @Test("Exact match: fieldBitCount == typeBitCount (1 == 1)")
    func exactMatch1Bit() throws {
        let result1 = try __createFromBits(Strict1Bit.self, fieldBits: UInt8(1), fieldRequestedBitCount: 1)
        #expect(result1.value == true)

        let result0 = try __createFromBits(Strict1Bit.self, fieldBits: UInt8(0), fieldRequestedBitCount: 1)
        #expect(result0.value == false)
    }

    @Test("Exact match: fieldBitCount == typeBitCount (12 == 12)")
    func exactMatch12Bits() throws {
        let result = try __createFromBits(Strict12Bit.self, fieldBits: UInt16(0xABC), fieldRequestedBitCount: 12)
        #expect(result.value == 0xABC)
    }

    // MARK: - Excess bits (fieldBitCount > Type.bitCount) - takes MSB

    @Test("Excess bits: takes MSB when fieldBitCount > typeBitCount (8 > 6)")
    func excessBits8vs6() throws {
        // fieldBits = 0b10110100 (8 bits)
        // typeBitCount = 6, so shift right by 2
        // Result = 0b101101 = 45
        let result = try __createFromBits(Strict6Bit.self, fieldBits: UInt8(0b1011_0100), fieldRequestedBitCount: 8)
        #expect(result.value == 0b101101)
    }

    @Test("Excess bits: takes MSB when fieldBitCount > typeBitCount (7 > 6)")
    func excessBits7vs6() throws {
        // fieldBits = 0b1011010 (7 bits, value 90)
        // typeBitCount = 6, so shift right by 1
        // Result = 0b101101 = 45
        let result = try __createFromBits(Strict6Bit.self, fieldBits: UInt8(0b1011010), fieldRequestedBitCount: 7)
        #expect(result.value == 0b101101)
    }

    @Test("Excess bits: takes MSB when fieldBitCount > typeBitCount (8 > 4)")
    func excessBits8vs4() throws {
        // fieldBits = 0b11010101 (8 bits)
        // typeBitCount = 4, so shift right by 4
        // Result = 0b1101 = 13
        let result = try __createFromBits(Strict4Bit.self, fieldBits: UInt8(0b1101_0101), fieldRequestedBitCount: 8)
        #expect(result.value == 0b1101)
    }

    @Test("Excess bits: takes MSB when fieldBitCount > typeBitCount (3 > 1)")
    func excessBits3vs1() throws {
        // fieldBits = 0b101 (3 bits)
        // typeBitCount = 1, so shift right by 2
        // Result = 0b1 -> true
        let result = try __createFromBits(Strict1Bit.self, fieldBits: UInt8(0b101), fieldRequestedBitCount: 3)
        #expect(result.value == true)

        // fieldBits = 0b011 (3 bits)
        // Result after shift = 0b0 -> false
        let result2 = try __createFromBits(Strict1Bit.self, fieldBits: UInt8(0b011), fieldRequestedBitCount: 3)
        #expect(result2.value == false)
    }

    @Test("Excess bits: takes MSB when fieldBitCount > typeBitCount (16 > 12)")
    func excessBits16vs12() throws {
        // fieldBits = 0xABCD (16 bits)
        // typeBitCount = 12, so shift right by 4
        // Result = 0xABC
        let result = try __createFromBits(Strict12Bit.self, fieldBits: UInt16(0xABCD), fieldRequestedBitCount: 16)
        #expect(result.value == 0xABC)
    }

    // MARK: - Type without BitCountProviding (pass-through)

    @Test("Type without BitCountProviding: passes through bits directly")
    func flexibleTypePassThrough() throws {
        let result = try __createFromBits(Flexible8Bit.self, fieldBits: UInt8(0xAB), fieldRequestedBitCount: 8)
        #expect(result.value == 0xAB)
    }

    @Test("Type without BitCountProviding: passes through even with small fieldBitCount")
    func flexibleTypeSmallBitCount() throws {
        // Even though we say fieldBitCount is 4, there's no BitCountProviding to check
        let result = try __createFromBits(Flexible8Bit.self, fieldBits: UInt8(0b1010), fieldRequestedBitCount: 4)
        #expect(result.value == 0b1010)
    }

    @Test("Type without BitCountProviding: passes through with large fieldBitCount")
    func flexibleTypeLargeBitCount() throws {
        let result = try __createFromBits(Flexible8Bit.self, fieldBits: UInt8(0xFF), fieldRequestedBitCount: 16)
        #expect(result.value == 0xFF)
    }

    // MARK: - Edge cases with truncation

    @Test("Truncation when fieldBits integer is wider than RawBitsInteger")
    func truncationWiderInteger() throws {
        // Using UInt16 fieldBits but type has UInt8 RawBitsInteger
        // Value 0x1234 truncates to 0x34
        let result = try __createFromBits(Flexible8Bit.self, fieldBits: UInt16(0x1234), fieldRequestedBitCount: 16)
        #expect(result.value == 0x34)
    }

    @Test("Truncation after MSB adjustment")
    func truncationAfterMSBAdjustment() throws {
        // fieldBits = 0x1234 (16 bits), fieldBitCount = 16
        // Strict6Bit.bitCount = 6, so shift right by 10
        // 0x1234 >> 10 = 0x04 (only lower bits remain after shift)
        // Then truncate to UInt8: 0x04
        let result = try __createFromBits(Strict6Bit.self, fieldBits: UInt16(0x1234), fieldRequestedBitCount: 16)
        #expect(result.value == 0x04)
    }

    // MARK: - Zero values

    @Test("Zero fieldBits with exact match")
    func zeroFieldBitsExactMatch() throws {
        let result = try __createFromBits(Strict6Bit.self, fieldBits: UInt8(0), fieldRequestedBitCount: 6)
        #expect(result.value == 0)
    }

    @Test("Zero fieldBits with excess bits")
    func zeroFieldBitsExcessBits() throws {
        let result = try __createFromBits(Strict4Bit.self, fieldBits: UInt8(0), fieldRequestedBitCount: 8)
        #expect(result.value == 0)
    }

    // MARK: - Maximum values

    @Test("Maximum fieldBits with exact match")
    func maxFieldBitsExactMatch() throws {
        // 6 bits max = 0b111111 = 63
        let result = try __createFromBits(Strict6Bit.self, fieldBits: UInt8(0b111111), fieldRequestedBitCount: 6)
        #expect(result.value == 63)
    }

    @Test("Maximum fieldBits with excess bits takes MSB")
    func maxFieldBitsExcessTakesMSB() throws {
        // 8 bits all ones = 0xFF
        // Shift right by 2 for 6-bit type = 0b111111 = 63
        let result = try __createFromBits(Strict6Bit.self, fieldBits: UInt8(0xFF), fieldRequestedBitCount: 8)
        #expect(result.value == 63)
    }
}
