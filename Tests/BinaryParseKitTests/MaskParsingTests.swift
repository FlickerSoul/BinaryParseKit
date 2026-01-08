//
//  MaskParsingTests.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 1/7/26.
//
@testable import BinaryParseKit
import BinaryParsing
import Foundation
import Testing

@Suite("__maskParsing Tests")
struct MaskParsingUtilityTests {
    // MARK: - Test Types

    /// A type that only conforms to ExpressibleByRawBits (no BitCountProviding)
    private struct SimpleRawBitsType: ExpressibleByRawBits, Equatable {
        let value: UInt8

        init(bits: borrowing RawBitsSpan) throws {
            value = try bits.load(as: UInt8.self)
        }
    }

    /// A type that conforms to both ExpressibleByRawBits and BitCountProviding
    private struct Strict6BitType: ExpressibleByRawBits, BitCountProviding, Equatable {
        static let bitCount = 6
        let value: UInt8

        init(bits: borrowing RawBitsSpan) throws {
            value = try bits.load(as: UInt8.self)
        }
    }

    /// A type with 1-bit width for edge case testing
    private struct Strict1BitType: ExpressibleByRawBits, BitCountProviding, Equatable {
        static let bitCount = 1
        let value: UInt8

        init(bits: borrowing RawBitsSpan) throws {
            let intValue: UInt8 = try bits.load()
            value = (intValue & 1) == 1 ? 1 : 0
        }
    }

    /// A parent type for testing __maskParsing from bits
    private struct Parent16Bit: ExpressibleByRawBits {
        let value: UInt16

        init(bits: borrowing RawBitsSpan) throws {
            value = try bits.load(as: UInt16.self)
        }
    }

    @Suite("__maskParsing from bits (BitCountProviding)")
    struct MaskParsingFromBitsWithBitCountTests {}

    @Suite("__maskParsing from bits (ExpressibleByRawBits only)")
    struct MaskParsingFromBitsNoBitCountTests {}

    @Suite("__maskParsing from span (BitCountProviding)")
    struct MaskParsingFromSpanWithBitCountTests {}

    @Suite("__maskParsing from span (ExpressibleByRawBits only)")
    struct MaskParsingFromSpanNoBitCountTests {}

    @Suite("__maskParsing Edge Cases")
    struct MaskParsingEdgeCaseTests {}
}

// MARK: - Tests for __maskParsing from bits (BitCountProviding)

