//
//  ExtractBitsAsIntegerTests.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 1/6/26.
//
@testable import BinaryParseKit
import BinaryParsing
import Foundation
import Testing

@Suite("__extractBitsAsInteger Tests")
struct ExtractBitsAsIntegerTests {
    @Test("Extract 8 bits as UInt8")
    func extract8BitsAsUInt8() throws {
        let data = Data([0b1101_0011])
        try data.withParserSpan { span in
            let value = try __extractBitsAsInteger(UInt8.self, from: span, offset: 0, count: 8)
            #expect(value == 0b1101_0011)
        }
    }

    @Test("Extract first 4 bits (MSB-first)")
    func extractFirst4Bits() throws {
        // 0b1101_0011 - first 4 bits = 0b1101 = 13
        let data = Data([0b1101_0011])
        try data.withParserSpan { span in
            let value = try __extractBitsAsInteger(UInt8.self, from: span, offset: 0, count: 4)
            #expect(value == 0b1101)
        }
    }

    @Test("Extract last 4 bits (MSB-first)")
    func extractLast4Bits() throws {
        // 0b1101_0011 - last 4 bits = 0b0011 = 3
        let data = Data([0b1101_0011])
        try data.withParserSpan { span in
            let value = try __extractBitsAsInteger(UInt8.self, from: span, offset: 4, count: 4)
            #expect(value == 0b0011)
        }
    }

    @Test("Extract middle 4 bits")
    func extractMiddle4Bits() throws {
        // 0b1101_0011 - bits [2,6) = 0b0100 = 4
        let data = Data([0b1101_0011])
        try data.withParserSpan { span in
            let value = try __extractBitsAsInteger(UInt8.self, from: span, offset: 2, count: 4)
            #expect(value == 0b0100)
        }
    }

    @Test("Extract single bit (true)")
    func extractSingleBitTrue() throws {
        // 0b1000_0000 - bit 0 = 1
        let data = Data([0b1000_0000])
        try data.withParserSpan { span in
            let value = try __extractBitsAsInteger(UInt8.self, from: span, offset: 0, count: 1)
            #expect(value == 1)
        }
    }

    @Test("Extract single bit (false)")
    func extractSingleBitFalse() throws {
        // 0b0111_1111 - bit 0 = 0
        let data = Data([0b0111_1111])
        try data.withParserSpan { span in
            let value = try __extractBitsAsInteger(UInt8.self, from: span, offset: 0, count: 1)
            #expect(value == 0)
        }
    }

    @Test("Extract 16 bits as UInt16")
    func extract16BitsAsUInt16() throws {
        // 0x1234 in big endian
        let data = Data([0x12, 0x34])
        try data.withParserSpan { span in
            let value = try __extractBitsAsInteger(UInt16.self, from: span, offset: 0, count: 16)
            #expect(value == 0x1234)
        }
    }

    @Test("Extract bits spanning byte boundary")
    func extractBitsSpanningByteBoundary() throws {
        // 0b1010_1100 0b1100_1010 - bits [4,12) spans bytes
        // bits 4-7 from byte 0: 1100
        // bits 8-11 from byte 1: 1100
        // result: 0b1100_1100 = 204
        let data = Data([0b1010_1100, 0b1100_1010])
        try data.withParserSpan { span in
            let value = try __extractBitsAsInteger(UInt8.self, from: span, offset: 4, count: 8)
            #expect(value == 0b1100_1100)
        }
    }

    @Test("Extract 10 bits spanning byte boundary")
    func extract10BitsSpanningBoundary() throws {
        // 0b1010_1010 0b1100_1100 - bits [3,13)
        // bits 3-7: 01010
        // bits 8-12: 11001
        // result: 0b01010_11001 = 345
        let data = Data([0b1010_1010, 0b1100_1100])
        try data.withParserSpan { span in
            let value = try __extractBitsAsInteger(UInt16.self, from: span, offset: 3, count: 10)
            #expect(value == 0b01_0101_1001)
        }
    }

