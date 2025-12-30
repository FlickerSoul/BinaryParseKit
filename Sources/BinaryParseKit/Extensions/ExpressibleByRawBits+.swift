//
//  ExpressibleByRawBits+.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 12/30/25.
//

// MARK: - Bool Conformance

extension Bool: ExpressibleByRawBits {
    public init(bits: RawBits) throws {
        guard bits.size >= 1 else {
            throw BitmaskParsableError.insufficientBits
        }
        self = bits.bit(at: 0)
    }
}

// MARK: - Integer Conformances

extension UInt8: ExpressibleByRawBits {
    public init(bits: RawBits) throws {
        guard bits.size <= 8 else {
            throw BitmaskParsableError.unsupportedBitCount
        }
        self = UInt8(bits.extractBits(from: 0, count: bits.size))
    }
}

extension UInt16: ExpressibleByRawBits {
    public init(bits: RawBits) throws {
        guard bits.size <= 16 else {
            throw BitmaskParsableError.unsupportedBitCount
        }
        self = UInt16(bits.extractBits(from: 0, count: bits.size))
    }
}

extension UInt32: ExpressibleByRawBits {
    public init(bits: RawBits) throws {
        guard bits.size <= 32 else {
            throw BitmaskParsableError.unsupportedBitCount
        }
        self = UInt32(bits.extractBits(from: 0, count: bits.size))
    }
}

extension UInt64: ExpressibleByRawBits {
    public init(bits: RawBits) throws {
        guard bits.size <= 64 else {
            throw BitmaskParsableError.unsupportedBitCount
        }
        self = bits.extractBits(from: 0, count: bits.size)
    }
}

extension Int8: ExpressibleByRawBits {
    public init(bits: RawBits) throws {
        guard bits.size <= 8 else {
            throw BitmaskParsableError.unsupportedBitCount
        }
        self = Int8(bitPattern: UInt8(bits.extractBits(from: 0, count: bits.size)))
    }
}

extension Int16: ExpressibleByRawBits {
    public init(bits: RawBits) throws {
        guard bits.size <= 16 else {
            throw BitmaskParsableError.unsupportedBitCount
        }
        self = Int16(bitPattern: UInt16(bits.extractBits(from: 0, count: bits.size)))
    }
}

extension Int32: ExpressibleByRawBits {
    public init(bits: RawBits) throws {
        guard bits.size <= 32 else {
            throw BitmaskParsableError.unsupportedBitCount
        }
        self = Int32(bitPattern: UInt32(bits.extractBits(from: 0, count: bits.size)))
    }
}

extension Int64: ExpressibleByRawBits {
    public init(bits: RawBits) throws {
        guard bits.size <= 64 else {
            throw BitmaskParsableError.unsupportedBitCount
        }
        self = Int64(bitPattern: bits.extractBits(from: 0, count: bits.size))
    }
}
