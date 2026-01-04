//
//  ExpressibleByRawBits+.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 12/30/25.
//

import Foundation

// MARK: - Bool Conformance

extension Bool: ExpressibleByRawBits {
    public init(bits: RawBits) throws {
        if bits.size == 0 {
            throw BitmaskParsableError.unsupportedBitCount
        } else {
            self = bits.bit(at: 0)
        }
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
    public init(bits: RawBits) throws {
        if bits.size == 0 {
            throw BitmaskParsableError.unsupportedBitCount
        } else {
            self = bits.extractBits(from: 0, count: Swift.min(bits.size, 8))
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
    public init(bits: RawBits) throws {
        if bits.size == 0 {
            throw BitmaskParsableError.unsupportedBitCount
        } else {
            self = Int8(bitPattern: bits.extractBits(from: 0, count: Swift.min(bits.size, 8)))
        }
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
