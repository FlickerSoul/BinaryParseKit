//
//  UInt16+.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 1/6/26.
//
import BinaryParseKit
import Foundation

extension UInt16: ExpressibleByRawBits {
    public typealias RawBitsInteger = UInt16

    public init(bits: RawBitsInteger) throws {
        self = bits
    }
}

extension UInt16: RawBitsConvertible {
    public func toRawBits(bitCount: Int) throws -> RawBits {
        RawBits(data: withUnsafeBytes(of: bigEndian) { Data($0) }, size: bitCount)
    }
}
