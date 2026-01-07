//
//  BenchmarkEnumSimple.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 1/6/26.
//

import BinaryParseKit
import BinaryParsing
import Foundation

@ParseEnum
public enum BenchmarkEnumSimple: Equatable, Sendable, BaselineParsable {
    @match(byte: 0x01)
    case first

    @match(byte: 0x02)
    case second

    @match(byte: 0x03)
    case third

    /// Baseline parsing - direct byte match without bound checking
    @inline(__always)
    public static func parseBaseline(_ data: Data) -> BenchmarkEnumSimple {
        let byte = data[data.startIndex]
        switch byte {
        case 0x01: return .first
        case 0x02: return .second
        case 0x03: return .third
        default: fatalError("Invalid byte")
        }
    }
}
