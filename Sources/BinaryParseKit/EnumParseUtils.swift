//
//  EnumParseUtils.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/7/25.
//
import BinaryParsing

/// Matches the given bytes in the input parser span.
/// - Warning: This function is used to `@parseEnum` macro and should not be used directly.
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

/// - Warning: This function is used to `@parse` macro and should not be used directly.
@inlinable
public func __assertParsable(_: (some Parsable).Type) {}

/// - Warning: This function is used to `@parse` macro and should not be used directly.
@inlinable
public func __assertSizedParsable(_: (some SizedParsable).Type) {}

/// - Warning: This function is used to `@parse` macro and should not be used directly.
@inlinable
public func __assertEndianParsable(_: (some EndianParsable).Type) {}

/// - Warning: This function is used to `@parse` macro and should not be used directly.
@inlinable
public func __assertEndianSizedParsable(_: (some EndianSizedParsable).Type) {}