extension MaskParsingUtilityTests.MaskParsingFromBitsWithBitCountTests {
    @Test("Extract field at position 0")
    func extractFieldAtPosition0() throws {
        // Binary: 1011_0100_0000_0000 = 0xB400
        // Extract 6 bits at position 0: 101101 = 45
        let bitsInteger: UInt16 = 0b1011_0100_0000_0000
        let result: MaskParsingUtilityTests.Strict6BitType = try bitsInteger.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 16)
            return try __maskParsing(
                from: rawBits,
                fieldType: MaskParsingUtilityTests.Strict6BitType.self,
                fieldRequestedBitCount: 6,
                at: 0,
            )
        }
        #expect(result.value == 0b101101)
    }

    @Test("Extract field at middle position")
    func extractFieldAtMiddlePosition() throws {
        // Binary: 0000_1011_0100_0000 = 0x0B40
        // Extract 6 bits at position 4: 101101 = 45
        let bitsInteger: UInt16 = 0b0000_1011_0100_0000
        let result: MaskParsingUtilityTests.Strict6BitType = try bitsInteger.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 16)
            return try __maskParsing(
                from: rawBits,
                fieldType: MaskParsingUtilityTests.Strict6BitType.self,
                fieldRequestedBitCount: 6,
                at: 4,
            )
        }
        #expect(result.value == 0b101101)
    }

    @Test("Extract field at end position")
    func extractFieldAtEndPosition() throws {
        // Binary: 0000_0000_0010_1101 = 0x002D
        // Extract 6 bits at position 10: 101101 = 45
        let bitsInteger: UInt16 = 0b0000_0000_0010_1101
        let result: MaskParsingUtilityTests.Strict6BitType = try bitsInteger.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 16)
            return try __maskParsing(
                from: rawBits,
                fieldType: MaskParsingUtilityTests.Strict6BitType.self,
                fieldRequestedBitCount: 6,
                at: 10,
            )
        }
        #expect(result.value == 0b101101)
    }

    @Test("Throws error when bitCount < Field.bitCount")
    func throwsWhenInsufficientBits() {
        // Try to extract 5 bits into a 6-bit type
        let bitsInteger: UInt16 = 0xFFFF
        #expect(throws: BitmaskParsableError.insufficientBitsAvailable) {
            let _: MaskParsingUtilityTests.Strict6BitType = try bitsInteger.withParserSpan { parserSpan in
                let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 16)
                return try __maskParsing(
                    from: rawBits,
                    fieldType: MaskParsingUtilityTests.Strict6BitType.self,
                    fieldRequestedBitCount: 5,
                    at: 0,
                )
            }
        }
    }

    @Test("Takes MSB when bitCount > Field.bitCount")
    func takesMSBWhenExcessBits() throws {
        // Binary: 1011_0111_1100_0000 = 0xB7C0
        // Extract 10 bits at position 0: 1011011111
        // Type only takes 6 MSB bits: 101101 = 45
        let bitsInteger: UInt16 = 0b1011_0111_1100_0000
        let result: MaskParsingUtilityTests.Strict6BitType = try bitsInteger.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 16)
            return try __maskParsing(
                from: rawBits,
                fieldType: MaskParsingUtilityTests.Strict6BitType.self,
                fieldRequestedBitCount: 10,
                at: 0,
            )
        }
        #expect(result.value == 0b101101)
    }

    @Test("Single bit extraction")
    func singleBitExtraction() throws {
        // Extract 1 bit at position 0: should be 1
        let bitsInteger1: UInt16 = 0b1000_0000_0000_0000
        let result: MaskParsingUtilityTests.Strict1BitType = try bitsInteger1.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 16)
            return try __maskParsing(
                from: rawBits,
                fieldType: MaskParsingUtilityTests.Strict1BitType.self,
                fieldRequestedBitCount: 1,
                at: 0,
            )
        }
        #expect(result.value == 1)

        // Extract 1 bit at position 0: should be 0
        let bitsInteger2: UInt16 = 0b0111_1111_1111_1111
        let result2: MaskParsingUtilityTests.Strict1BitType = try bitsInteger2.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 16)
            return try __maskParsing(
                from: rawBits,
                fieldType: MaskParsingUtilityTests.Strict1BitType.self,
                fieldRequestedBitCount: 1,
                at: 0,
            )
        }
        #expect(result2.value == 0)
    }

    @Test("All zeros extraction")
    func allZerosExtraction() throws {
        let bitsInteger: UInt16 = 0x0000
        let result: MaskParsingUtilityTests.Strict6BitType = try bitsInteger.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 16)
            return try __maskParsing(
                from: rawBits,
                fieldType: MaskParsingUtilityTests.Strict6BitType.self,
                fieldRequestedBitCount: 6,
                at: 0,
            )
        }
        #expect(result.value == 0)
    }

    @Test("All ones extraction")
    func allOnesExtraction() throws {
        // Extract 6 bits of all 1s: 111111 = 63
        let bitsInteger: UInt16 = 0b1111_1100_0000_0000
        let result: MaskParsingUtilityTests.Strict6BitType = try bitsInteger.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 16)
            return try __maskParsing(
                from: rawBits,
                fieldType: MaskParsingUtilityTests.Strict6BitType.self,
                fieldRequestedBitCount: 6,
                at: 0,
            )
        }
        #expect(result.value == 0b111111)
    }
}

// MARK: - Tests for __maskParsing from bits (ExpressibleByRawBits only)

