//
//  TestRawBits.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 12/30/25.
//

import BinaryParseKit
import Foundation
import Testing

// MARK: - RawBits Tests

@Suite
struct RawBitsTests {
    @Suite
    struct Initialization {
        @Test("RawBits initialization with 10 bits")
        func initWith10Bits() {
            let data = Data([0b1101_0011, 0b1000_0000]) // 16 bits available, using 10
            let bits = RawBits(data: data, size: 10)

            #expect(bits.size == 10)
            #expect(bits.byteCount == 2)
        }

        @Test
        func `initialize RawBits with tail trimming`() {
            let data = Data([0b1101_0011, 0xFF]) // 16 bits available, using 10
            let bits = RawBits(data: data, size: 10)

            #expect(bits.size == 10)
            #expect(bits.byteCount == 2)

            #expect(bits.data == Data([0b1101_0011, 0b1100_0000]))
        }

        @Test("Normalization trims excess bytes")
        func normalizationTrimsExcessBytes() {
            // 3 bytes provided, but only need 1 for 5 bits
            let data = Data([0b1101_0011, 0xFF, 0xFF])
            let bits = RawBits(data: data, size: 5)

            #expect(bits.size == 5)
            #expect(bits.byteCount == 1)
            #expect(bits.data.count == 1)
            #expect(bits.data == Data([0b1101_0000])) // Last 3 bits zeroed
        }

        @Test("Normalization with exact byte boundary")
        func normalizationExactByteBoundary() {
            // Exactly 8 bits - no partial byte
            let data = Data([0b1010_1010, 0xFF])
            let bits = RawBits(data: data, size: 8)

            #expect(bits.size == 8)
            #expect(bits.byteCount == 1)
            #expect(bits.data.count == 1)
            #expect(bits.data == Data([0b1010_1010])) // No masking needed, second byte trimmed
        }

        @Test("Normalization with single bit")
        func normalizationSingleBit() {
            let data = Data([0b0111_1111])
            let bits = RawBits(data: data, size: 1)

            #expect(bits.size == 1)
            #expect(bits.byteCount == 1)
            #expect(bits.data == Data([0b0000_0000])) // Only MSB matters, and it's 0
        }

        @Test("Normalization preserves valid bits")
        func normalizationPreservesValidBits() {
            // 12 bits: first byte + 4 bits of second byte
            let data = Data([0b1010_1010, 0b1111_0000])
            let bits = RawBits(data: data, size: 12)

            #expect(bits.size == 12)
            #expect(bits.byteCount == 2)
            #expect(bits.data == Data([0b1010_1010, 0b1111_0000])) // All bits are valid

            // Now with garbage in the last nibble
            let data2 = Data([0b1010_1010, 0b1111_1111])
            let bits2 = RawBits(data: data2, size: 12)

            #expect(bits2.data == Data([0b1010_1010, 0b1111_0000])) // Last 4 bits zeroed
        }

        @Test("RawBits initialization with 100 bits")
        func initWith100Bits() {
            let data = Data(repeating: 0xFF, count: 13) // 104 bits available
            let bits = RawBits(data: data, size: 100)

            #expect(bits.size == 100)
            #expect(bits.byteCount == 13)
        }

        @Test("RawBits from full Data")
        func initFromFullData() {
            let data = Data([0x12, 0x34])
            let bits = RawBits(data: data)

            #expect(bits.size == 16)
            #expect(bits.byteCount == 2)
        }

        @Test("Empty RawBits")
        func emptyRawBits() {
            let bits = RawBits()

            #expect(bits.size == 0)
            #expect(bits.byteCount == 0)
        }
    }

    @Suite("Bit Extraction")
    struct BitExtraction {
        @Test("Extract single bit MSB-first")
        func extractSingleBit() {
            // 0b11010011 -> MSB-first: bit 0 = 1, bit 1 = 1, bit 2 = 0, bit 3 = 1, etc.
            let data = Data([0b1101_0011])
            let bits = RawBits(data: data, size: 8)

            #expect(bits.bit(at: 0) == true) // MSB = 1
            #expect(bits.bit(at: 1) == true) // 1
            #expect(bits.bit(at: 2) == false) // 0
            #expect(bits.bit(at: 3) == true) // 1
            #expect(bits.bit(at: 4) == false) // 0
            #expect(bits.bit(at: 5) == false) // 0
            #expect(bits.bit(at: 6) == true) // 1
            #expect(bits.bit(at: 7) == true) // LSB = 1
        }

        @Test("Extract bits as UInt64")
        func extractBitsAsUInt64() {
            // 0b11010011 (0xD3)
            let data = Data([0b1101_0011])
            let bits = RawBits(data: data, size: 8)

            // Extract first 4 bits: 0b1101 = 13
            let first4 = bits.extractBits(from: 0, count: 4)
            #expect(first4 == 13)

            // Extract last 4 bits: 0b0011 = 3
            let last4 = bits.extractBits(from: 4, count: 4)
            #expect(last4 == 3)

            // Extract middle 4 bits (2-5): 0b0100 = 4
            let middle4 = bits.extractBits(from: 2, count: 4)
            #expect(middle4 == 4)
        }

