//
//  UInt32+RawBits.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 12/29/25.
//

import BinaryParseKit
import BinaryParsing
import Foundation

extension UInt32: ExpressibleByRawBits, RawBitsConvertible {
    public init(bits: RawBits) throws {
        let data = if bits.data.count < 4 {
            bits.data + Data([UInt8](repeating: 0, count: 4 - bits.data.count))
        } else {
            bits.data
        }
        self = try data.withParserSpan { span in
            try UInt32(parsingBigEndian: &span)
        }
    }

    public func toRawBits(bitCount: Int) throws -> RawBits {
        RawBits(data: withUnsafeBytes(of: bigEndian) { Data($0) }, size: bitCount)
    }
}
