//
//  Types.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 1/6/26.
//
import BenchmarkCommons
import BinaryParseKit
import BinaryParsing
import Foundation

// MARK: - Test Types for Benchmarking

// Simple enum for parsing benchmarks
@ParseEnum
enum BenchmarkEnumSimple: Equatable {
    @match(byte: 0x01)
    case first

    @match(byte: 0x02)
    case second

    @match(byte: 0x03)
    case third

    /// Baseline parsing - direct byte match without bound checking
    @inline(__always)
    static func parseBaseline(_ data: Data) -> BenchmarkEnumSimple {
        let byte = data[data.startIndex]
        switch byte {
        case 0x01: return .first
        case 0x02: return .second
        case 0x03: return .third
        default: fatalError("Invalid byte")
        }
    }
}

// Complex enum with associated values
@ParseEnum
enum BenchmarkEnumComplex: Equatable {
    @matchAndTake(byte: 0x01)
    @parse(endianness: .big)
    case withInt16(Int16)

    @matchAndTake(byte: 0x02)
    @parse(endianness: .big)
    case withUInt32(UInt32)

    @matchAndTake(byte: 0x03)
    @parse(endianness: .big)
    @parse(endianness: .big)
    case withTwoValues(Int16, UInt16)

    @matchDefault
    case unknown

    /// Baseline parsing - direct parsing without bound checking
    @inline(__always)
    static func parseBaseline(_ data: Data) -> BenchmarkEnumComplex {
        let byte = data[data.startIndex]
        switch byte {
        case 0x01:
            let value = Int16(bigEndian: data.withUnsafeBytes { $0.load(fromByteOffset: 1, as: Int16.self) })
            return .withInt16(value)
        case 0x02:
            let value = UInt32(bigEndian: data.withUnsafeBytes { $0.load(fromByteOffset: 1, as: UInt32.self) })
            return .withUInt32(value)
        case 0x03:
            let arg1 = Int16(bigEndian: data.withUnsafeBytes { $0.load(fromByteOffset: 1, as: Int16.self) })
            let arg2 = UInt16(bigEndian: data.withUnsafeBytes { $0.load(fromByteOffset: 3, as: UInt16.self) })
            return .withTwoValues(arg1, arg2)
        default:
            return .unknown
        }
    }
}

// Simple struct for parsing benchmarks
@ParseStruct
struct BenchmarkStructSimple: Equatable {
    @parse(endianness: .big)
    let value: UInt32

    /// Baseline parsing - direct UInt32 big-endian without bound checking
    @inline(__always)
    static func parseBaseline(_ data: Data) -> BenchmarkStructSimple {
        let value = UInt32(bigEndian: data.withUnsafeBytes { $0.load(as: UInt32.self) })
        return BenchmarkStructSimple(value: value)
    }
}

// Complex struct with multiple fields
@ParseStruct
struct BenchmarkStructComplex: Equatable {
    @parse(byteCount: 4, endianness: .big)
    let magic: UInt32

    @skip(byteCount: 2, because: "reserved")
    @parse(byteCount: 2, endianness: .little)
    let version: UInt16

    @parse(endianness: .big)
    let timestamp: UInt64

    @parse(endianness: .little)
    let flags: UInt16

    /// Baseline parsing - direct multi-field parsing without bound checking
    @inline(__always)
    static func parseBaseline(_ data: Data) -> BenchmarkStructComplex {
        data.withUnsafeBytes { ptr in
            let magic = UInt32(bigEndian: ptr.load(fromByteOffset: 0, as: UInt32.self))
            // Skip 2 bytes at offset 4-5
            let version = UInt16(littleEndian: ptr.load(fromByteOffset: 6, as: UInt16.self))
            let timestamp = UInt64(bigEndian: ptr.load(fromByteOffset: 8, as: UInt64.self))
            let flags = UInt16(littleEndian: ptr.load(fromByteOffset: 16, as: UInt16.self))
            return BenchmarkStructComplex(magic: magic, version: version, timestamp: timestamp, flags: flags)
        }
    }
}

// Simple bitmask for parsing benchmarks
@ParseBitmask
struct BenchmarkBitmaskSimple: Equatable {
    typealias RawBitsInteger = UInt8

