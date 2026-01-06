//
//  Types.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 1/6/26.
//
import BenchmarkCommons
import BinaryParseKit
import BinaryParsing

// MARK: - Test Types for Benchmarking

// Simple enum for printing benchmarks
@ParseEnum
enum PrintBenchmarkEnumSimple: Equatable {
    @match(byte: 0x01)
    case first

    @match(byte: 0x02)
    case second

    @match(byte: 0x03)
    case third
}

// Complex enum with associated values
@ParseEnum
enum PrintBenchmarkEnumComplex: Equatable {
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
}

// Simple struct for printing benchmarks
@ParseStruct
struct PrintBenchmarkStructSimple: Equatable {
    @parse(endianness: .big)
    let value: UInt32
}

// Complex struct with multiple fields
@ParseStruct
struct PrintBenchmarkStructComplex: Equatable {
    @parse(byteCount: 4, endianness: .big)
    let magic: UInt32

    @skip(byteCount: 2, because: "reserved")
    @parse(byteCount: 2, endianness: .little)
    let version: UInt16

    @parse(endianness: .big)
    let timestamp: UInt64

    @parse(endianness: .little)
    let flags: UInt16
}

// Simple bitmask for printing benchmarks
@ParseBitmask
struct PrintBenchmarkBitmaskSimple: Equatable {
    @mask(bitCount: 1)
    var flag: UInt8

    @mask(bitCount: 7)
    var value: UInt8
}

// Complex bitmask with multiple fields
@ParseBitmask
struct PrintBenchmarkBitmaskComplex: Equatable {
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
}

@ParseBitmask
struct NonByteAlignedPrintBitmask: Equatable {
    @mask(bitCount: 3)
    var first: UInt8

    @mask(bitCount: 5)
    var second: UInt8

    @mask(bitCount: 2)
    var third: UInt8
}
