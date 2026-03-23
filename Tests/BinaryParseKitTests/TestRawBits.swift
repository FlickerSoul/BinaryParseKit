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
        @Test
        func `rawBits initialization with 10 bits`() {
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

        @Test
        func `normalization trims excess bytes`() {
            // 3 bytes provided, but only need 1 for 5 bits
            let data = Data([0b1101_0011, 0xFF, 0xFF])
            let bits = RawBits(data: data, size: 5)

            #expect(bits.size == 5)
            #expect(bits.byteCount == 1)
            #expect(bits.data.count == 1)
            #expect(bits.data == Data([0b1101_0000])) // Last 3 bits zeroed
        }

        @Test
        func `normalization with exact byte boundary`() {
            // Exactly 8 bits - no partial byte
            let data = Data([0b1010_1010, 0xFF])
            let bits = RawBits(data: data, size: 8)

            #expect(bits.size == 8)
            #expect(bits.byteCount == 1)
            #expect(bits.data.count == 1)
            #expect(bits.data == Data([0b1010_1010])) // No masking needed, second byte trimmed
        }

        @Test
        func `normalization with single bit`() {
            let data = Data([0b0111_1111])
            let bits = RawBits(data: data, size: 1)

            #expect(bits.size == 1)
            #expect(bits.byteCount == 1)
            #expect(bits.data == Data([0b0000_0000])) // Only MSB matters, and it's 0
        }

        @Test
        func `normalization preserves valid bits`() {
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

        @Test
        func `rawBits initialization with 100 bits`() {
            let data = Data(repeating: 0xFF, count: 13) // 104 bits available
            let bits = RawBits(data: data, size: 100)

            #expect(bits.size == 100)
            #expect(bits.byteCount == 13)
        }

        @Test
        func `rawBits from full Data`() {
            let data = Data([0x12, 0x34])
            let bits = RawBits(data: data)

            #expect(bits.size == 16)
            #expect(bits.byteCount == 2)
        }

        @Test
        func `empty RawBits`() {
            let bits = RawBits()

            #expect(bits.size == 0)
            #expect(bits.byteCount == 0)
        }
    }

    struct Equality {
        @Test
        func `equal RawBits`() {
            let data1 = Data([0xAB, 0xCD])
            let data2 = Data([0xAB, 0xCD])

            let bits1 = RawBits(data: data1, size: 16)
            let bits2 = RawBits(data: data2, size: 16)

            #expect(bits1 == bits2)
        }

        @Test
        func `different size inequality`() {
            let data = Data([0xAB, 0xCD])

            let bits1 = RawBits(data: data, size: 16)
            let bits2 = RawBits(data: data, size: 8)

            #expect(bits1 != bits2)
        }

        @Test
        func `partial byte equality`() {
            // Only first 4 bits should matter
            let data1 = Data([0b1111_0000])
            let data2 = Data([0b1111_1111])

            let bits1 = RawBits(data: data1, size: 4)
            let bits2 = RawBits(data: data2, size: 4)

            #expect(bits1 == bits2)
        }
    }
}
