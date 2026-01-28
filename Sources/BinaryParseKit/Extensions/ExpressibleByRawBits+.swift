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
        precondition(bits.bitCount == 1, "Bool requires only 1 bit")
        let booleanInteger = bits.loadUnsafe(as: UInt8.self, bitCount: 1)
        assert(booleanInteger == 0 || booleanInteger == 1, "Bool raw bits must be 0 or 1")
        self = booleanInteger != 0
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
        self = try bits.load(as: UInt8.self)
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
