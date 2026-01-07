//
//  BenchmarkEnumComplex.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 1/6/26.
//

import BinaryParseKit
import BinaryParsing
import Foundation

@ParseEnum
public enum BenchmarkEnumComplex: Equatable, Sendable, BaselineParsable {
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

    /// Baseline parsing - direct parsing without bound checking
    @inline(__always)
    public static func parseBaseline(_ data: Data) -> BenchmarkEnumComplex {
        let byte = data[data.startIndex]
        switch byte {
        case 0x01:
            let value = Int16(bigEndian: data.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: 1, as: Int16.self) })
            return .withInt16(value)
        case 0x02:
            let value = UInt32(bigEndian: data.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: 1, as: UInt32.self) })
            return .withUInt32(value)
        case 0x03:
            let arg1 = Int16(bigEndian: data.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: 1, as: Int16.self) })
            let arg2 = UInt16(bigEndian: data.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: 3, as: UInt16.self) })
            return .withTwoValues(arg1, arg2)
        default:
            return .unknown
        }
    }
}
