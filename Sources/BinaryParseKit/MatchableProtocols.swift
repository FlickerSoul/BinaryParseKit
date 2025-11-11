//
//  MatchableProtocols.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/11/25.
//

/// A protocol for types that can provide a sequence of bytes for matching purposes.
public protocol Matchable {
    func bytesToMatch() -> [UInt8]
}

/// A protocol for types that conform to `RawRepresentable` and `Matchable`.
/// It provides a default implementation for `RawRepresentable` whose `RawValue` conforms to `Matchable`.
public protocol MatchableRawRepresentable: RawRepresentable, Matchable {}

/// Default implementation of `bytesToMatch()` for `MatchableRawRepresentable` where `RawValue` conforms to `Matchable`.
public extension MatchableRawRepresentable where Self.RawValue: Matchable {
    /// Returns `rawValue`'s `bytesToMatch()`.
    func bytesToMatch() -> [UInt8] {
        rawValue.bytesToMatch()
    }
}
