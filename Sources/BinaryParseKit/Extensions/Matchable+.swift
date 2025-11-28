//
//  Matchable+.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/28/25.
//

public extension Matchable where Self: RawRepresentable, Self.RawValue == UInt8 {
    func bytesToMatch() -> [UInt8] {
        [rawValue]
    }
}

/// Default implementation of `bytesToMatch()` for ``Matchable`` where it's also a `RawRepresentable` and its `RawValue`
/// conforms to `Matchable`.
public extension Matchable where Self: RawRepresentable, Self.RawValue: Matchable {
    /// Returns `rawValue`'s `bytesToMatch()`.
    func bytesToMatch() -> [UInt8] {
        rawValue.bytesToMatch()
    }
}
