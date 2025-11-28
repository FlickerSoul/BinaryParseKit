//
//  Matchable.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/11/25.
//

/// A protocol for types that can provide a sequence of bytes for matching purposes.
public protocol Matchable {
    func bytesToMatch() -> [UInt8]
}
