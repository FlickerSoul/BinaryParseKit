//
//  BenchmarkStructSimple.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 1/6/26.
//

import BinaryParseKit
import BinaryParsing
import Foundation

@ParseStruct
public struct BenchmarkStructSimple: Equatable, Sendable, BaselineParsable {
    @parse(endianness: .big)
    public let value: UInt32

    public init(value: UInt32) {
        self.value = value
    }

    /// Baseline parsing - direct UInt32 big-endian without bound checking
    @inline(__always)
    public static func parseBaseline(_ data: Data) -> BenchmarkStructSimple {
        let value = UInt32(bigEndian: data.withUnsafeBytes { $0.loadUnaligned(as: UInt32.self) })
        return BenchmarkStructSimple(value: value)
    }
}
