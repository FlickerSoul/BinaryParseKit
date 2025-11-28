//
//  BitmaskParsable.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/28/25.
//
import BinaryParsing

public enum BitmaskParsableError: Error {
    case unsupportedBitCount
}

public protocol BitmaskParsable: Parsable, SizedParsable, ExpressibleByBitmask {
    static var bitCount: Int { get }
    static var endianness: Endianness? { get }
}

public protocol ExpressibleByBitmask: OptionSet where RawValue: BinaryInteger & BitwiseCopyable {
    init(bitmask: RawValue) throws(BitmaskParsableError)
}

public extension ExpressibleByBitmask {
    init(bitmask: RawValue) throws(BitmaskParsableError) {
        self.init(rawValue: bitmask)
    }
}
