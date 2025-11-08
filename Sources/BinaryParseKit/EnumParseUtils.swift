//
//  EnumParseUtils.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/7/25.
//
import BinaryParsing

/// - Warning: This function is used to `@parseEnum` macro and should not be used directly.
@inlinable
public func __match(_ bytes: [UInt8], in input: inout BinaryParsing.ParserSpan) -> Bool {
    // FIXME: right now, it's all `matchAndTake` semantic, implement a peak on ParserSpan??
    (try? input.atomically { span in
        let toMatchSpan = try span.sliceSpan(byteCount: bytes.count)
        let toMatch: [UInt8] = unsafe toMatchSpan.withUnsafeBytes(Array.init)
        if toMatch == bytes {
            return true
        } else {
            throw BinaryParserKitError.failedToParse("Expected bytes \(bytes), found \(toMatch)")
        }
    }) ?? false
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
