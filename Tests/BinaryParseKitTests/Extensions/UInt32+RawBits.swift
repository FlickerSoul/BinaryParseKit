//
//  UInt32+RawBits.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 12/29/25.
//

import BinaryParseKit
import BinaryParsing
import Foundation

extension UInt32: ExpressibleByRawBits {
    public typealias RawBitsInteger = UInt32

    public init(bits: RawBitsInteger) throws {
        self = bits
    }
}

extension UInt32: RawBitsConvertible {
    public func toRawBits(bitCount: Int) throws -> RawBits {
        // Left-align the value within 32 bits, then convert to big-endian bytes
        // e.g., value=0x12345 with bitCount=20 -> shift left by 12 -> 0x12345000
        let effectiveBits = Swift.min(bitCount, 32)
        let shifted = self << (32 - effectiveBits)
        return RawBits(data: withUnsafeBytes(of: shifted.bigEndian) { Data($0) }, size: bitCount)
    }
}
