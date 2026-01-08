//
//  BenchmarkBitmaskSimple.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 1/6/26.
//

import BinaryParseKit
import BinaryParsing
import Foundation

@ParseBitmask
public struct BenchmarkBitmaskSimple: Equatable, Sendable, BaselineParsable {
    @mask(bitCount: 1)
    public var flag: UInt8

    @mask(bitCount: 7)
    public var value: UInt8

    public init(flag: UInt8, value: UInt8) {
        self.flag = flag
        self.value = value
    }

    /// Baseline parsing - direct bit extraction without bound checking
    @inline(__always)
    public static func parseBaseline(_ data: Data) -> BenchmarkBitmaskSimple {
        let byte = data[data.startIndex]
        let flag = (byte >> 7) & 0x01
        let value = byte & 0x7F
        return BenchmarkBitmaskSimple(flag: flag, value: value)
    }
}
