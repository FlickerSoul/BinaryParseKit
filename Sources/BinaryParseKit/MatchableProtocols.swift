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

/// Default implementation of `bytesToMatch()` for ``Matchable`` where it's also a `RawRepresentable` and its `RawValue`
/// conforms to `Matchable`.
public extension Matchable where Self: RawRepresentable, Self.RawValue: Matchable {
    /// Returns `rawValue`'s `bytesToMatch()`.
    func bytesToMatch() -> [UInt8] {
        rawValue.bytesToMatch()
    }
}
