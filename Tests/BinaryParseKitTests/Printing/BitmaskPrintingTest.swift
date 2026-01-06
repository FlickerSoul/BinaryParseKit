//
//  BitmaskPrintingTest.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 12/29/25.
//

import BinaryParseKit
import BinaryParsing
import Foundation
import Testing

// MARK: - @ParseBitmask Printing Integration Tests

@Suite
struct BitmaskPrintingTest {
    // MARK: - Basic Round-Trip Tests

    @ParseBitmask
    struct BasicFlags {
        @mask(bitCount: 1)
        var flag1: UInt8

        @mask(bitCount: 3)
        var value: UInt8

        @mask(bitCount: 4)
        var nibble: UInt8
    }

    @Test("Basic bitmask round-trip: parse then print")
    func basicBitmaskRoundTrip() throws {
        // Binary: 1 010 0011 = 0xA3
        let originalBytes = Data([0xA3])
        let bits = RawBits(data: originalBytes, size: 8)
        let flags = try BasicFlags(bits: bits)

        // Print back to bytes
        let printedBytes = try flags.printParsed(printer: .data)
        #expect(printedBytes == originalBytes)
    }

    @Test("Basic bitmask round-trip: all zeros")
    func basicBitmaskRoundTripAllZeros() throws {
        let originalBytes = Data([0x00])
        let bits = RawBits(data: originalBytes, size: 8)
        let flags = try BasicFlags(bits: bits)

        let printedBytes = try flags.printParsed(printer: .data)
        #expect(printedBytes == originalBytes)
    }

    @Test("Basic bitmask round-trip: all ones")
    func basicBitmaskRoundTripAllOnes() throws {
        let originalBytes = Data([0xFF])
        let bits = RawBits(data: originalBytes, size: 8)
        let flags = try BasicFlags(bits: bits)

        let printedBytes = try flags.printParsed(printer: .data)
        #expect(printedBytes == originalBytes)
    }

    // MARK: - Multi-Byte Round-Trip Tests

    @ParseBitmask
    struct WideBitmask {
        @mask(bitCount: 4)
        var high: UInt8

        @mask(bitCount: 8)
        var middle: UInt8

        @mask(bitCount: 4)
        var low: UInt8
    }

    @Test("Multi-byte bitmask round-trip")
    func multiByteBitmaskRoundTrip() throws {
        // Binary: 1010 10110011 0100 = 0xAB 0x34
        let originalBytes = Data([0xAB, 0x34])
        let bits = RawBits(data: originalBytes, size: 16)
        let wide = try WideBitmask(bits: bits)

        let printedBytes = try wide.printParsed(printer: .data)
        #expect(printedBytes == originalBytes)
    }

    // MARK: - Non-Byte-Aligned Round-Trip Tests

    @ParseBitmask
    struct NonByteAligned: Equatable {
        @mask(bitCount: 3)
        var first: UInt8

        @mask(bitCount: 5)
        var second: UInt8

        @mask(bitCount: 2)
        var third: UInt8
    }

    @Test("Non-byte-aligned bitmask round-trip (10 bits)")
    func nonByteAlignedBitmaskRoundTrip() throws {
        // Binary: 101 01100 11 = 10 bits
        // Byte representation: 10101100 11000000 = 0xAC 0xC0
        let originalData = Data([0xAC, 0xC0])
        let bits = RawBits(data: originalData, size: 10)
        let bitmask = try NonByteAligned(bits: bits)

        let printedBytes = try bitmask.printParsed(printer: .data)
        // Should output 2 bytes with the 10 bits at MSB
        #expect(printedBytes == originalData)
    }

    // MARK: - toRawBits Tests

    @Test("toRawBits produces correct bits")
    func toRawBitsCorrectness() throws {
        let flags = BasicFlags(flag1: 1, value: 2, nibble: 3)
        let rawBits = try flags.toRawBits(bitCount: BasicFlags.bitCount)

        #expect(rawBits.size == 8)
        #expect(Array(rawBits.data) == [0xA3]) // 1 010 0011
    }

    @Test("toRawBits with different values")
    func toRawBitsDifferentValues() throws {
        let flags = BasicFlags(flag1: 0, value: 7, nibble: 15)
        let rawBits = try flags.toRawBits(bitCount: BasicFlags.bitCount)

        #expect(rawBits.size == 8)
        // 0 111 1111 = 0x7F
        #expect(Array(rawBits.data) == [0x7F])
    }

    // MARK: - printerIntel Tests

