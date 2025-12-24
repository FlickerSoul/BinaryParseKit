//
//  ExpressibleByRawBitsExtensions.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 12/24/25.
//

import BinaryParsing

// MARK: - Unsigned Integer Extensions

extension UInt8: ExpressibleByRawBits {
    public init(from bits: borrowing RawBits) throws {
        guard bits.size >= 1 else {
            throw BitmaskParsableError.insufficientBits(required: 1, available: bits.size)
        }
        let value = bits.extractBits(from: 0, count: Swift.min(bits.size, 8))
        self = UInt8(truncatingIfNeeded: value)
    }
}

extension UInt16: ExpressibleByRawBits {
    public init(from bits: borrowing RawBits) throws {
        guard bits.size >= 1 else {
            throw BitmaskParsableError.insufficientBits(required: 1, available: bits.size)
        }
        let value = bits.extractBits(from: 0, count: Swift.min(bits.size, 16))
        self = UInt16(truncatingIfNeeded: value)
    }
}

extension UInt32: ExpressibleByRawBits {
    public init(from bits: borrowing RawBits) throws {
        guard bits.size >= 1 else {
            throw BitmaskParsableError.insufficientBits(required: 1, available: bits.size)
        }
        let value = bits.extractBits(from: 0, count: Swift.min(bits.size, 32))
        self = UInt32(truncatingIfNeeded: value)
    }
}

extension UInt64: ExpressibleByRawBits {
    public init(from bits: borrowing RawBits) throws {
        guard bits.size >= 1 else {
            throw BitmaskParsableError.insufficientBits(required: 1, available: bits.size)
        }
        let value = bits.extractBits(from: 0, count: Swift.min(bits.size, 64))
        self = value
    }
}

extension UInt: ExpressibleByRawBits {
    public init(from bits: borrowing RawBits) throws {
        guard bits.size >= 1 else {
            throw BitmaskParsableError.insufficientBits(required: 1, available: bits.size)
        }
        let value = bits.extractBits(from: 0, count: Swift.min(bits.size, UInt.bitWidth))
        self = UInt(truncatingIfNeeded: value)
    }
}

// MARK: - Signed Integer Extensions

extension Int8: ExpressibleByRawBits {
    public init(from bits: borrowing RawBits) throws {
        guard bits.size >= 1 else {
            throw BitmaskParsableError.insufficientBits(required: 1, available: bits.size)
        }
        let value = bits.extractBits(from: 0, count: Swift.min(bits.size, 8))
        self = Int8(bitPattern: UInt8(truncatingIfNeeded: value))
    }
}

extension Int16: ExpressibleByRawBits {
    public init(from bits: borrowing RawBits) throws {
        guard bits.size >= 1 else {
            throw BitmaskParsableError.insufficientBits(required: 1, available: bits.size)
        }
        let value = bits.extractBits(from: 0, count: Swift.min(bits.size, 16))
        self = Int16(bitPattern: UInt16(truncatingIfNeeded: value))
    }
}

extension Int32: ExpressibleByRawBits {
    public init(from bits: borrowing RawBits) throws {
        guard bits.size >= 1 else {
            throw BitmaskParsableError.insufficientBits(required: 1, available: bits.size)
        }
        let value = bits.extractBits(from: 0, count: Swift.min(bits.size, 32))
        self = Int32(bitPattern: UInt32(truncatingIfNeeded: value))
    }
}

extension Int64: ExpressibleByRawBits {
    public init(from bits: borrowing RawBits) throws {
        guard bits.size >= 1 else {
            throw BitmaskParsableError.insufficientBits(required: 1, available: bits.size)
        }
        let value = bits.extractBits(from: 0, count: Swift.min(bits.size, 64))
        self = Int64(bitPattern: value)
    }
}

extension Int: ExpressibleByRawBits {
    public init(from bits: borrowing RawBits) throws {
        guard bits.size >= 1 else {
            throw BitmaskParsableError.insufficientBits(required: 1, available: bits.size)
        }
        let value = bits.extractBits(from: 0, count: Swift.min(bits.size, Int.bitWidth))
        self = Int(bitPattern: UInt(truncatingIfNeeded: value))
    }
}

// MARK: - Bool Extension

extension Bool: ExpressibleByRawBits {
    public init(from bits: borrowing RawBits) throws {
        guard bits.size >= 1 else {
            throw BitmaskParsableError.insufficientBits(required: 1, available: bits.size)
        }
        self = bits.bit(at: 0)
    }
}
