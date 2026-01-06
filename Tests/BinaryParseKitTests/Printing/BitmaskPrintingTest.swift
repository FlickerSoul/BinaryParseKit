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

extension PrintingTests { @Suite struct BitmaskPrintingTest {} }

// MARK: - @ParseBitmask Printing Integration Tests

extension PrintingTests.BitmaskPrintingTest {
    // MARK: - Basic Round-Trip Tests

    @ParseBitmask
    struct BasicFlags {
        typealias RawBitsInteger = UInt8

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
        let originalBytes = Data([0b1010_0011])
        let flags = try BasicFlags(bits: 0b1010_0011)

        // Print back to bytes
        let printedBytes = try flags.printParsed(printer: .data)
        #expect(printedBytes == originalBytes)
    }

    @Test("Basic bitmask round-trip: all zeros")
    func basicBitmaskRoundTripAllZeros() throws {
        let originalBytes = Data([0b0000_0000])
        let flags = try BasicFlags(bits: 0b0000_0000)

        let printedBytes = try flags.printParsed(printer: .data)
        #expect(printedBytes == originalBytes)
    }

    @Test("Basic bitmask round-trip: all ones")
    func basicBitmaskRoundTripAllOnes() throws {
        let originalBytes = Data([0b1111_1111])
        let flags = try BasicFlags(bits: 0b1111_1111)

        let printedBytes = try flags.printParsed(printer: .data)
        #expect(printedBytes == originalBytes)
    }

    // MARK: - Multi-Byte Round-Trip Tests

    @ParseBitmask
    struct WideBitmask {
        typealias RawBitsInteger = UInt16

        @mask(bitCount: 4)
        var high: UInt8

        @mask(bitCount: 8)
        var middle: UInt8

        @mask(bitCount: 4)
        var low: UInt8
    }

    @Test("Multi-byte bitmask round-trip")
    func multiByteBitmaskRoundTrip() throws {
        // Binary: 1010 10110011 0100 = 0xAB34
        let originalBytes = Data([0b1010_1011, 0b0011_0100])
        let wide = try WideBitmask(bits: 0b1010_1011_0011_0100)

        let printedBytes = try wide.printParsed(printer: .data)
        #expect(printedBytes == originalBytes)
    }

    // MARK: - Non-Byte-Aligned Round-Trip Tests

    @ParseBitmask
    struct NonByteAligned: Equatable {
        typealias RawBitsInteger = UInt16

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
        // Byte representation: 10101100 11000000 = 0xACC0 (MSB-aligned in 16-bit)
        let originalData = Data([0b1010_1100, 0b1100_0000])
        let bitmask = try NonByteAligned(bits: 0b1010_1100_1100_0000)

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
        #expect(Array(rawBits.data) == [0b1010_0011]) // 1 010 0011
    }

    @Test("toRawBits with different values")
    func toRawBitsDifferentValues() throws {
        let flags = BasicFlags(flag1: 0, value: 7, nibble: 15)
        let rawBits = try flags.toRawBits(bitCount: BasicFlags.bitCount)

        #expect(rawBits.size == 8)
        // 0 111 1111 = 0x7F
        #expect(Array(rawBits.data) == [0b0111_1111])
    }

    // MARK: - printerIntel Tests

    @Test("printerIntel returns bitmask intel")
    func printerIntelReturnsBitmask() throws {
        let flags = try BasicFlags(bits: 0b1010_0011)

        let intel = try flags.printerIntel()
        guard case let .bitmask(bitmaskIntel) = intel else {
            Issue.record("Expected .bitmask intel, got \(intel)")
            return
        }

        #expect(bitmaskIntel.bits.size == 8)
        #expect(Array(bitmaskIntel.bits.data) == [0b1010_0011])
    }

    // MARK: - Edge Case Tests: Padding and Various Bit Widths

