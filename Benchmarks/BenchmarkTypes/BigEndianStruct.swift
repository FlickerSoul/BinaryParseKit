//
//  BigEndianStruct.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 1/6/26.
//

import BinaryParseKit
import BinaryParsing
import Foundation

@ParseStruct
public struct BigEndianStruct: Equatable, Sendable, BaselineParsable {
    @parse(endianness: .big)
    public let value1: UInt32

    @parse(endianness: .big)
    public let value2: UInt32

    /// Baseline parsing - direct big-endian parsing without bound checking
    @inline(__always)
    public static func parseBaseline(_ data: Data) -> BigEndianStruct {
        data.withUnsafeBytes { ptr in
            let value1 = UInt32(bigEndian: ptr.load(fromByteOffset: 0, as: UInt32.self))
            let value2 = UInt32(bigEndian: ptr.load(fromByteOffset: 4, as: UInt32.self))
            return BigEndianStruct(value1: value1, value2: value2)
        }
    }
}
