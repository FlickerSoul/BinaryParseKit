//
//  BenchmarkBitmaskComplex.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 1/6/26.
//

import BinaryParseKit
import BinaryParsing
import Foundation

@ParseBitmask
public struct BenchmarkBitmaskComplex: Equatable, Sendable, BaselineParsable {
    @mask(bitCount: 1)
    public var flag1: UInt8

    @mask(bitCount: 3)
    public var priority: UInt8

    @mask(bitCount: 4)
    public var nibble: UInt8

    @mask(bitCount: 8)
    public var byte: UInt8

    @mask(bitCount: 16)
    public var word: UInt16

    public init(flag1: UInt8, priority: UInt8, nibble: UInt8, byte: UInt8, word: UInt16) {
        self.flag1 = flag1
        self.priority = priority
        self.nibble = nibble
        self.byte = byte
        self.word = word
    }

    /// Baseline parsing - direct 32-bit extraction without bound checking
    @inline(__always)
    public static func parseBaseline(_ data: Data) -> BenchmarkBitmaskComplex {
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