    /// 13-bit bitmask (not byte-aligned)
    @ParseBitmask
    struct ThirteenBitMask: Equatable {
        typealias RawBitsInteger = UInt16

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
        // Bytes: 10101110 00011000 = 0xAE18 (MSB-aligned in 16-bit)
        let originalData = Data([0b1010_1110, 0b0001_1000])
        let parsed = try ThirteenBitMask(bits: 0b1010_1110_0001_1000)
        #expect(parsed == ThirteenBitMask(highBits: 0b10101, middleBits: 0b1100, lowBits: 0b0011))
        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == originalData)
    }

    /// Eight single-bit fields
    @ParseBitmask
    struct EightSingleBits: Equatable {
        typealias RawBitsInteger = UInt8

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
        let parsed = try EightSingleBits(bits: 0b1010_1010)
        #expect(parsed == EightSingleBits(bit0: 1, bit1: 0, bit2: 1, bit3: 0, bit4: 1, bit5: 0, bit6: 1, bit7: 0))
        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == originalData)
    }

    @Test("Eight single-bit fields all ones round-trip")
    func eightSingleBitsAllOnesRoundTrip() throws {
        let originalData = Data([0b1111_1111])
        let parsed = try EightSingleBits(bits: 0b1111_1111)
        #expect(parsed == EightSingleBits(bit0: 1, bit1: 1, bit2: 1, bit3: 1, bit4: 1, bit5: 1, bit6: 1, bit7: 1))
        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == originalData)
    }

    @Test("Eight single-bit fields all zeros round-trip")
    func eightSingleBitsAllZerosRoundTrip() throws {
        let originalData = Data([0b0000_0000])
        let parsed = try EightSingleBits(bits: 0b0000_0000)
        #expect(parsed == EightSingleBits(bit0: 0, bit1: 0, bit2: 0, bit3: 0, bit4: 0, bit5: 0, bit6: 0, bit7: 0))
        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == originalData)
    }

    /// Large bitmask spanning 32 bits
    @ParseBitmask
    struct LargeBitmask: Equatable {
        typealias RawBitsInteger = UInt32

        @mask(bitCount: 20)
        var largePart: UInt32

        @mask(bitCount: 12)
        var smallPart: UInt16
    }

    @Test("Large 32-bit bitmask round-trip")
    func largeBitmaskRoundTrip() throws {
        // 20 bits + 12 bits = 32 bits total
        let originalData = Data([0x12, 0x34, 0x56, 0x78])
        let parsed = try LargeBitmask(bits: 0x1234_5678)
        // 0x12345678 -> first 20 bits = 0x12345 (= 74565), last 12 bits = 0x678 (= 1656)
        #expect(parsed == LargeBitmask(largePart: 0x12345, smallPart: 0x678))
        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == originalData)
    }

    /// Asymmetric bit widths (1, 2, 3, 4, 5, 6, 7 bits = 28 bits total)
    @ParseBitmask
    struct AsymmetricBitWidths: Equatable {
        typealias RawBitsInteger = UInt32

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
        // Bytes: 11110101 10011110 10101010 10100000 = 0xF59EAAA0 (MSB-aligned in 32-bit)
        let originalData = Data([0b1111_0101, 0b1001_1110, 0b1010_1010, 0b1010_0000])
        let parsed = try AsymmetricBitWidths(bits: 0b1111_0101_1001_1110_1010_1010_1010_0000)
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
        typealias RawBitsInteger = UInt32

        @mask(bitCount: 16)
        var upperHalf: UInt16

        @mask(bitCount: 16)
        var lowerHalf: UInt16
    }

    @Test("Two 16-bit halves round-trip")
    func twoHalvesRoundTrip() throws {
        let originalData = Data([0x12, 0x34, 0x56, 0x78])
        let parsed = try TwoHalves(bits: 0x1234_5678)
        #expect(parsed == TwoHalves(upperHalf: 0x1234, lowerHalf: 0x5678))
        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == originalData)
    }

    /// Single 3-bit field (minimal non-byte-aligned)
    @ParseBitmask
    struct ThreeBitField: Equatable {
        typealias RawBitsInteger = UInt8

        @mask(bitCount: 3)
        var value: UInt8
    }

    @Test("Single 3-bit field round-trip")
    func threeBitFieldRoundTrip() throws {
        // 101 00000 = 0xA0 (MSB-aligned in 8-bit)
        let originalData = Data([0b1010_0000])
        let parsed = try ThreeBitField(bits: 0b1010_0000)
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
        typealias RawBitsInteger = UInt32

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
        let parsed = try TwentyFourBits(bits: 0xABCD_EF00)
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
        typealias RawBitsInteger = UInt8

        @mask(bitCount: 3)
        var high: UInt8

        @mask(bitCount: 4)
        var low: UInt8
    }

    @Test("7-bit bitmask round-trip")
    func sevenBitsRoundTrip() throws {
        // 101 0110 0 = 0xAC (MSB-aligned in 8-bit, with trailing 0 padding)
        let originalData = Data([0b1010_1100])
        let parsed = try SevenBits(bits: 0b1010_1100)
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
        typealias RawBitsInteger = UInt16

        @mask(bitCount: 4)
        var high: UInt8

        @mask(bitCount: 5)
        var low: UInt8
    }

    @Test("9-bit bitmask round-trip")
    func nineBitsRoundTrip() throws {
        // 1010 10110 0000000 = 0xAB00 (MSB-aligned in 16-bit, with trailing padding)
        let originalData = Data([0b1010_1011, 0b0000_0000])
        let parsed = try NineBits(bits: 0b1010_1011_0000_0000)
        #expect(parsed == NineBits(high: 0b1010, low: 0b10110))
        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == originalData)
    }

    @Test("NineBits bitCount is correct")
    func nineBitsBitCount() {
        #expect(NineBits.bitCount == 9)
    }

    // MARK: - Padding Normalization Tests (output has clean padding bits)

    @Test("Non-byte-aligned bitmask produces clean padding")
    func nonByteAlignedCleanPadding() throws {
        // 10 bits: 101 01100 11
        // MSB-aligned in 16-bit: 10101100 11000000 = 0xACC0
        // Output: 10101100 11000000 (padding bits are 0s)
        let parsed = try NonByteAligned(bits: 0b1010_1100_1100_0000)
        #expect(parsed == NonByteAligned(first: 0b101, second: 0b01100, third: 0b11))
        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == Data([0b1010_1100, 0b1100_0000]))
    }

    @Test("13-bit bitmask produces clean padding")
    func thirteenBitCleanPadding() throws {
        // 13 bits: 10101 1100 0011
        // MSB-aligned in 16-bit: 10101110 00011000 = 0xAE18
        // Output: 10101110 00011000 (padding: 000)
        let parsed = try ThirteenBitMask(bits: 0b1010_1110_0001_1000)
        #expect(parsed == ThirteenBitMask(highBits: 0b10101, middleBits: 0b1100, lowBits: 0b0011))
        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == Data([0b1010_1110, 0b0001_1000]))
    }

    @Test("3-bit field produces clean padding")
    func threeBitCleanPadding() throws {
        // 3 bits: 101
        // MSB-aligned in 8-bit: 10100000
        // Output: 10100000
        let parsed = try ThreeBitField(bits: 0b1010_0000)
        #expect(parsed == ThreeBitField(value: 0b101))
        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == Data([0b1010_0000]))
    }

    @Test("7-bit bitmask produces clean padding")
    func sevenBitCleanPadding() throws {
        // 7 bits: 101 0110
        // MSB-aligned in 8-bit: 10101100
        // Output: 10101100
        let parsed = try SevenBits(bits: 0b1010_1100)
        #expect(parsed == SevenBits(high: 0b101, low: 0b0110))
        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == Data([0b1010_1100]))
    }

    @Test("9-bit bitmask produces clean padding")
    func nineBitCleanPadding() throws {
        // 9 bits: 1010 10110
        // MSB-aligned in 16-bit: 10101011 00000000 = 0xAB00
        // Output: 10101011 00000000
        let parsed = try NineBits(bits: 0b1010_1011_0000_0000)
        #expect(parsed == NineBits(high: 0b1010, low: 0b10110))
        let printedBytes = try parsed.printParsed(printer: .data)
        #expect(printedBytes == Data([0b1010_1011, 0b0000_0000]))
    }

    @Test("28-bit asymmetric produces clean padding")
    func asymmetricCleanPadding() throws {
        // 28 bits with 4 padding bits
        // MSB-aligned in 32-bit: 11110101 10011110 10101010 10100000 = 0xF59EAAA0
        // Output should have padding bits = 0000
        let parsed = try AsymmetricBitWidths(bits: 0b1111_0101_1001_1110_1010_1010_1010_0000)
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

    @ParseBitmask
    struct OverflowBits {
        typealias RawBitsInteger = UInt8

        @mask(bitCount: 5)
        var first: UInt8

        @mask(bitCount: 4)
        var second: UInt8
    }

    @Test("Throws unsupportedBitCount when bits exceed storage")
    func throwsUnsupportedBitCount() {
        // Total bits = 9, RawBitsInteger = UInt8 (8 bits)
        #expect(throws: BitmaskParsableError.rawBitsIntegerNotWideEnough) {
            try OverflowBits(bits: 0)
        }
    }
}