extension MaskParsingUtilityTests.MaskParsingFromBitsNoBitCountTests {
    @Test("Extract field at position 0")
    func extractFieldAtPosition0() throws {
        // Binary: 1010_1100_0000_0000 = 0xAC00
        // Extract 8 bits at position 0: 10101100 = 172
        let bitsInteger: UInt16 = 0b1010_1100_0000_0000
        let result: MaskParsingUtilityTests.SimpleRawBitsType = try bitsInteger.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 16)
            return try __maskParsing(
                from: rawBits,
                fieldType: MaskParsingUtilityTests.SimpleRawBitsType.self,
                fieldRequestedBitCount: 8,
                at: 0,
            )
        }
        #expect(result.value == 0b1010_1100)
    }

    @Test("Extract field at middle position")
    func extractFieldAtMiddlePosition() throws {
        // Binary: 0000_1010_1100_0000 = 0x0AC0
        // Extract 8 bits at position 4: 10101100 = 172
        let bitsInteger: UInt16 = 0b0000_1010_1100_0000
        let result: MaskParsingUtilityTests.SimpleRawBitsType = try bitsInteger.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 16)
            return try __maskParsing(
                from: rawBits,
                fieldType: MaskParsingUtilityTests.SimpleRawBitsType.self,
                fieldRequestedBitCount: 8,
                at: 4,
            )
        }
        #expect(result.value == 0b1010_1100)
    }

    @Test("No bit count validation (does not throw)")
    func noBitCountValidation() throws {
        // SimpleRawBitsType doesn't conform to BitCountProviding,
        // so no validation should occur even with small bitCount
        let bitsInteger: UInt16 = 0b1110_0000_0000_0000
        let result: MaskParsingUtilityTests.SimpleRawBitsType = try bitsInteger.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 16)
            return try __maskParsing(
                from: rawBits,
                fieldType: MaskParsingUtilityTests.SimpleRawBitsType.self,
                fieldRequestedBitCount: 3,
                at: 0,
            )
        }
        // Just truncates to fit RawBitsInteger
        #expect(result.value == 0b111)
    }

    @Test("No MSB adjustment (takes raw bits)")
    func noMSBAdjustment() throws {
        // Binary: 1011_0111_1100_0000 = 0xB7C0
        // Extract 10 bits at position 0: 1011011111
        // SimpleRawBitsType takes all bits (truncated to UInt8): 0b10111111 = 0xBF
        let bitsInteger: UInt16 = 0b1011_0111_1100_0000
        let result: MaskParsingUtilityTests.SimpleRawBitsType = try bitsInteger.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 16)
            return try __maskParsing(
                from: rawBits,
                fieldType: MaskParsingUtilityTests.SimpleRawBitsType.self,
                fieldRequestedBitCount: 10,
                at: 0,
            )
        }
        // 1011011111 truncated to UInt8 = 0b10111111 = 191
        #expect(result.value == 0b1011_0111)
    }

    @Test("Single bit extraction")
    func singleBitExtraction() throws {
        let bitsInteger: UInt16 = 0b1000_0000_0000_0000
        let result: MaskParsingUtilityTests.SimpleRawBitsType = try bitsInteger.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 16)
            return try __maskParsing(
                from: rawBits,
                fieldType: MaskParsingUtilityTests.SimpleRawBitsType.self,
                fieldRequestedBitCount: 1,
                at: 0,
            )
        }
        #expect(result.value == 1)
    }

    @Test("All zeros extraction")
    func allZerosExtraction() throws {
        let bitsInteger: UInt16 = 0x0000
        let result: MaskParsingUtilityTests.SimpleRawBitsType = try bitsInteger.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 16)
            return try __maskParsing(
                from: rawBits,
                fieldType: MaskParsingUtilityTests.SimpleRawBitsType.self,
                fieldRequestedBitCount: 8,
                at: 0,
            )
        }
        #expect(result.value == 0)
    }

    @Test("All ones extraction")
    func allOnesExtraction() throws {
        let bitsInteger: UInt16 = 0xFFFF
        let result: MaskParsingUtilityTests.SimpleRawBitsType = try bitsInteger.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 16)
            return try __maskParsing(
                from: rawBits,
                fieldType: MaskParsingUtilityTests.SimpleRawBitsType.self,
                fieldRequestedBitCount: 8,
                at: 0,
            )
        }
        #expect(result.value == 0xFF)
    }
}

// MARK: - Edge Case Tests