        @Test("MSB-first bit extraction per spec")
        func msbFirstBitExtraction() {
            // Spec scenario: byte 0b11010011
            // Field A: 2 bits = 0b11 = 3
            // Field B: 4 bits = 0b0100 = 4
            // Field C: 2 bits = 0b11 = 3
            let data = Data([0b1101_0011])
            let bits = RawBits(data: data, size: 8)

            let fieldA = bits.extractBits(from: 0, count: 2)
            let fieldB = bits.extractBits(from: 2, count: 4)
            let fieldC = bits.extractBits(from: 6, count: 2)

            #expect(fieldA == 3)
            #expect(fieldB == 4)
            #expect(fieldC == 3)
        }
    }

    @Suite("Slicing")
    struct Slicing {
        @Test("Slice extraction from middle")
        func sliceFromMiddle() {
            // 0b1010110011001010 spread across 2 bytes
            let data = Data([0b1010_1100, 0b1100_1010])
            let bits = RawBits(data: data, size: 16)

            // Slice bits 4-11 (8 bits)
            let slice = bits.slice(from: 4, count: 8)
            #expect(slice.size == 8)
        }

        @Test("Slice from beginning")
        func sliceFromBeginning() {
            let data = Data([0b1111_0000, 0b0000_1111])
            let bits = RawBits(data: data, size: 10)

            // Slice first 4 bits
            let slice = bits.slice(from: 0, count: 4)
            #expect(slice.size == 4)
        }

        @Test("Empty slice")
        func emptySlice() {
            let data = Data([0xFF])
            let bits = RawBits(data: data, size: 8)

            let slice = bits.slice(from: 4, count: 0)
            #expect(slice.size == 0)
        }

        @Test("Slice with proper normalization - issue example")
        func sliceWithNormalization() {
            // Test case from issue:
            // RawBits(data = 01010101, size = 8) with slice [1, 2)
            // Should produce RawBits(data = 10000000, size = 1)
            let data = Data([0b0101_0101])
            let bits = RawBits(data: data, size: 8)

            // Slice from index 1, count 1 (which is [1, 2) in range notation)
            let sliced = bits.slice(from: 1, count: 1)

            #expect(sliced.size == 1)
            #expect(sliced.data[0] == 0b1000_0000)
            #expect(sliced.bit(at: 0) == true) // bit 1 from original was '1'
        }

        @Test("Slice realigns bits to MSB")
        func sliceRealignsBitsToMSB() {
            // Original: 0b11110000
            // Slice bits [4, 8) -> last 4 bits are 0b0000
            let data = Data([0b1111_0000])
            let bits = RawBits(data: data, size: 8)

            let sliced = bits.slice(from: 4, count: 4)

            #expect(sliced.size == 4)
            #expect(sliced.data[0] == 0b0000_0000) // 0b0000 aligned to MSB
        }

        @Test("Slice with unaligned multi-byte")
        func sliceUnalignedMultiByte() {
            // Original: 0b10101010 11001100
            // Slice bits [3, 13) -> 10 bits starting from bit 3
            // Bits 3-7 from byte 0: 01010
            // Bits 8-12 from byte 1: 11001
            // Result: 0b01010 11001 -> 0b01010110 01000000
            let data = Data([0b1010_1010, 0b1100_1100])
            let bits = RawBits(data: data, size: 16)

            let sliced = bits.slice(from: 3, count: 10)

            #expect(sliced.size == 10)
            #expect(sliced.data.count == 2)
            // Expected: 01010110 01000000
            #expect(sliced.data[0] == 0b0101_0110)
            #expect(sliced.data[1] == 0b0100_0000)
        }

        @Test("Slice single bit from different positions")
        func sliceSingleBitFromDifferentPositions() {
            let data = Data([0b1011_0100])
            let bits = RawBits(data: data, size: 8)

            // Bit 0 (MSB) = 1
            let bit0 = bits.slice(from: 0, count: 1)
            #expect(bit0.data[0] == 0b1000_0000)

            // Bit 2 = 1
            let bit2 = bits.slice(from: 2, count: 1)
            #expect(bit2.data[0] == 0b1000_0000)

            // Bit 3 = 1
            let bit3 = bits.slice(from: 3, count: 1)
            #expect(bit3.data[0] == 0b1000_0000)

            // Bit 5 = 1
            let bit5 = bits.slice(from: 5, count: 1)
            #expect(bit5.data[0] == 0b1000_0000)

            // Bit 1 = 0
            let bit1 = bits.slice(from: 1, count: 1)
            #expect(bit1.data[0] == 0b0000_0000)
        }