    @Test("printerIntel returns bitmask intel")
    func printerIntelReturnsBitmask() throws {
        let bits = RawBits(data: Data([0xA3]), size: 8)
        let flags = try BasicFlags(bits: bits)

        let intel = try flags.printerIntel()
        guard case let .bitmask(bitmaskIntel) = intel else {
            Issue.record("Expected .bitmask intel, got \(intel)")
            return
        }

        #expect(bitmaskIntel.bits.size == 8)
        #expect(Array(bitmaskIntel.bits.data) == [0xA3])
    }

    // MARK: - Edge Case Tests: Padding and Various Bit Widths

    /// 13-bit bitmask (not byte-aligned)
    @ParseBitmask
    struct ThirteenBitMask: Equatable {
        @mask(bitCount: 5)
        var highBits: UInt8

        @mask(bitCount: 4)
        var middleBits: UInt8

        @mask(bitCount: 4)
        var lowBits: UInt8
    }

    @Test("13-bit bitmask round-trip")
    func thirteenBitMaskRoundTrip() throws {
        // 10101 1100 0011 000 (padded to 16 bits) -> highBits=21, middleBits=12, lowBits=3
        // Bytes: 10101110 00011000 = 0xAE 0x18
        let originalData = Data([0b1010_1110, 0b0001_1000])
        let bits = RawBits(data: originalData, size: 13)
        let parsed = try ThirteenBitMask(bits: bits)
        #expect(parsed == ThirteenBitMask(highBits: 0b10101, middleBits: 0b1100, lowBits: 0b0011))
        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == originalData)
    }

    /// Eight single-bit fields
    @ParseBitmask
    struct EightSingleBits: Equatable {
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

    @Test("Eight single-bit fields round-trip")
    func eightSingleBitsRoundTrip() throws {
        // 10101010 -> bit0=1, bit1=0, bit2=1, bit3=0, bit4=1, bit5=0, bit6=1, bit7=0
        let originalData = Data([0b1010_1010])
        let bits = RawBits(data: originalData, size: 8)
        let parsed = try EightSingleBits(bits: bits)
        #expect(parsed == EightSingleBits(bit0: 1, bit1: 0, bit2: 1, bit3: 0, bit4: 1, bit5: 0, bit6: 1, bit7: 0))
        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == originalData)
    }

    @Test("Eight single-bit fields all ones round-trip")
    func eightSingleBitsAllOnesRoundTrip() throws {
        let originalData = Data([0xFF])
        let bits = RawBits(data: originalData, size: 8)
        let parsed = try EightSingleBits(bits: bits)
        #expect(parsed == EightSingleBits(bit0: 1, bit1: 1, bit2: 1, bit3: 1, bit4: 1, bit5: 1, bit6: 1, bit7: 1))
        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == originalData)
    }

    @Test("Eight single-bit fields all zeros round-trip")
    func eightSingleBitsAllZerosRoundTrip() throws {
        let originalData = Data([0x00])
        let bits = RawBits(data: originalData, size: 8)
        let parsed = try EightSingleBits(bits: bits)
        #expect(parsed == EightSingleBits(bit0: 0, bit1: 0, bit2: 0, bit3: 0, bit4: 0, bit5: 0, bit6: 0, bit7: 0))
        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == originalData)
    }

    /// Large bitmask spanning 32 bits
    @ParseBitmask
    struct LargeBitmask: Equatable {
        @mask(bitCount: 20)
        var largePart: UInt32

        @mask(bitCount: 12)
        var smallPart: UInt16
    }

    @Test("Large 32-bit bitmask round-trip")
    func largeBitmaskRoundTrip() throws {
        // 20 bits + 12 bits = 32 bits total
        let originalData = Data([0x12, 0x34, 0x56, 0x78])
        let bits = RawBits(data: originalData, size: 32)
        let parsed = try LargeBitmask(bits: bits)
        #expect(parsed == LargeBitmask(largePart: 0x1234_5000, smallPart: 0x6780))
        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == originalData)
    }

    /// Asymmetric bit widths (1, 2, 3, 4, 5, 6, 7 bits = 28 bits total)
    @ParseBitmask
    struct AsymmetricBitWidths: Equatable {
        @mask(bitCount: 1)
        var oneBit: UInt8

        @mask(bitCount: 2)
        var twoBits: UInt8

        @mask(bitCount: 3)
        var threeBits: UInt8

        @mask(bitCount: 4)
        var fourBits: UInt8

        @mask(bitCount: 5)
        var fiveBits: UInt8

        @mask(bitCount: 6)
        var sixBits: UInt8

        @mask(bitCount: 7)
        var sevenBits: UInt8
    }

    @Test("Asymmetric bit widths (1-7 bits) round-trip")
    func asymmetricBitWidthsRoundTrip() throws {
        // 1 + 2 + 3 + 4 + 5 + 6 + 7 = 28 bits
        // 1 11 101 0110 01111 010101 0101010 0000
        // Bytes: 11110101 10011110 10101010 10100000 = 0xF5 0x9E 0xAA 0xA0
        let originalData = Data([0b1111_0101, 0b1001_1110, 0b1010_1010, 0b1010_0000])
        let bits = RawBits(data: originalData, size: 28)
        let parsed = try AsymmetricBitWidths(bits: bits)
        #expect(parsed == AsymmetricBitWidths(
            oneBit: 1,
            twoBits: 0b11,
            threeBits: 0b101,
            fourBits: 0b0110,
            fiveBits: 0b01111,
            sixBits: 0b010101,
            sevenBits: 0b0101010,
        ))
        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == originalData)
    }

    /// Two equal 16-bit halves
    @ParseBitmask
    struct TwoHalves: Equatable {
        @mask(bitCount: 16)
        var upperHalf: UInt16

        @mask(bitCount: 16)
        var lowerHalf: UInt16
    }

    @Test("Two 16-bit halves round-trip")
    func twoHalvesRoundTrip() throws {
        let originalData = Data([0x12, 0x34, 0x56, 0x78])
        let bits = RawBits(data: originalData, size: 32)
        let parsed = try TwoHalves(bits: bits)
        #expect(parsed == TwoHalves(upperHalf: 0x1234, lowerHalf: 0x5678))
        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == originalData)
    }

    /// Single 3-bit field (minimal non-byte-aligned)
    @ParseBitmask
    struct ThreeBitField: Equatable {
        @mask(bitCount: 3)
        var value: UInt8
    }

    @Test("Single 3-bit field round-trip")
    func threeBitFieldRoundTrip() throws {
        // 101 00000 = 0xA0
        let originalData = Data([0b1010_0000])
        let bits = RawBits(data: originalData, size: 3)
        let parsed = try ThreeBitField(bits: bits)
        #expect(parsed == ThreeBitField(value: 0b101))
        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == originalData)
    }

    @Test("ThreeBitField bitCount is correct")
    func threeBitFieldBitCount() {
        #expect(ThreeBitField.bitCount == 3)
    }

    /// 24-bit bitmask (3 bytes exactly)
    @ParseBitmask
    struct TwentyFourBits: Equatable {
        @mask(bitCount: 8)
        var firstByte: UInt8

        @mask(bitCount: 8)
        var secondByte: UInt8

        @mask(bitCount: 8)
        var thirdByte: UInt8
    }

    @Test("24-bit (3 bytes) bitmask round-trip")
    func twentyFourBitsRoundTrip() throws {
        let originalData = Data([0xAB, 0xCD, 0xEF])
        let bits = RawBits(data: originalData, size: 24)
        let parsed = try TwentyFourBits(bits: bits)
        #expect(parsed == TwentyFourBits(firstByte: 0xAB, secondByte: 0xCD, thirdByte: 0xEF))
        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == originalData)
    }

    @Test("TwentyFourBits bitCount is correct")
    func twentyFourBitsBitCount() {
        #expect(TwentyFourBits.bitCount == 24)
    }

    /// 7-bit bitmask (one bit less than a byte)
    @ParseBitmask
    struct SevenBits: Equatable {
        @mask(bitCount: 3)
        var high: UInt8

        @mask(bitCount: 4)
        var low: UInt8
    }

    @Test("7-bit bitmask round-trip")
    func sevenBitsRoundTrip() throws {
        // 101 0110 0 = 0xAC (with trailing 0 padding)
        let originalData = Data([0b1010_1100])
        let bits = RawBits(data: originalData, size: 7)
        let parsed = try SevenBits(bits: bits)
        #expect(parsed == SevenBits(high: 0b101, low: 0b0110))
        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == originalData)
    }

    @Test("SevenBits bitCount is correct")
    func sevenBitsBitCount() {
        #expect(SevenBits.bitCount == 7)
    }

    /// 9-bit bitmask (one bit more than a byte)
    @ParseBitmask
    struct NineBits: Equatable {
        @mask(bitCount: 4)
        var high: UInt8

        @mask(bitCount: 5)
        var low: UInt8
    }

    @Test("9-bit bitmask round-trip")
    func nineBitsRoundTrip() throws {
        // 1010 10110 0000000 = 0xAB 0x00 (with trailing padding)
        let originalData = Data([0b1010_1011, 0b0000_0000])
        let bits = RawBits(data: originalData, size: 9)
        let parsed = try NineBits(bits: bits)
        #expect(parsed == NineBits(high: 0b1010, low: 0b10110))
        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == originalData)
    }

    @Test("NineBits bitCount is correct")
    func nineBitsBitCount() {
        #expect(NineBits.bitCount == 9)
    }

    // MARK: - Padding Normalization Tests (input padding bits != output padding bits)

    @Test("Non-byte-aligned input with dirty padding bits gets normalized")
    func nonByteAlignedDirtyPaddingNormalized() throws {
        // 10 bits: 101 01100 11 with dirty padding bits (111111)
        // Input:  10101100 11111111 (padding bits are all 1s)
        // Output: 10101100 11000000 (padding bits normalized to 0s)
        let inputData = Data([0b1010_1100, 0b1111_1111])
        let bits = RawBits(data: inputData, size: 10)
        let parsed = try NonByteAligned(bits: bits)
        #expect(parsed == NonByteAligned(first: 0b101, second: 0b01100, third: 0b11))
        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == Data([0b1010_1100, 0b1100_0000]))
    }

    @Test("13-bit bitmask with dirty padding normalized")
    func thirteenBitDirtyPaddingNormalized() throws {
        // 13 bits with trailing 3 dirty padding bits (all 1s)
        // Input:  10101110 00011111 (padding: 111)
        // Output: 10101110 00011000 (padding: 000)
        let inputData = Data([0b1010_1110, 0b0001_1111])
        let bits = RawBits(data: inputData, size: 13)
        let parsed = try ThirteenBitMask(bits: bits)
        #expect(parsed == ThirteenBitMask(highBits: 0b10101, middleBits: 0b1100, lowBits: 0b0011))
        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == Data([0b1010_1110, 0b0001_1000]))
    }

    @Test("3-bit field with dirty padding normalized")
    func threeBitDirtyPaddingNormalized() throws {
        // 3 bits: 101 with dirty padding (11111)
        // Input:  10111111
        // Output: 10100000
        let inputData = Data([0b1011_1111])
        let bits = RawBits(data: inputData, size: 3)
        let parsed = try ThreeBitField(bits: bits)
        #expect(parsed == ThreeBitField(value: 0b101))
        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == Data([0b1010_0000]))
    }

    @Test("7-bit bitmask with dirty padding normalized")
    func sevenBitDirtyPaddingNormalized() throws {
        // 7 bits: 101 0110 with dirty padding (1)
        // Input:  10101101
        // Output: 10101100
        let inputData = Data([0b1010_1101])
        let bits = RawBits(data: inputData, size: 7)
        let parsed = try SevenBits(bits: bits)
        #expect(parsed == SevenBits(high: 0b101, low: 0b0110))
        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == Data([0b1010_1100]))
    }

    @Test("9-bit bitmask with dirty padding normalized")
    func nineBitDirtyPaddingNormalized() throws {
        // 9 bits: 1010 10110 with dirty padding (1111111)
        // Input:  10101011 01111111
        // Output: 10101011 00000000
        let inputData = Data([0b1010_1011, 0b0111_1111])
        let bits = RawBits(data: inputData, size: 9)
        let parsed = try NineBits(bits: bits)
        #expect(parsed == NineBits(high: 0b1010, low: 0b10110))
        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == Data([0b1010_1011, 0b0000_0000]))
    }

    @Test("28-bit asymmetric with dirty padding normalized")
    func asymmetricDirtyPaddingNormalized() throws {
        // 28 bits with 4 dirty padding bits
        // Input has padding bits = 1111
        // Output should have padding bits = 0000
        let inputData = Data([0b1111_0101, 0b1001_1110, 0b1010_1010, 0b1010_1111])
        let bits = RawBits(data: inputData, size: 28)
        let parsed = try AsymmetricBitWidths(bits: bits)
        #expect(parsed == AsymmetricBitWidths(
            oneBit: 1,
            twoBits: 0b11,
            threeBits: 0b101,
            fourBits: 0b0110,
            fiveBits: 0b01111,
            sixBits: 0b010101,
            sevenBits: 0b0101010,
        ))
        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == Data([0b1111_0101, 0b1001_1110, 0b1010_1010, 0b1010_0000]))
    }
}
