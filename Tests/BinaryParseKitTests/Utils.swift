//
//  Utils.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 1/8/26.
//
import BinaryParsing
import Foundation

extension FixedWidthInteger {
    func withParserSpan<T, E>(_ body: @escaping (inout ParserSpan) throws(E) -> T) rethrows -> T {
        try withUnsafeBytes(of: bigEndian) { buffer in
            try Data(buffer).withParserSpan(body)
        }
    }
}