    @Test("Extract zero bits returns zero")
    func extractZeroBits() throws {
        let data = Data([0xFF])
        try data.withParserSpan { span in
            let value = try __extractBitsAsInteger(UInt8.self, from: span, offset: 0, count: 0)
            #expect(value == 0)
        }
    }

    @Test("MSB-first bit extraction per spec")
    func msbFirstBitExtractionPerSpec() throws {
        // Spec scenario: byte 0b11010011
        // Field A: 2 bits = 0b11 = 3
        // Field B: 4 bits = 0b0100 = 4
        // Field C: 2 bits = 0b11 = 3
        let data = Data([0b1101_0011])
        try data.withParserSpan { span in
            let fieldA = try __extractBitsAsInteger(UInt8.self, from: span, offset: 0, count: 2)
            let fieldB = try __extractBitsAsInteger(UInt8.self, from: span, offset: 2, count: 4)
            let fieldC = try __extractBitsAsInteger(UInt8.self, from: span, offset: 6, count: 2)

            #expect(fieldA == 3)
            #expect(fieldB == 4)
            #expect(fieldC == 3)
        }
    }

    // MARK: - Multi-byte spanning tests

    @Test("Extract 16 bits spanning 3 bytes (offset in middle of first byte)")
    func extract16BitsSpanning3Bytes() throws {
        // Bytes: [0b1010_0101, 0b1100_0011, 0b1111_0000]
        // Extract 16 bits starting at bit offset 4 (middle of first byte)
        // Bits 4-7 from byte 0: 0101
        // Bits 8-15 from byte 1: 11000011
        // Bits 16-19 from byte 2: 1111
        // Result: 0101_1100_0011_1111 = 0x5C3F
        let data = Data([0b1010_0101, 0b1100_0011, 0b1111_0000])
        try data.withParserSpan { span in
            let value = try __extractBitsAsInteger(UInt16.self, from: span, offset: 4, count: 16)
            #expect(value == 0b0101_1100_0011_1111)
        }
    }

    @Test("Extract 24 bits spanning 4 bytes")
    func extract24BitsSpanning4Bytes() throws {
        // Bytes: [0b1111_0000, 0b1010_1010, 0b0101_0101, 0b1100_1100]
        // Extract 24 bits starting at bit offset 4
        // Result spans bytes 0-3
        let data = Data([0b1111_0000, 0b1010_1010, 0b0101_0101, 0b1100_1100])
        try data.withParserSpan { span in
            let value = try __extractBitsAsInteger(UInt32.self, from: span, offset: 4, count: 24)
            // Bits: 0000_1010_1010_0101_0101_1100 = 0x0AA55C
            #expect(value == 0x0AA55C)
        }
    }

    @Test("Extract 32 bits as UInt32")
    func extract32BitsAsUInt32() throws {
        let data = Data([0x12, 0x34, 0x56, 0x78])
        try data.withParserSpan { span in
            let value = try __extractBitsAsInteger(UInt32.self, from: span, offset: 0, count: 32)
            #expect(value == 0x1234_5678)
        }
    }

    @Test("Extract 32 bits with offset spanning 5 bytes")
    func extract32BitsWithOffset() throws {
        // Start at bit 4, extract 32 bits (spans 5 bytes)
        let data = Data([0b1111_0001, 0x23, 0x45, 0x67, 0x89])
        try data.withParserSpan { span in
            let value = try __extractBitsAsInteger(UInt32.self, from: span, offset: 4, count: 32)
            // First nibble of byte 0 (0001) + bytes 1-4 shifted
            #expect(value == 0x1234_5678)
        }
    }

    @Test("Extract 64 bits as UInt64")
    func extract64BitsAsUInt64() throws {
        let data = Data([0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF])
        try data.withParserSpan { span in
            let value = try __extractBitsAsInteger(UInt64.self, from: span, offset: 0, count: 64)
            #expect(value == 0x0123_4567_89AB_CDEF)
        }
    }

