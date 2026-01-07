//
//  BenchmarkStructComplex.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 1/6/26.
//

import BinaryParseKit
import BinaryParsing
import Foundation

@ParseStruct
public struct BenchmarkStructComplex: Equatable, Sendable, BaselineParsable {
    @parse(byteCount: 4, endianness: .big)
    public let magic: UInt32

    @skip(byteCount: 2, because: "reserved")
    @parse(byteCount: 2, endianness: .little)
    public let version: UInt16

    @parse(endianness: .big)
    public let timestamp: UInt64

    @parse(endianness: .little)
    public let flags: UInt16

    public init(magic: UInt32, version: UInt16, timestamp: UInt64, flags: UInt16) {
        self.magic = magic
        self.version = version
        self.timestamp = timestamp
        self.flags = flags
    }

    /// Baseline parsing - direct multi-field parsing without bound checking
    @inline(__always)
    public static func parseBaseline(_ data: Data) -> BenchmarkStructComplex {
        data.withUnsafeBytes { ptr in
            let magic = UInt32(bigEndian: ptr.load(fromByteOffset: 0, as: UInt32.self))
            // Skip 2 bytes at offset 4-5
            let version = UInt16(littleEndian: ptr.load(fromByteOffset: 6, as: UInt16.self))
            let timestamp = UInt64(bigEndian: ptr.load(fromByteOffset: 8, as: UInt64.self))
            let flags = UInt16(littleEndian: ptr.load(fromByteOffset: 16, as: UInt16.self))
            return BenchmarkStructComplex(magic: magic, version: version, timestamp: timestamp, flags: flags)
        }
    }
}