extension MaskParsingUtilityTests.MaskParsingEdgeCaseTests {
    @Test("Extract at last valid bit position")
    func extractAtLastValidPosition() throws {
        // 16-bit parent, extract 6 bits at position 10 (last valid position)
        let bitsInteger: UInt16 = 0b0000_0000_0010_1101
        let result: MaskParsingUtilityTests.Strict6BitType = try bitsInteger.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 16)
            return try __maskParsing(
                from: rawBits,
                fieldType: MaskParsingUtilityTests.Strict6BitType.self,
                fieldRequestedBitCount: 6,
                at: 10,
            )
        }
        #expect(result.value == 0b101101)
    }

    @Test("Exactly matching bit count")
    func exactlyMatchingBitCount() throws {
        // fieldRequestedBitCount == Field.bitCount (6 == 6)
        let bitsInteger: UInt16 = 0b1011_0100_0000_0000
        let result: MaskParsingUtilityTests.Strict6BitType = try bitsInteger.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 16)
            return try __maskParsing(
                from: rawBits,
                fieldType: MaskParsingUtilityTests.Strict6BitType.self,
                fieldRequestedBitCount: 6,
                at: 0,
            )
        }
        #expect(result.value == 0b101101)
    }

    @Test("Large excess bits with MSB extraction")
    func largeExcessBitsMSBExtraction() throws {
        // Request 15 bits but type only needs 6
        // Binary: 1111_0000_1111_0010 = 0xF0F2
        // 15 bits at position 0: 111100001111001 (take 6 MSB: 111100 = 60)
        let bitsInteger: UInt16 = 0b1111_0000_1111_0010
        let result: MaskParsingUtilityTests.Strict6BitType = try bitsInteger.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 16)
            return try __maskParsing(
                from: rawBits,
                fieldType: MaskParsingUtilityTests.Strict6BitType.self,
                fieldRequestedBitCount: 15,
                at: 0,
            )
        }
        #expect(result.value == 0b111100)
    }

    @Test("Single bit type with exactly 1 bit requested")
    func singleBitTypeExactMatch() throws {
        let bitsInteger: UInt16 = 0b1000_0000_0000_0000
        let result: MaskParsingUtilityTests.Strict1BitType = try bitsInteger.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 16)
            return try __maskParsing(
                from: rawBits,
                fieldType: MaskParsingUtilityTests.Strict1BitType.self,
                fieldRequestedBitCount: 1,
                at: 0,
            )
        }
        #expect(result.value == 1)
    }

    @Test("Single bit type throws when requesting 0 bits")
    func singleBitTypeThrowsOnZeroBits() {
        let bitsInteger: UInt16 = 0xFFFF
        #expect(throws: BitmaskParsableError.insufficientBitsAvailable) {
            let _: MaskParsingUtilityTests.Strict1BitType = try bitsInteger.withParserSpan { parserSpan in
                let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 16)
                return try __maskParsing(
                    from: rawBits,
                    fieldType: MaskParsingUtilityTests.Strict1BitType.self,
                    fieldRequestedBitCount: 0,
                    at: 0,
                )
            }
        }
    }

    @Test("Alternating bit pattern")
    func alternatingBitPattern() throws {
        // 0b1010_1010... pattern
        let bitsInteger: UInt16 = 0b1010_1010_1010_1010
        let result: MaskParsingUtilityTests.Strict6BitType = try bitsInteger.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 16)
            return try __maskParsing(
                from: rawBits,
                fieldType: MaskParsingUtilityTests.Strict6BitType.self,
                fieldRequestedBitCount: 6,
                at: 0,
            )
        }
        #expect(result.value == 0b101010)
    }

    @Test("Extract field with zero bit count")
    func extractFieldWithZeroBitCount() throws {
        // Binary: 0000_0000_0010_1101 = 0x002D
        // Extract 6 bits at position 10: 101101 = 45
        let bitsInteger: UInt16 = 0b0000_0000_0010_1101
        let result = try bitsInteger.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 16)
            return try __maskParsing(
                from: rawBits,
                fieldType: MaskParsingUtilityTests.SimpleRawBitsType.self,
                fieldRequestedBitCount: 0,
                at: 10,
            )
        }
        #expect(result.value == 0)
    }
}