    @mask(bitCount: 1)
    var flag: UInt8

    @mask(bitCount: 7)
    var value: UInt8

    /// Baseline parsing - direct bit extraction without bound checking
    @inline(__always)
    static func parseBaseline(_ data: Data) -> BenchmarkBitmaskSimple {
        let byte = data[data.startIndex]
        let flag = (byte >> 7) & 0x01
        let value = byte & 0x7F
        return BenchmarkBitmaskSimple(flag: flag, value: value)
    }
}

// Complex bitmask with multiple fields
@ParseBitmask
struct BenchmarkBitmaskComplex: Equatable {
    typealias RawBitsInteger = UInt32

    @mask(bitCount: 1)
    var flag1: UInt8

    @mask(bitCount: 3)
    var priority: UInt8

    @mask(bitCount: 4)
    var nibble: UInt8

    @mask(bitCount: 8)
    var byte: UInt8

    @mask(bitCount: 16)
    var word: UInt16

    /// Baseline parsing - direct 32-bit extraction without bound checking
    @inline(__always)
    static func parseBaseline(_ data: Data) -> BenchmarkBitmaskComplex {
        data.withUnsafeBytes { ptr in
            let bits = UInt32(bigEndian: ptr.load(as: UInt32.self))
            let flag1 = UInt8((bits >> 31) & 0x01)
            let priority = UInt8((bits >> 28) & 0x07)
            let nibble = UInt8((bits >> 24) & 0x0F)
            let byte = UInt8((bits >> 16) & 0xFF)
            let word = UInt16(bits & 0xFFFF)
            return BenchmarkBitmaskComplex(flag1: flag1, priority: priority, nibble: nibble, byte: byte, word: word)
        }
    }
}

@ParseStruct
struct BigEndianStruct: Equatable {
    @parse(endianness: .big)
    let value1: UInt32

    @parse(endianness: .big)
    let value2: UInt32

    /// Baseline parsing - direct big-endian parsing without bound checking
    @inline(__always)
    static func parseBaseline(_ data: Data) -> BigEndianStruct {
        data.withUnsafeBytes { ptr in
            let value1 = UInt32(bigEndian: ptr.load(fromByteOffset: 0, as: UInt32.self))
            let value2 = UInt32(bigEndian: ptr.load(fromByteOffset: 4, as: UInt32.self))
            return BigEndianStruct(value1: value1, value2: value2)
        }
    }
}

@ParseStruct
struct LittleEndianStruct: Equatable {
    @parse(endianness: .little)
    let value1: UInt32

    @parse(endianness: .little)
    let value2: UInt32

    /// Baseline parsing - direct little-endian parsing without bound checking
    @inline(__always)
    static func parseBaseline(_ data: Data) -> LittleEndianStruct {
        data.withUnsafeBytes { ptr in
            let value1 = UInt32(littleEndian: ptr.load(fromByteOffset: 0, as: UInt32.self))
            let value2 = UInt32(littleEndian: ptr.load(fromByteOffset: 4, as: UInt32.self))
            return LittleEndianStruct(value1: value1, value2: value2)
        }
    }
}

@ParseBitmask
struct NonByteAlignedBitmask: Equatable {
    typealias RawBitsInteger = UInt16

    @mask(bitCount: 3)
    var first: UInt8

    @mask(bitCount: 5)
    var second: UInt8

    @mask(bitCount: 2)
    var third: UInt8

    /// Baseline parsing - direct 10-bit extraction without bound checking
    @inline(__always)
    static func parseBaseline(_ data: Data) -> NonByteAlignedBitmask {
        data.withUnsafeBytes { ptr in
            let byte0 = ptr.load(fromByteOffset: 0, as: UInt8.self)
            let byte1 = ptr.load(fromByteOffset: 1, as: UInt8.self)
            // first: 3 bits from byte0 (bits 7-5)
            let first = (byte0 >> 5) & 0x07
            // second: 5 bits from byte0 (bits 4-0)
            let second = byte0 & 0x1F
            // third: 2 bits from byte1 (bits 7-6)
            let third = (byte1 >> 6) & 0x03
            return NonByteAlignedBitmask(first: first, second: second, third: third)
        }
    }
}