        @Test("Slice preserves bit values across byte boundaries")
        func slicePreservesBitValuesAcrossBoundaries() {
            // Create a pattern that spans multiple bytes
            let data = Data([0b1111_0000, 0b1010_1010, 0b0000_1111])
            let bits = RawBits(data: data, size: 24)

            // Slice middle byte plus some bits from neighbors
            // From bit 6 to bit 18 (12 bits)
            let sliced = bits.slice(from: 6, count: 12)

            #expect(sliced.size == 12)

            // Verify each bit matches the original
            for i in 0 ..< 12 {
                #expect(sliced.bit(at: i) == bits.bit(at: 6 + i))
            }
        }

        @Test("Slice result is properly normalized")
        func sliceResultIsNormalized() {
            // Verify that sliced data has trailing bits zeroed
            let data = Data([0b1111_1111])
            let bits = RawBits(data: data, size: 8)

            // Slice 3 bits from the middle
            let sliced = bits.slice(from: 2, count: 3)

            #expect(sliced.size == 3)
            #expect(sliced.data.count == 1)
            // 3 bits: 111, aligned to MSB: 11100000
            #expect(sliced.data[0] == 0b1110_0000)
        }
    }

    @Suite("Equality")
    struct Equality {
        @Test("Equal RawBits")
        func equalRawBits() {
            let data1 = Data([0xAB, 0xCD])
            let data2 = Data([0xAB, 0xCD])

            let bits1 = RawBits(data: data1, size: 16)
            let bits2 = RawBits(data: data2, size: 16)

            #expect(bits1 == bits2)
        }

        @Test("Different size inequality")
        func differentSizeInequality() {
            let data = Data([0xAB, 0xCD])

            let bits1 = RawBits(data: data, size: 16)
            let bits2 = RawBits(data: data, size: 8)

            #expect(bits1 != bits2)
        }

        @Test("Partial byte equality")
        func partialByteEquality() {
            // Only first 4 bits should matter
            let data1 = Data([0b1111_0000])
            let data2 = Data([0b1111_1111])

            let bits1 = RawBits(data: data1, size: 4)
            let bits2 = RawBits(data: data2, size: 4)

            #expect(bits1 == bits2)
        }
    }

    @Suite("Slice Equality with Offset")
    struct SliceEqualityWithOffset {
        @Test("Slice equality match at offset 0")
        func sliceEqualityMatchAtOffset0() {
            let dataA = Data([0b1111_0000])
            let dataB = Data([0b1111_0000])

            let bitsA = RawBits(data: dataA, size: 8)
            let bitsB = RawBits(data: dataB, size: 4)

            #expect(bitsA.sliceEquals(bitsB, at: 0) == true)
        }

        @Test("Slice equality mismatch at offset 4")
        func sliceEqualityMismatchAtOffset4() {
            let dataA = Data([0b1111_0000])
            let dataB = Data([0b1111_0000])

            let bitsA = RawBits(data: dataA, size: 8)
            let bitsB = RawBits(data: dataB, size: 4)

            // At offset 4, bitsA has 0b0000, bitsB has 0b1111
            #expect(bitsA.sliceEquals(bitsB, at: 4) == false)
        }
    }

    @Suite("Bitwise Operations")
    struct BitwiseOperations {
        @Test("Bitwise AND")
        func bitwiseAnd() {
            let dataA = Data([0b1010_0000])
            let dataB = Data([0b1100_0000])

            let bitsA = RawBits(data: dataA, size: 4)
            let bitsB = RawBits(data: dataB, size: 4)

            let result = bitsA & bitsB
            // 0b1010 & 0b1100 = 0b1000
            #expect(result == [0b1000_0000])
        }

        @Test("Bitwise OR")
        func bitwiseOr() {
            let dataA = Data([0b1010_0000])
            let dataB = Data([0b1100_0000])

            let bitsA = RawBits(data: dataA, size: 4)
            let bitsB = RawBits(data: dataB, size: 4)

            let result = bitsA | bitsB
            // 0b1010 | 0b1100 = 0b1110
            #expect(result == [0b1110_0000])
        }

        @Test("Bitwise XOR")
        func bitwiseXor() {
            let dataA = Data([0b1010_0000])
            let dataB = Data([0b1100_0000])

            let bitsA = RawBits(data: dataA, size: 4)
            let bitsB = RawBits(data: dataB, size: 4)

            let result = bitsA ^ bitsB
            // 0b1010 ^ 0b1100 = 0b0110
            #expect(result == [0b0110_0000])
        }

        @Test("Bitwise AND with different sizes")
        func bitwiseAndDifferentSizes() {
            let dataA = Data([0xFF])
            let dataB = Data([0b1111_0000])

            let bitsA = RawBits(data: dataA, size: 8)
            let bitsB = RawBits(data: dataB, size: 4)

            let result = bitsA & bitsB
            // Result size is minimum (4 bits)
            #expect(result.count == 1)
        }
    }
}
