//
//  Matchable+RawRepresentable.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/8/25.
//

import BinaryParseKit

extension Matchable where Self: RawRepresentable, Self.RawValue == UInt16 {
    func bytesToMatch() -> [UInt8] {
        [
            UInt8((rawValue & 0xFF00) >> 8),
            UInt8(rawValue & 0x00FF),
        ]
    }
}
