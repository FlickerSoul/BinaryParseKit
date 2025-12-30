//
//  ExpressibleByRawBits+.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 12/30/25.
//

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

extension Int8: ExpressibleByRawBits {
    public init(bits: RawBits) throws {
        if bits.size == 0 {
            throw BitmaskParsableError.unsupportedBitCount
        } else {
            self = Int8(bitPattern: bits.extractBits(from: 0, count: Swift.min(bits.size, 8)))
        }
    }
}
