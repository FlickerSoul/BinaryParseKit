//
//  NonByteAlignedBitmask.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 1/6/26.
//

import BinaryParseKit
import BinaryParsing
import Foundation

@ParseBitmask
public struct NonByteAlignedBitmask: Equatable, Sendable, BaselineParsable {
    public typealias RawBitsInteger = UInt16

    @mask(bitCount: 3)
    public var first: UInt8

    @mask(bitCount: 5)
    public var second: UInt8

    @mask(bitCount: 2)
    public var third: UInt8

    public init(first: UInt8, second: UInt8, third: UInt8) {
        self.first = first
        self.second = second
        self.third = third
    }

    /// Baseline parsing - direct 10-bit extraction without bound checking
    @inline(__always)
    public static func parseBaseline(_ data: Data) -> NonByteAlignedBitmask {
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