    @Test("Extract 64 bits with small offset spanning 9 bytes")
    func extract64BitsWithSmallOffset() throws {
        // Start at bit 1, extract 64 bits
        // Input:    [0]0000001 00100011 01000101 01100111 10001001 10101011 11001101 11101111 0[0000000]
        //              ^^^^^^^ ^^^^^^^^ ^^^^^^^^ ^^^^^^^^ ^^^^^^^^ ^^^^^^^^ ^^^^^^^^ ^^^^^^^^ ^
        //              bits 1-7  8-15    16-23    24-31    32-39    40-47    48-55    56-63   bit 64
        // Expected: 00000001 00100011 01000101 01100111 10001001 10101011 11001101 11101111
        //         = 0x0123456789ABCDEF
        let data = Data([
            0b0000_0001,
            0b0010_0011,
            0b0100_0101,
            0b0110_0111,
            0b1000_1001,
            0b1010_1011,
            0b1100_1101,
            0b1110_1111,
            0b0000_0000,
        ])
        try data.withParserSpan { span in
            let value = try __extractBitsAsInteger(UInt64.self, from: span, offset: 1, count: 64)
            #expect(value == 0b0000_0010_0100_0110_1000_1010_1100_1111_0001_0011_0101_0111_1001_1011_1101_1110)
        }
    }

    // MARK: - Error cases

    @Test("Throws when count exceeds integer bit width (UInt8)")
    func throwsWhenCountExceedsUInt8Width() throws {
        let data = Data([0xFF, 0xFF])
        #expect(throws: BitmaskParsableError.rawBitsIntegerNotWideEnough) {
            try data.withParserSpan { span in
                _ = try __extractBitsAsInteger(UInt8.self, from: span, offset: 0, count: 9)
            }
        }
    }

    // MARK: - Boundary cases

    @Test("Extract exactly at integer bit width boundary (32 bits)")
    func extractExactly32Bits() throws {
        let data = Data([0xDE, 0xAD, 0xBE, 0xEF])
        try data.withParserSpan { span in
            let value = try __extractBitsAsInteger(UInt32.self, from: span, offset: 0, count: 32)
            #expect(value == 0xDEAD_BEEF)
        }
    }

    // MARK: - Unusual offsets

    @Test("Extract with offset at last bit of byte")
    func extractWithOffsetAtLastBitOfByte() throws {
        // Offset 7 means we start at the LSB of first byte
        let data = Data([0b0000_0001, 0b1010_1010, 0b0000_0000])
        try data.withParserSpan { span in
            // Extract 9 bits starting at bit 7
            // Bit 7 from byte 0: 1
            // Bits 0-7 from byte 1: 10101010
            // Result: 1_1010_1010 = 0x1AA
            let value = try __extractBitsAsInteger(UInt16.self, from: span, offset: 7, count: 9)
            #expect(value == 0b1_1010_1010)
        }
    }

    @Test("Extract single bit from various positions")
    func extractSingleBitFromVariousPositions() throws {
        let data = Data([0b1010_0101])
        try data.withParserSpan { span in
            let bit0 = try __extractBitsAsInteger(UInt8.self, from: span, offset: 0, count: 1)
            let bit1 = try __extractBitsAsInteger(UInt8.self, from: span, offset: 1, count: 1)
            let bit2 = try __extractBitsAsInteger(UInt8.self, from: span, offset: 2, count: 1)
            let bit3 = try __extractBitsAsInteger(UInt8.self, from: span, offset: 3, count: 1)
            let bit4 = try __extractBitsAsInteger(UInt8.self, from: span, offset: 4, count: 1)
            let bit5 = try __extractBitsAsInteger(UInt8.self, from: span, offset: 5, count: 1)
            let bit6 = try __extractBitsAsInteger(UInt8.self, from: span, offset: 6, count: 1)
            let bit7 = try __extractBitsAsInteger(UInt8.self, from: span, offset: 7, count: 1)

            #expect(bit0 == 1)
            #expect(bit1 == 0)
            #expect(bit2 == 1)
            #expect(bit3 == 0)
            #expect(bit4 == 0)
            #expect(bit5 == 1)
            #expect(bit6 == 0)
            #expect(bit7 == 1)
        }
    }
}
