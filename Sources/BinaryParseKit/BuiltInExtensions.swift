//
//  Extensions.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 7/16/25.
//
import BinaryParsing
import Foundation

extension UInt8: @retroactive ExpressibleByParsing {}
extension UInt8: EndianSizedParsable {}
extension UInt16: EndianSizedParsable, EndianParsable {}
extension UInt32: EndianSizedParsable, EndianParsable {}
extension UInt: EndianSizedParsable {}
extension UInt64: EndianSizedParsable, EndianParsable {}

extension Int8: EndianSizedParsable {}
extension Int16: EndianSizedParsable, EndianParsable {}
extension Int32: EndianSizedParsable, EndianParsable {}
extension Int: EndianSizedParsable {}
extension Int64: EndianSizedParsable, EndianParsable {}

extension Data: SizedParsable {}

public extension MatchableRawRepresentable where Self.RawValue == UInt8 {
    func bytesToMatch() -> [UInt8] {
        [rawValue]
    }
}
