//
//  UInt16+RawBits.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 12/29/25.
//

import BinaryParseKit
import BinaryParsing
import Foundation

extension UInt16: ExpressibleByRawBits {
    public init(bits: borrowing RawBitsSpan) throws {
        self = try bits.load(as: Self.self)
    }
}

extension UInt16: RawBitsConvertible {
    public func toRawBits(bitCount: Int) throws -> RawBits {
        // Left-align the value within 16 bits, then convert to big-endian bytes
        // e.g., value=0xAB3 with bitCount=12 -> shift left by 4 -> 0xAB30
        let effectiveBits = Swift.min(bitCount, 16)
        let shifted = self << (16 - effectiveBits)
        return RawBits(data: withUnsafeBytes(of: shifted.bigEndian) { Data($0) }, size: bitCount)
    }
}
