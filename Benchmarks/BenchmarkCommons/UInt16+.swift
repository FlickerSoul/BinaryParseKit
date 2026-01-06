//
//  UInt16+.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 1/6/26.
//
import BinaryParseKit
import Foundation

extension UInt16: ExpressibleByRawBits, RawBitsConvertible {
    public init(bits: RawBits) throws {
        let data = if bits.data.count < 2 {
            bits.data + Data([UInt8](repeating: 0, count: 2 - bits.data.count))
        } else {
            bits.data
        }

        self = try data.withParserSpan { span in
            try UInt16(parsingBigEndian: &span)
        }
    }

    public func toRawBits(bitCount: Int) throws -> RawBits {
        RawBits(data: withUnsafeBytes(of: bigEndian) { Data($0) }, size: bitCount)
    }
}
