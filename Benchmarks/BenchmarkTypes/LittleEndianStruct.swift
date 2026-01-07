//
//  LittleEndianStruct.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 1/6/26.
//

import BinaryParseKit
import BinaryParsing
import Foundation

@ParseStruct
public struct LittleEndianStruct: Equatable, Sendable, BaselineParsable {
    @parse(endianness: .little)
    public let value1: UInt32

    @parse(endianness: .little)
    public let value2: UInt32

    /// Baseline parsing - direct little-endian parsing without bound checking
    @inline(__always)
    public static func parseBaseline(_ data: Data) -> LittleEndianStruct {
        data.withUnsafeBytes { ptr in
            let value1 = UInt32(littleEndian: ptr.load(fromByteOffset: 0, as: UInt32.self))
            let value2 = UInt32(littleEndian: ptr.load(fromByteOffset: 4, as: UInt32.self))
            return LittleEndianStruct(value1: value1, value2: value2)
        }
    }
}
