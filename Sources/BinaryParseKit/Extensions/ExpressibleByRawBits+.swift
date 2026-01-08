//
//  ExpressibleByRawBits+.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 12/30/25.
//

import Foundation

// MARK: - Bool Conformance

extension Bool: ExpressibleByRawBits {
    public init(bits: borrowing RawBitsSpan) throws {
        // Extract the first bit from the span
        precondition(bits.bitCount >= 1, "Bool requires at least 1 bit")
        let firstByte = unsafe bits._bytes.unsafeLoad(fromByteOffset: 0, as: UInt8.self)
        // Check the bit at bitOffset position (MSB-first)
        let mask: UInt8 = 0x80 >> bits.bitStartIndex
        self = (firstByte & mask) != 0
    }
}

extension Bool: RawBitsConvertible {
    public func toRawBits(bitCount: Int) throws -> RawBits {
        // For Bool, set the MSB of the first byte if true
        // e.g., true with bitCount=1 -> 0b10000000
        let byte: UInt8 = self ? (0x80 >> (bitCount - 1)) << (bitCount - 1) : 0
        return RawBits(data: Data([byte]), size: bitCount)
    }
}

// MARK: - Integer Conformances

extension UInt8: ExpressibleByRawBits {
    public init(bits: borrowing RawBitsSpan) throws {
        // Extract up to 8 bits from the span and convert to UInt8
        precondition(bits.bitCount <= 8, "UInt8 can hold at most 8 bits")

        if bits.bitCount == 0 {
            self = 0
            return
        }

        if bits.bitStartIndex + bits.bitCount <= 8 {
            // Single byte extraction
            let byte = unsafe bits._bytes.unsafeLoad(fromByteOffset: 0, as: UInt8.self)
            let shifted = byte << bits.bitStartIndex
            self = shifted >> (8 - bits.bitCount)
        } else {
            // Two byte extraction
            let highByte = unsafe bits._bytes.unsafeLoad(fromByteOffset: 0, as: UInt8.self)
            let lowByte = unsafe bits._bytes.unsafeLoad(fromByteOffset: 1, as: UInt8.self)
            let combined = (UInt16(highByte) << 8) | UInt16(lowByte)
            self = UInt8((combined << bits.bitStartIndex) >> (16 - bits.bitCount))
        }
    }
}

extension UInt8: RawBitsConvertible {
    public func toRawBits(bitCount: Int) throws -> RawBits {
        // Place value in MSB position
        // e.g., value=5 (0b101) with bitCount=3 -> 0b10100000
        let effectiveBits = Swift.min(bitCount, 8)
        let byte = self << (8 - effectiveBits)
        return RawBits(data: Data([byte]), size: bitCount)
    }
}

extension Int8: ExpressibleByRawBits {
    public init(bits: borrowing RawBitsSpan) throws {
        // Extract up to 8 bits from the span and convert to Int8
        let unsigned = try UInt8(bits: bits)
        self = Int8(bitPattern: unsigned)
    }
}

extension Int8: RawBitsConvertible {
    public func toRawBits(bitCount: Int) throws -> RawBits {
        // Place value in MSB position (same as UInt8, using bit pattern)
        let effectiveBits = Swift.min(bitCount, 8)
        let byte = UInt8(bitPattern: self) << (8 - effectiveBits)
        return RawBits(data: Data([byte]), size: bitCount)
    }
}
