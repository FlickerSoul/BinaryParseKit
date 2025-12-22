//
//  EnumParseUtils.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/7/25.
//
import BinaryParsing

/// Matches the given bytes in the input parser span.
/// - Warning: This function is used by `@ParseEnum` macro and should not be used directly.
@inlinable
public func __match(_ bytes: borrowing [UInt8], in input: inout BinaryParsing.ParserSpan) -> Bool {
    if bytes.isEmpty { return true }

    do {
        try input._checkCount(minimum: bytes.count)
    } catch {
        return false
    }

    let toMatch = unsafe input.bytes.extracting(first: bytes.count).withUnsafeBytes(Array.init)
    return toMatch == bytes
}

/// Matches when the remaining bytes in the input parser span equals the specified length.
/// - Warning: This function is used by `@ParseEnum` macro and should not be used directly.
@inlinable
public func __matchLength(length: Int, in input: borrowing BinaryParsing.ParserSpan) -> Bool {
    input.count == length
}

/// Asserts that the given type conforms to `Parsable`.
/// - Warning: This function is used to `@parse` macro and should not be used directly.
@inlinable
public func __assertParsable(_: (some Parsable).Type) {}

/// Asserts that the given type conforms to `SizedParsable`.
/// - Warning: This function is used to `@parse` macro and should not be used directly.
@inlinable
public func __assertSizedParsable(_: (some SizedParsable).Type) {}

/// Asserts that the given type conforms to `EndianParsable`.
/// - Warning: This function is used to `@parse` macro and should not be used directly.
@inlinable
public func __assertEndianParsable(_: (some EndianParsable).Type) {}

/// Asserts that the given type conforms to `EndianSizedParsable`.
/// - Warning: This function is used to `@parse` macro and should not be used directly.
@inlinable
public func __assertEndianSizedParsable(_: (some EndianSizedParsable).Type) {}
