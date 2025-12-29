//
//  BinaryParseKitEnumTests.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 7/26/25.
//
import BinaryParseKitCommons
@testable import BinaryParseKitMacros
import MacroTesting
import SwiftSyntaxMacrosGenericTestSupport
import Testing

// swiftlint:disable file_length line_length
extension BinaryParseKitMacroTests {
    @Suite
    struct `Test Parsing Enum` { // swiftlint:disable:this type_body_length
        @Test
        func `parse regular enum`() {
            assertMacro {
                """
                @ParseEnum
                public enum TestEnum {
                    @match(byte: 0x08)
                    case a

                    @match(bytes: [0x01, 0x02])
                    case b
                }
                """
            } expansion: {
                #"""
                public enum TestEnum {
                    case a
                    case b
                }

                extension TestEnum: BinaryParseKit.Parsable {
                    public init(parsing span: inout BinaryParsing.ParserSpan) throws(BinaryParsing.ThrownParsingError) {
                        if BinaryParseKit.__match([0x08], in: &span) {
                            self = .a
                            return
                        }
                        if BinaryParseKit.__match([0x01, 0x02], in: &span) {
                            self = .b
                            return
                        }
                        throw BinaryParseKit.BinaryParserKitError.failedToParse("Failed to find a match for TestEnum, at \(span.startPosition)")
                    }
                }

                extension TestEnum: BinaryParseKit.Printable {
                    public func printerIntel() throws -> PrinterIntel {
                        switch self {
                        case .a:
                            let __macro_local_20bytesTakenInMatchingfMu_: [UInt8] = [0x08]
                            return .enum(
                                .init(
                                    bytes: __macro_local_20bytesTakenInMatchingfMu_,
                                    parseType: .match,
                                    fields: [],
                                )
                            )
                        case .b:
                            let __macro_local_20bytesTakenInMatchingfMu0_: [UInt8] = [0x01, 0x02]
                            return .enum(
                                .init(
                                    bytes: __macro_local_20bytesTakenInMatchingfMu0_,
                                    parseType: .match,
                                    fields: [],
                                )
                            )
                        }
                    }
                }
                """#
            }
        }

        @Test
        func `parse RawRepresentable enum by matching bytes`() {
            assertMacro {
                """
                @ParseEnum
                enum TestEnum: UInt8 {
                    @match(bytes: [0x02, 0x03])
                    case a

                    @match(byte: 0x01)
                    case b
                }
                """
            } expansion: {
                #"""
                enum TestEnum: UInt8 {
                    case a
                    case b
                }

                extension TestEnum: BinaryParseKit.Parsable {
                    internal init(parsing span: inout BinaryParsing.ParserSpan) throws(BinaryParsing.ThrownParsingError) {
                        if BinaryParseKit.__match([0x02, 0x03], in: &span) {
                            self = .a
                            return
                        }
                        if BinaryParseKit.__match([0x01], in: &span) {
                            self = .b
                            return
                        }
                        throw BinaryParseKit.BinaryParserKitError.failedToParse("Failed to find a match for TestEnum, at \(span.startPosition)")
                    }
                }

                extension TestEnum: BinaryParseKit.Printable {
                    internal func printerIntel() throws -> PrinterIntel {
                        switch self {
                        case .a:
                            let __macro_local_20bytesTakenInMatchingfMu_: [UInt8] = [0x02, 0x03]
                            return .enum(
                                .init(
                                    bytes: __macro_local_20bytesTakenInMatchingfMu_,
                                    parseType: .match,
                                    fields: [],
                                )
                            )
                        case .b:
                            let __macro_local_20bytesTakenInMatchingfMu0_: [UInt8] = [0x01]
                            return .enum(
                                .init(
                                    bytes: __macro_local_20bytesTakenInMatchingfMu0_,
                                    parseType: .match,
                                    fields: [],
                                )
                            )
                        }
                    }
                }
                """#
            }
        }

        /// Test parsing RawRepresentable enum by matching raw value directly
        @Test
        func `parse RawRepresentable enum by matching types`() {
            assertMacro {
                """
                @ParseEnum
                enum TestEnum: UInt8 {
                    @match
                    case a

                    @match
                    case b
                }
                """
            } expansion: {
                #"""
                enum TestEnum: UInt8 {
                    case a
                    case b
                }

                extension TestEnum: BinaryParseKit.Parsable {
                    internal init(parsing span: inout BinaryParsing.ParserSpan) throws(BinaryParsing.ThrownParsingError) {
                        if BinaryParseKit.__match((TestEnum.a as any BinaryParseKit.Matchable).bytesToMatch(), in: &span) {
                            self = .a
                            return
                        }
                        if BinaryParseKit.__match((TestEnum.b as any BinaryParseKit.Matchable).bytesToMatch(), in: &span) {
                            self = .b
                            return
                        }
                        throw BinaryParseKit.BinaryParserKitError.failedToParse("Failed to find a match for TestEnum, at \(span.startPosition)")
                    }
                }

                extension TestEnum: BinaryParseKit.Printable {
                    internal func printerIntel() throws -> PrinterIntel {
                        switch self {
                        case .a:
                            let __macro_local_20bytesTakenInMatchingfMu_: [UInt8] = (TestEnum.a as any BinaryParseKit.Matchable).bytesToMatch()
                            return .enum(
                                .init(
                                    bytes: __macro_local_20bytesTakenInMatchingfMu_,
                                    parseType: .match,
                                    fields: [],
                                )
                            )
                        case .b:
                            let __macro_local_20bytesTakenInMatchingfMu0_: [UInt8] = (TestEnum.b as any BinaryParseKit.Matchable).bytesToMatch()
                            return .enum(
                                .init(
                                    bytes: __macro_local_20bytesTakenInMatchingfMu0_,
                                    parseType: .match,
                                    fields: [],
                                )
                            )
                        }
                    }
                }
                """#
            }
        }

        @Test
        func `enum with associated value`() {
            assertMacro {
                """
                @ParseEnum
                enum TestEnum {
                    @match(byte: 0x08)
                    @parse(byteCount: 1)
                    case a(SomeType)

                    @match(bytes: [0x01, 0x02])
                    @parse
                    @parse(endianness: .big)
                    case b(Int, value: SomeType)

                    @match(byte: 0x09)
                    @parse(endianness: .little)
                    @skip(byteCount: 2, because: "some reason")
                    @parse(endianness: .little)
                    case c(code: UInt8, value: SomeType)
                }
                """
            } expansion: {
                #"""
                enum TestEnum {
                    case a(SomeType)
                    case b(Int, value: SomeType)
                    case c(code: UInt8, value: SomeType)
                }

                extension TestEnum: BinaryParseKit.Parsable {
                    internal init(parsing span: inout BinaryParsing.ParserSpan) throws(BinaryParsing.ThrownParsingError) {
                        if BinaryParseKit.__match([0x08], in: &span) {
                            // Parse `__macro_local_12TestEnum_a_0fMu_` of type SomeType with byte count
                            BinaryParseKit.__assertSizedParsable((SomeType).self)
                            let __macro_local_12TestEnum_a_0fMu_ = try SomeType(parsing: &span, byteCount: 1)
                            // construct `a` with above associated values
                            self = .a(__macro_local_12TestEnum_a_0fMu_)
                            return
                        }
                        if BinaryParseKit.__match([0x01, 0x02], in: &span) {
                            // Parse `__macro_local_12TestEnum_b_0fMu_` of type Int
                            BinaryParseKit.__assertParsable((Int).self)
                            let __macro_local_12TestEnum_b_0fMu_ = try Int(parsing: &span)
                            // Parse `value` of type SomeType with endianness
                            BinaryParseKit.__assertEndianParsable((SomeType).self)
                            let value = try SomeType(parsing: &span, endianness: .big)
                            // construct `b` with above associated values
                            self = .b(__macro_local_12TestEnum_b_0fMu_, value: value)
                            return
                        }
                        if BinaryParseKit.__match([0x09], in: &span) {
                            // Parse `code` of type UInt8 with endianness
                            BinaryParseKit.__assertEndianParsable((UInt8).self)
                            let code = try UInt8(parsing: &span, endianness: .little)
                            // Skip 2 because of "some reason", before parsing `c`
                            try span.seek(toRelativeOffset: 2)
                            // Parse `value` of type SomeType with endianness
                            BinaryParseKit.__assertEndianParsable((SomeType).self)
                            let value = try SomeType(parsing: &span, endianness: .little)
                            // construct `c` with above associated values
                            self = .c(code: code, value: value)
                            return
                        }
                        throw BinaryParseKit.BinaryParserKitError.failedToParse("Failed to find a match for TestEnum, at \(span.startPosition)")
                    }
                }

                extension TestEnum: BinaryParseKit.Printable {
                    internal func printerIntel() throws -> PrinterIntel {
                        switch self {
                        case let .a(__macro_local_9a_index_0fMu_):
                            let __macro_local_20bytesTakenInMatchingfMu_: [UInt8] = [0x08]
                            return .enum(
                                .init(
                                    bytes: __macro_local_20bytesTakenInMatchingfMu_,
                                    parseType: .match,
                                    fields: [.init(byteCount: Swift.Int(1), endianness: nil, intel: try BinaryParseKit.__getPrinterIntel(__macro_local_9a_index_0fMu_))],
                                )
                            )
                        case let .b(__macro_local_9b_index_0fMu_, __macro_local_7b_valuefMu_):
                            let __macro_local_20bytesTakenInMatchingfMu0_: [UInt8] = [0x01, 0x02]
                            return .enum(
                                .init(
                                    bytes: __macro_local_20bytesTakenInMatchingfMu0_,
                                    parseType: .match,
                                    fields: [.init(byteCount: nil, endianness: nil, intel: try BinaryParseKit.__getPrinterIntel(__macro_local_9b_index_0fMu_)), .init(byteCount: nil, endianness: .big, intel: try BinaryParseKit.__getPrinterIntel(__macro_local_7b_valuefMu_))],
                                )
                            )
                        case let .c(__macro_local_6c_codefMu_, __macro_local_7c_valuefMu_):
                            let __macro_local_20bytesTakenInMatchingfMu1_: [UInt8] = [0x09]
                            return .enum(
                                .init(
                                    bytes: __macro_local_20bytesTakenInMatchingfMu1_,
                                    parseType: .match,
                                    fields: [.init(byteCount: nil, endianness: .little, intel: try BinaryParseKit.__getPrinterIntel(__macro_local_6c_codefMu_)), .init(byteCount: Swift.Int(2), endianness: nil, intel: .skip(.init(byteCount: Swift.Int(2)))), .init(byteCount: nil, endianness: .little, intel: try BinaryParseKit.__getPrinterIntel(__macro_local_7c_valuefMu_))],
                                )
                            )
                        }
                    }
                }
                """#
            }
        }

        @Test
        func `enum with match and take`() {
            assertMacro {
                """
                @ParseEnum
                enum TestEnum {
                    @matchAndTake(byte: 0x01)
                    case a
                    @match(bytes: [0x02, 0x03])
                    case b
                }
                """
            } expansion: {
                #"""
                enum TestEnum {
                    case a
                    case b
                }

                extension TestEnum: BinaryParseKit.Parsable {
                    internal init(parsing span: inout BinaryParsing.ParserSpan) throws(BinaryParsing.ThrownParsingError) {
                        if BinaryParseKit.__match([0x01], in: &span) {
                            try span.seek(toRelativeOffset: [0x01].count)
                            self = .a
                            return
                        }
                        if BinaryParseKit.__match([0x02, 0x03], in: &span) {
                            self = .b
                            return
                        }
                        throw BinaryParseKit.BinaryParserKitError.failedToParse("Failed to find a match for TestEnum, at \(span.startPosition)")
                    }
                }

                extension TestEnum: BinaryParseKit.Printable {
                    internal func printerIntel() throws -> PrinterIntel {
                        switch self {
                        case .a:
                            let __macro_local_20bytesTakenInMatchingfMu_: [UInt8] = [0x01]
                            return .enum(
                                .init(
                                    bytes: __macro_local_20bytesTakenInMatchingfMu_,
                                    parseType: .matchAndTake,
                                    fields: [],
                                )
                            )
                        case .b:
                            let __macro_local_20bytesTakenInMatchingfMu0_: [UInt8] = [0x02, 0x03]
                            return .enum(
                                .init(
                                    bytes: __macro_local_20bytesTakenInMatchingfMu0_,
                                    parseType: .match,
                                    fields: [],
                                )
                            )
                        }
                    }
                }
                """#
            }
        }

        @Test
        func `enum with match default`() {
            assertMacro {
                """
                @ParseEnum
                enum TestEnum {
                    @matchAndTake(byte: 0x01)
                    case a
                    @match(bytes: [0x02, 0x03])
                    case b
                    @matchDefault
                    case c
                }
                """
            } expansion: {
                #"""
                enum TestEnum {
                    case a
                    case b
                    case c
                }

                extension TestEnum: BinaryParseKit.Parsable {
                    internal init(parsing span: inout BinaryParsing.ParserSpan) throws(BinaryParsing.ThrownParsingError) {
                        if BinaryParseKit.__match([0x01], in: &span) {
                            try span.seek(toRelativeOffset: [0x01].count)
                            self = .a
                            return
                        }
                        if BinaryParseKit.__match([0x02, 0x03], in: &span) {
                            self = .b
                            return
                        }
                        if true {
                            self = .c
                            return
                        }
                        throw BinaryParseKit.BinaryParserKitError.failedToParse("Failed to find a match for TestEnum, at \(span.startPosition)")
                    }
                }

                extension TestEnum: BinaryParseKit.Printable {
                    internal func printerIntel() throws -> PrinterIntel {
                        switch self {
                        case .a:
                            let __macro_local_20bytesTakenInMatchingfMu_: [UInt8] = [0x01]
                            return .enum(
                                .init(
                                    bytes: __macro_local_20bytesTakenInMatchingfMu_,
                                    parseType: .matchAndTake,
                                    fields: [],
                                )
                            )
                        case .b:
                            let __macro_local_20bytesTakenInMatchingfMu0_: [UInt8] = [0x02, 0x03]
                            return .enum(
                                .init(
                                    bytes: __macro_local_20bytesTakenInMatchingfMu0_,
                                    parseType: .match,
                                    fields: [],
                                )
                            )
                        case .c:
                            let __macro_local_20bytesTakenInMatchingfMu1_: [UInt8] = []
                            return .enum(
                                .init(
                                    bytes: __macro_local_20bytesTakenInMatchingfMu1_,
                                    parseType: .matchDefault,
                                    fields: [],
                                )
                            )
                        }
                    }
                }
                """#
            }
        }

        @Test
        func `enum with too many parse skip`() {
            assertMacro {
                """
                @ParseEnum
                enum TestEnum {
                    @matchAndTake(byte: 0x01)
                    @skip(byteCount: 2, because: "reserved")
                    @parse(byteCount: 4, endianness: .big)
                    case a
                    @matchAndTake(bytes: [0x02, 0x03])
                    @parse(byteCount: 4, endianness: .big)
                    case b
                    @matchAndTake(bytes: [0x02, 0x03])
                    @parse(byteCount: 4, endianness: .big)
                    @skip(byteCount: 2, because: "reserved")
                    @parse(byteCount: 4, endianness: .big)
                    case c(Int)
                    @matchAndTake(bytes: [0x02, 0x03])
                    @skip(byteCount: 2, because: "reserved")
                    @parse(byteCount: 4, endianness: .big)
                    case d(Int)
                    @match
                    @parse(byteCount: 4, endianness: .big)
                    @skip(byteCount: 2, because: "reserved")
                    @parse(byteCount: 4, endianness: .big)
                    case e(Int, Int), f(Int)
                }
                """
            } diagnostics: {
                """
                @ParseEnum
                ┬─────────
                ╰─ 🛑 Unexpected error: Enum macro parsing encountered errors
                enum TestEnum {
                    @matchAndTake(byte: 0x01)
                    @skip(byteCount: 2, because: "reserved")
                    ┬───────────────────────────────────────
                    ╰─ 🛑 There are more parse/skip macros than the number of cases in the enum.
                    @parse(byteCount: 4, endianness: .big)
                    ┬─────────────────────────────────────
                    ╰─ 🛑 There are more parse/skip macros than the number of cases in the enum.
                    case a
                    @matchAndTake(bytes: [0x02, 0x03])
                    @parse(byteCount: 4, endianness: .big)
                    ┬─────────────────────────────────────
                    ╰─ 🛑 There are more parse/skip macros than the number of cases in the enum.
                    case b
                    @matchAndTake(bytes: [0x02, 0x03])
                    @parse(byteCount: 4, endianness: .big)
                    @skip(byteCount: 2, because: "reserved")
                    ┬───────────────────────────────────────
                    ╰─ 🛑 There are more parse/skip macros than the number of cases in the enum.
                    @parse(byteCount: 4, endianness: .big)
                    ┬─────────────────────────────────────
                    ╰─ 🛑 There are more parse/skip macros than the number of cases in the enum.
                    case c(Int)
                    @matchAndTake(bytes: [0x02, 0x03])
                    @skip(byteCount: 2, because: "reserved")
                    @parse(byteCount: 4, endianness: .big)
                    case d(Int)
                    @match
                    @parse(byteCount: 4, endianness: .big)
                    @skip(byteCount: 2, because: "reserved")
                    ┬───────────────────────────────────────
                    ╰─ 🛑 There are more parse/skip macros than the number of cases in the enum.
                    @parse(byteCount: 4, endianness: .big)
                    ┬─────────────────────────────────────
                    ╰─ 🛑 There are more parse/skip macros than the number of cases in the enum.
                    case e(Int, Int), f(Int)
                }
                """
            }
        }

        @Test
        func `enum with too few parse and skip`() {
            assertMacro {
                """
                @ParseEnum
                enum TestEnum {
                    @matchAndTake(byte: 0x01)
                    @skip(byteCount: 2, because: "reserved")
                    case a(Int)
                    @matchAndTake(bytes: [0x02, 0x03])
                    case b(Int)
                    @match
                    @parse
                    case c(Int, value: SomeType)
                    @match
                    @parse
                    case d(Int), e(Int, Int)
                }
                """
            } diagnostics: {
                """
                @ParseEnum
                ┬─────────
                ╰─ 🛑 Unexpected error: Enum macro parsing encountered errors
                enum TestEnum {
                    @matchAndTake(byte: 0x01)
                    @skip(byteCount: 2, because: "reserved")
                    case a(Int)
                           ┬──
                           ╰─ 🛑 The associated values in the enum case exceed the number of parse/skip macros.
                    @matchAndTake(bytes: [0x02, 0x03])
                    case b(Int)
                           ┬──
                           ╰─ 🛑 The associated values in the enum case exceed the number of parse/skip macros.
                    @match
                    @parse
                    case c(Int, value: SomeType)
                                ┬──────────────
                                ╰─ 🛑 The associated values in the enum case exceed the number of parse/skip macros.
                    @match
                    @parse
                    case d(Int), e(Int, Int)
                                        ┬──
                                        ╰─ 🛑 The associated values in the enum case exceed the number of parse/skip macros.
                }
                """
            }
        }

        @Test
        func `enum with match(Default) after matchDefault`() {
            assertMacro {
                """
                @ParseEnum
                enum TestEnum {
                    @matchDefault
                    case a
                    @matchAndTake(byte: 0x01)
                    case b
                    @match(byte: 0x01)
                    case c
                    @matchDefault
                    case d
                }
                """
            } diagnostics: {
                """
                @ParseEnum
                ┬─────────
                ╰─ 🛑 Unexpected error: Enum macro parsing encountered errors
                enum TestEnum {
                    @matchDefault
                    case a
                    @matchAndTake(byte: 0x01)
                    ╰─ 🛑 The `matchDefault` case must be the last case in the enum.
                    case b
                    @match(byte: 0x01)
                    ╰─ 🛑 The `matchDefault` case must be the last case in the enum.
                    case c
                    @matchDefault
                    ╰─ 🛑 Only one `matchDefault` case is allowed in a enum.
                    case d
                }
                """
            }
        }

        @Test
        func `enum with parse/skip before match`() {
            assertMacro {
                """
                @ParseEnum
                enum TestEnum {
                    @parse
                    @match
                    @parse
                    case a(Int, Int)

                    @skip(byteCount: 1, reason: "not used")
                    @parse
                    @matchAndTake(byte: 0x01)
                    @parse
                    case b(Int, Int)

                    @skip(byteCount: 1, reason: "not used")
                    @match(byte: 0x01)
                    @parse
                    case c(Int)
                }
                """
            } diagnostics: {
                """
                @ParseEnum
                ┬─────────
                ╰─ 🛑 Unexpected error: Enum macro parsing encountered errors
                enum TestEnum {
                    @parse
                    @match
                    ┬─────
                    ╰─ 🛑 The `match` macro must proceed all `parse` and `skip` macro.
                    @parse
                    case a(Int, Int)

                    @skip(byteCount: 1, reason: "not used")
                    @parse
                    @matchAndTake(byte: 0x01)
                    ┬────────────────────────
                    ╰─ 🛑 The `match` macro must proceed all `parse` and `skip` macro.
                    @parse
                    case b(Int, Int)

                    @skip(byteCount: 1, reason: "not used")
                    @match(byte: 0x01)
                    ┬─────────────────
                    ╰─ 🛑 The `match` macro must proceed all `parse` and `skip` macro.
                    @parse
                    case c(Int)
                }
                """
            }
        }

        @Test
        func `macro ParseEnum not used with enum`() {
            assertMacro {
                """
                @ParseEnum
                struct Test {
                }
                """
            } diagnostics: {
                """
                @ParseEnum
                ┬─────────
                ╰─ 🛑 Only enums are supported by this macro.
                struct Test {
                }
                """
            }
        }

        @Test
        func `enum case missing match macro`() {
            assertMacro {
                """
                @ParseEnum
                enum TestEnum {
                    case a
                    @match(byte: 0x01)
                    case b
                }
                """
            } diagnostics: {
                """
                @ParseEnum
                ┬─────────
                ╰─ 🛑 Unexpected error: Enum macro parsing encountered errors
                enum TestEnum {
                    case a
                    ┬─────
                    ╰─ 🛑 A `case` declaration must has a `match` macro.
                    @match(byte: 0x01)
                    case b
                }
                """
            }
        }

        @Test
        func `no comments in code generation`() {
            assertMacro {
                """
                @ParseEnum
                enum TestEnum {
                    @match
                    @parse
                    case a(
                        value: Int // some value
                    )

                    @match
                    @parse
                    case b(
                        value:  // some value
                            Int // some value
                    )

                    @match
                    @parse
                    @parse
                    case c(
                        Int, // some value
                        value: // some value
                            Int // some value
                    )
                }
                """
            } expansion: {
                #"""
                enum TestEnum {
                    case a(
                        value: Int // some value
                    )
                    case b(
                        value:  // some value
                            Int // some value
                    )
                    case c(
                        Int, // some value
                        value: // some value
                            Int // some value
                    )
                }

                extension TestEnum: BinaryParseKit.Parsable {
                    internal init(parsing span: inout BinaryParsing.ParserSpan) throws(BinaryParsing.ThrownParsingError) {
                        if BinaryParseKit.__match((TestEnum.a as any BinaryParseKit.Matchable).bytesToMatch(), in: &span) {
                            // Parse `value` of type Int
                            BinaryParseKit.__assertParsable((Int).self)
                            let value = try Int(parsing: &span)
                            // construct `a` with above associated values
                            self = .a(value: value)
                            return
                        }
                        if BinaryParseKit.__match((TestEnum.b as any BinaryParseKit.Matchable).bytesToMatch(), in: &span) {
                            // Parse `value` of type Int
                            BinaryParseKit.__assertParsable((Int).self)
                            let value = try Int(parsing: &span)
                            // construct `b` with above associated values
                            self = .b(value: value)
                            return
                        }
                        if BinaryParseKit.__match((TestEnum.c as any BinaryParseKit.Matchable).bytesToMatch(), in: &span) {
                            // Parse `__macro_local_12TestEnum_c_0fMu_` of type Int
                            BinaryParseKit.__assertParsable((Int).self)
                            let __macro_local_12TestEnum_c_0fMu_ = try Int(parsing: &span)
                            // Parse `value` of type Int
                            BinaryParseKit.__assertParsable((Int).self)
                            let value = try Int(parsing: &span)
                            // construct `c` with above associated values
                            self = .c(__macro_local_12TestEnum_c_0fMu_, value: value)
                            return
                        }
                        throw BinaryParseKit.BinaryParserKitError.failedToParse("Failed to find a match for TestEnum, at \(span.startPosition)")
                    }
                }

                extension TestEnum: BinaryParseKit.Printable {
                    internal func printerIntel() throws -> PrinterIntel {
                        switch self {
                        case let .a(__macro_local_7a_valuefMu_):
                            let __macro_local_20bytesTakenInMatchingfMu_: [UInt8] = (TestEnum.a as any BinaryParseKit.Matchable).bytesToMatch()
                            return .enum(
                                .init(
                                    bytes: __macro_local_20bytesTakenInMatchingfMu_,
                                    parseType: .match,
                                    fields: [.init(byteCount: nil, endianness: nil, intel: try BinaryParseKit.__getPrinterIntel(__macro_local_7a_valuefMu_))],
                                )
                            )
                        case let .b(__macro_local_7b_valuefMu_):
                            let __macro_local_20bytesTakenInMatchingfMu0_: [UInt8] = (TestEnum.b as any BinaryParseKit.Matchable).bytesToMatch()
                            return .enum(
                                .init(
                                    bytes: __macro_local_20bytesTakenInMatchingfMu0_,
                                    parseType: .match,
                                    fields: [.init(byteCount: nil, endianness: nil, intel: try BinaryParseKit.__getPrinterIntel(__macro_local_7b_valuefMu_))],
                                )
                            )
                        case let .c(__macro_local_9c_index_0fMu_, __macro_local_7c_valuefMu_):
                            let __macro_local_20bytesTakenInMatchingfMu1_: [UInt8] = (TestEnum.c as any BinaryParseKit.Matchable).bytesToMatch()
                            return .enum(
                                .init(
                                    bytes: __macro_local_20bytesTakenInMatchingfMu1_,
                                    parseType: .match,
                                    fields: [.init(byteCount: nil, endianness: nil, intel: try BinaryParseKit.__getPrinterIntel(__macro_local_9c_index_0fMu_)), .init(byteCount: nil, endianness: nil, intel: try BinaryParseKit.__getPrinterIntel(__macro_local_7c_valuefMu_))],
                                )
                            )
                        }
                    }
                }
                """#
            }
        }

        struct EnumAccessorTestCase: Codable {
            let arguments: String
            let parsingAccessor: ExtensionAccessor
            let printingAccessor: ExtensionAccessor
        }

        @Test(
            arguments: [
                // String literal
                .init(
                    arguments: #"parsingAccessor: "public", printingAccessor: "public""#,
                    parsingAccessor: .public,
                    printingAccessor: .public,
                ),
                .init(
                    arguments: #"parsingAccessor: "public""#,
                    parsingAccessor: .public,
                    printingAccessor: .internal,
                ),
                .init(
                    arguments: #"printingAccessor: "public""#,
                    parsingAccessor: .internal,
                    printingAccessor: .public,
                ),
                .init(
                    arguments: #"parsingAccessor: "private", printingAccessor: "package""#,
                    parsingAccessor: .private,
                    printingAccessor: .package,
                ),
                // member access
                .init(
                    arguments: #"parsingAccessor: .public, printingAccessor: .public"#,
                    parsingAccessor: .public,
                    printingAccessor: .public,
                ),
                .init(
                    arguments: #"parsingAccessor: .public"#,
                    parsingAccessor: .public,
                    printingAccessor: .internal,
                ),
                .init(
                    arguments: #"printingAccessor: .public"#,
                    parsingAccessor: .internal,
                    printingAccessor: .public,
                ),
                .init(
                    arguments: #"parsingAccessor: .private, printingAccessor: .package"#,
                    parsingAccessor: .private,
                    printingAccessor: .package,
                ),
            ] as [EnumAccessorTestCase],
        )
        func `enum accessor`(testCase: EnumAccessorTestCase) {
            assertMacro {
                """
                // \(testCase.arguments)
                @ParseEnum(\(testCase.arguments))
                enum TestEnum {
                    @match(byte: 0x01)
                    case a

                    @match(byte: 0x02)
                    case b
                }
                """
            } expansion: {
                #"""
                // \#(testCase.arguments)
                enum TestEnum {
                    case a
                    case b
                }

                extension TestEnum: BinaryParseKit.Parsable {
                    \#(testCase.parsingAccessor
                    .description) init(parsing span: inout BinaryParsing.ParserSpan) throws(BinaryParsing.ThrownParsingError) {
                        if BinaryParseKit.__match([0x01], in: &span) {
                            self = .a
                            return
                        }
                        if BinaryParseKit.__match([0x02], in: &span) {
                            self = .b
                            return
                        }
                        throw BinaryParseKit.BinaryParserKitError.failedToParse("Failed to find a match for TestEnum, at \(span.startPosition)")
                    }
                }

                extension TestEnum: BinaryParseKit.Printable {
                    \#(testCase.printingAccessor.description) func printerIntel() throws -> PrinterIntel {
                        switch self {
                        case .a:
                            let __macro_local_20bytesTakenInMatchingfMu_: [UInt8] = [0x01]
                            return .enum(
                                .init(
                                    bytes: __macro_local_20bytesTakenInMatchingfMu_,
                                    parseType: .match,
                                    fields: [],
                                )
                            )
                        case .b:
                            let __macro_local_20bytesTakenInMatchingfMu0_: [UInt8] = [0x02]
                            return .enum(
                                .init(
                                    bytes: __macro_local_20bytesTakenInMatchingfMu0_,
                                    parseType: .match,
                                    fields: [],
                                )
                            )
                        }
                    }
                }
                """#
            }
        }

        @Test
        func `enum bad accessor`() {
            assertMacro {
                """
                @ParseEnum(parsingAccessor: "invalid", printingAccessor: .invalid)
                enum TestEnum {
                    @match(byte: 0x01)
                    case a

                    @match(byte: 0x02)
                    case b
                }
                """
            } diagnostics: {
                """
                @ParseEnum(parsingAccessor: "invalid", printingAccessor: .invalid)
                                                       ┬─────────────────────────
                │          │                           ╰─ 🛑 Invalid ACL value: invalid; Please use one of public, package, internal, fileprivate, private, follow; use it in string literal "public" or enum member access .public.
                           ┬──────────────────────────
                │          ╰─ 🛑 Invalid ACL value: invalid; Please use one of public, package, internal, fileprivate, private, follow; use it in string literal "public" or enum member access .public.
                ┬─────────────────────────────────────────────────────────────────
                ╰─ 🛑 You have used unknown accessor in `@ParseStruct` or `@ParseEnum`.
                enum TestEnum {
                    @match(byte: 0x01)
                    case a

                    @match(byte: 0x02)
                    case b
                }
                """
            }
        }

        @Test
        func `enum with match length`() {
            assertMacro {
                """
                @ParseEnum
                enum VariableSizeData {
                    @match(length: 4)
                    @parse(endianness: .big)
                    case shortPayload(UInt32)

                    @match(length: 8)
                    @parse(endianness: .big)
                    case longPayload(UInt64)

                    @matchDefault
                    case unknown
                }
                """
            } expansion: {
                #"""
                enum VariableSizeData {
                    case shortPayload(UInt32)
                    case longPayload(UInt64)
                    case unknown
                }

                extension VariableSizeData: BinaryParseKit.Parsable {
                    internal init(parsing span: inout BinaryParsing.ParserSpan) throws(BinaryParsing.ThrownParsingError) {
                        if BinaryParseKit.__match(length: 4, in: span) {
                            // Parse `__macro_local_31VariableSizeData_shortPayload_0fMu_` of type UInt32 with endianness
                            BinaryParseKit.__assertEndianParsable((UInt32).self)
                            let __macro_local_31VariableSizeData_shortPayload_0fMu_ = try UInt32(parsing: &span, endianness: .big)
                            // construct `shortPayload` with above associated values
                            self = .shortPayload(__macro_local_31VariableSizeData_shortPayload_0fMu_)
                            return
                        }
                        if BinaryParseKit.__match(length: 8, in: span) {
                            // Parse `__macro_local_30VariableSizeData_longPayload_0fMu_` of type UInt64 with endianness
                            BinaryParseKit.__assertEndianParsable((UInt64).self)
                            let __macro_local_30VariableSizeData_longPayload_0fMu_ = try UInt64(parsing: &span, endianness: .big)
                            // construct `longPayload` with above associated values
                            self = .longPayload(__macro_local_30VariableSizeData_longPayload_0fMu_)
                            return
                        }
                        if true {
                            self = .unknown
                            return
                        }
                        throw BinaryParseKit.BinaryParserKitError.failedToParse("Failed to find a match for VariableSizeData, at \(span.startPosition)")
                    }
                }

                extension VariableSizeData: BinaryParseKit.Printable {
                    internal func printerIntel() throws -> PrinterIntel {
                        switch self {
                        case let .shortPayload(__macro_local_20shortPayload_index_0fMu_):
                            let __macro_local_20bytesTakenInMatchingfMu_: [UInt8] = []
                            return .enum(
                                .init(
                                    bytes: __macro_local_20bytesTakenInMatchingfMu_,
                                    parseType: .match,
                                    fields: [.init(byteCount: nil, endianness: .big, intel: try BinaryParseKit.__getPrinterIntel(__macro_local_20shortPayload_index_0fMu_))],
                                )
                            )
                        case let .longPayload(__macro_local_19longPayload_index_0fMu_):
                            let __macro_local_20bytesTakenInMatchingfMu0_: [UInt8] = []
                            return .enum(
                                .init(
                                    bytes: __macro_local_20bytesTakenInMatchingfMu0_,
                                    parseType: .match,
                                    fields: [.init(byteCount: nil, endianness: .big, intel: try BinaryParseKit.__getPrinterIntel(__macro_local_19longPayload_index_0fMu_))],
                                )
                            )
                        case .unknown:
                            let __macro_local_20bytesTakenInMatchingfMu1_: [UInt8] = []
                            return .enum(
                                .init(
                                    bytes: __macro_local_20bytesTakenInMatchingfMu1_,
                                    parseType: .matchDefault,
                                    fields: [],
                                )
                            )
                        }
                    }
                }
                """#
            }
        }

        @Test
        func `enum with mixed matching strategies`() {
            assertMacro {
                """
                @ParseEnum
                enum Invalid {
                    @match(byte: 0x01)
                    case byteCase

                    @match(length: 4)
                    case lengthCase
                }
                """
            } diagnostics: {
                """
                @ParseEnum
                ┬─────────
                ╰─ 🛑 Unexpected error: Enum macro parsing encountered errors
                enum Invalid {
                    @match(byte: 0x01)
                    case byteCase

                    @match(length: 4)
                    ╰─ 🛑 An enum cannot mix byte-based matching (@match, @match(byte:), @match(bytes:), @matchAndTake) with length-based matching (@match(length:)).
                    case lengthCase
                }
                """
            }
        }

        @Test
        func `enum with mixed matching strategies reverse order`() {
            assertMacro {
                """
                @ParseEnum
                enum Invalid {
                    @match(length: 4)
                    case lengthCase

                    @matchAndTake(byte: 0x01)
                    case byteCase
                }
                """
            } diagnostics: {
                """
                @ParseEnum
                ┬─────────
                ╰─ 🛑 Unexpected error: Enum macro parsing encountered errors
                enum Invalid {
                    @match(length: 4)
                    case lengthCase

                    @matchAndTake(byte: 0x01)
                    ╰─ 🛑 An enum cannot mix byte-based matching (@match, @match(byte:), @match(bytes:), @matchAndTake) with length-based matching (@match(length:)).
                    case byteCase
                }
                """
            }
        }

        @Test
        func `enum with mask associated values`() {
            assertMacro {
                """
                @ParseEnum
                enum TestEnum {
                    @match(byte: 0x01)
                    @mask(bitCount: 1)
                    @mask(bitCount: 7)
                    case flags(Bool, UInt8)

                    @match(byte: 0x02)
                    @parse
                    @mask(bitCount: 4)
                    @mask
                    case mixed(UInt16, value: UInt8, flag: Bool)
                }
                """
            } expansion: {
                #"""
                enum TestEnum {
                    case flags(Bool, UInt8)
                    case mixed(UInt16, value: UInt8, flag: Bool)
                }

                extension TestEnum: BinaryParseKit.Parsable {
                    internal init(parsing span: inout BinaryParsing.ParserSpan) throws(BinaryParsing.ThrownParsingError) {
                        if BinaryParseKit.__match([0x01], in: &span) {
                            // Parse bitmask fields for `flags`
                            let __macro_local_19__bitmask_totalBitsfMu_ = 1 + 7
                            let __macro_local_19__bitmask_byteCountfMu_ = (__macro_local_19__bitmask_totalBitsfMu_ + 7) / 8
                            let __macro_local_14__bitmask_datafMu_ = Data(try span.slicing(first: __macro_local_19__bitmask_byteCountfMu_))
                            try span.seek(toRelativeOffset: __macro_local_19__bitmask_byteCountfMu_)
                            let __macro_local_14__bitmask_bitsfMu_ = BinaryParseKit.RawBits(data: __macro_local_14__bitmask_datafMu_, size: __macro_local_19__bitmask_totalBitsfMu_)
                            var __macro_local_16__bitmask_offsetfMu_ = 0
                            // Parse `__macro_local_16TestEnum_flags_0fMu_` of type Bool from bits
                            BinaryParseKit.__assertExpressibleByRawBits((Bool).self)
                            let __macro_local_16TestEnum_flags_0fMu_ = try BinaryParseKit.__parseFromBits((Bool).self, from: __macro_local_14__bitmask_bitsfMu_, offset: __macro_local_16__bitmask_offsetfMu_, count: 1)
                            __macro_local_16__bitmask_offsetfMu_ += 1
                            // Parse `__macro_local_16TestEnum_flags_1fMu_` of type UInt8 from bits
                            BinaryParseKit.__assertExpressibleByRawBits((UInt8).self)
                            let __macro_local_16TestEnum_flags_1fMu_ = try BinaryParseKit.__parseFromBits((UInt8).self, from: __macro_local_14__bitmask_bitsfMu_, offset: __macro_local_16__bitmask_offsetfMu_, count: 7)
                            __macro_local_16__bitmask_offsetfMu_ += 7
                            // construct `flags` with above associated values
                            self = .flags(__macro_local_16TestEnum_flags_0fMu_, __macro_local_16TestEnum_flags_1fMu_)
                            return
                        }
                        if BinaryParseKit.__match([0x02], in: &span) {
                            // Parse `__macro_local_16TestEnum_mixed_0fMu_` of type UInt16
                            BinaryParseKit.__assertParsable((UInt16).self)
                            let __macro_local_16TestEnum_mixed_0fMu_ = try UInt16(parsing: &span)
                            // Parse bitmask fields for `mixed`
                            let __macro_local_19__bitmask_totalBitsfMu0_ = 4 + (Bool).bitCount
                            let __macro_local_19__bitmask_byteCountfMu0_ = (__macro_local_19__bitmask_totalBitsfMu0_ + 7) / 8
                            let __macro_local_14__bitmask_datafMu0_ = Data(try span.slicing(first: __macro_local_19__bitmask_byteCountfMu0_))
                            try span.seek(toRelativeOffset: __macro_local_19__bitmask_byteCountfMu0_)
                            let __macro_local_14__bitmask_bitsfMu0_ = BinaryParseKit.RawBits(data: __macro_local_14__bitmask_datafMu0_, size: __macro_local_19__bitmask_totalBitsfMu0_)
                            var __macro_local_16__bitmask_offsetfMu0_ = 0
                            // Parse `value` of type UInt8 from bits
                            BinaryParseKit.__assertExpressibleByRawBits((UInt8).self)
                            let value = try BinaryParseKit.__parseFromBits((UInt8).self, from: __macro_local_14__bitmask_bitsfMu0_, offset: __macro_local_16__bitmask_offsetfMu0_, count: 4)
                            __macro_local_16__bitmask_offsetfMu0_ += 4
                            // Parse `flag` of type Bool from bits
                            BinaryParseKit.__assertBitmaskParsable((Bool).self)
                            let flag = try BinaryParseKit.__parseFromBits((Bool).self, from: __macro_local_14__bitmask_bitsfMu0_, offset: __macro_local_16__bitmask_offsetfMu0_, count: (Bool).bitCount)
                            __macro_local_16__bitmask_offsetfMu0_ += (Bool).bitCount
                            // construct `mixed` with above associated values
                            self = .mixed(__macro_local_16TestEnum_mixed_0fMu_, value: value, flag: flag)
                            return
                        }
                        throw BinaryParseKit.BinaryParserKitError.failedToParse("Failed to find a match for TestEnum, at \(span.startPosition)")
                    }
                }

                extension TestEnum: BinaryParseKit.Printable {
                    internal func printerIntel() throws -> PrinterIntel {
                        switch self {
                        case let .flags(__macro_local_13flags_index_0fMu_, __macro_local_13flags_index_1fMu_):
                            let __macro_local_20bytesTakenInMatchingfMu_: [UInt8] = [0x01]
                            return .enum(
                                .init(
                                    bytes: __macro_local_20bytesTakenInMatchingfMu_,
                                    parseType: .match,
                                    fields: [],
                                )
                            )
                        case let .mixed(__macro_local_13mixed_index_0fMu_, __macro_local_11mixed_valuefMu_, __macro_local_10mixed_flagfMu_):
                            let __macro_local_20bytesTakenInMatchingfMu0_: [UInt8] = [0x02]
                            return .enum(
                                .init(
                                    bytes: __macro_local_20bytesTakenInMatchingfMu0_,
                                    parseType: .match,
                                    fields: [.init(byteCount: nil, endianness: nil, intel: try BinaryParseKit.__getPrinterIntel(__macro_local_13mixed_index_0fMu_))],
                                )
                            )
                        }
                    }
                }
                """#
            }
        }

        @Test
        func `enum with alternating parse`() {
            assertMacro {
                """
                @ParseEnum
                enum TestEnum {
                    @match(byte: 0x01)
                    @mask(bitCount: 1)
                    @mask(bitCount: 2)
                    @parse
                    @mask(bitCount: 7)
                    @skip(byteCount: 2, reason: "skip")
                    @mask(bitCount: 4)
                    case flags(Bool, UInt8, UInt8, UInt8, UInt8)
                }
                """
            } expansion: {
                #"""
                enum TestEnum {
                    case flags(Bool, UInt8, UInt8, UInt8, UInt8)
                }

                extension TestEnum: BinaryParseKit.Parsable {
                    internal init(parsing span: inout BinaryParsing.ParserSpan) throws(BinaryParsing.ThrownParsingError) {
                        if BinaryParseKit.__match([0x01], in: &span) {
                            // Parse bitmask fields for `flags`
                            let __macro_local_19__bitmask_totalBitsfMu_ = 1 + 2
                            let __macro_local_19__bitmask_byteCountfMu_ = (__macro_local_19__bitmask_totalBitsfMu_ + 7) / 8
                            let __macro_local_14__bitmask_datafMu_ = Data(try span.slicing(first: __macro_local_19__bitmask_byteCountfMu_))
                            try span.seek(toRelativeOffset: __macro_local_19__bitmask_byteCountfMu_)
                            let __macro_local_14__bitmask_bitsfMu_ = BinaryParseKit.RawBits(data: __macro_local_14__bitmask_datafMu_, size: __macro_local_19__bitmask_totalBitsfMu_)
                            var __macro_local_16__bitmask_offsetfMu_ = 0
                            // Parse `__macro_local_16TestEnum_flags_0fMu_` of type Bool from bits
                            BinaryParseKit.__assertExpressibleByRawBits((Bool).self)
                            let __macro_local_16TestEnum_flags_0fMu_ = try BinaryParseKit.__parseFromBits((Bool).self, from: __macro_local_14__bitmask_bitsfMu_, offset: __macro_local_16__bitmask_offsetfMu_, count: 1)
                            __macro_local_16__bitmask_offsetfMu_ += 1
                            // Parse `__macro_local_16TestEnum_flags_1fMu_` of type UInt8 from bits
                            BinaryParseKit.__assertExpressibleByRawBits((UInt8).self)
                            let __macro_local_16TestEnum_flags_1fMu_ = try BinaryParseKit.__parseFromBits((UInt8).self, from: __macro_local_14__bitmask_bitsfMu_, offset: __macro_local_16__bitmask_offsetfMu_, count: 2)
                            __macro_local_16__bitmask_offsetfMu_ += 2
                            // Parse `__macro_local_16TestEnum_flags_2fMu_` of type UInt8
                            BinaryParseKit.__assertParsable((UInt8).self)
                            let __macro_local_16TestEnum_flags_2fMu_ = try UInt8(parsing: &span)
                            // Parse bitmask fields for `flags`
                            let __macro_local_19__bitmask_totalBitsfMu0_ = 7
                            let __macro_local_19__bitmask_byteCountfMu0_ = (__macro_local_19__bitmask_totalBitsfMu0_ + 7) / 8
                            let __macro_local_14__bitmask_datafMu0_ = Data(try span.slicing(first: __macro_local_19__bitmask_byteCountfMu0_))
                            try span.seek(toRelativeOffset: __macro_local_19__bitmask_byteCountfMu0_)
                            let __macro_local_14__bitmask_bitsfMu0_ = BinaryParseKit.RawBits(data: __macro_local_14__bitmask_datafMu0_, size: __macro_local_19__bitmask_totalBitsfMu0_)
                            var __macro_local_16__bitmask_offsetfMu0_ = 0
                            // Parse `__macro_local_16TestEnum_flags_3fMu_` of type UInt8 from bits
                            BinaryParseKit.__assertExpressibleByRawBits((UInt8).self)
                            let __macro_local_16TestEnum_flags_3fMu_ = try BinaryParseKit.__parseFromBits((UInt8).self, from: __macro_local_14__bitmask_bitsfMu0_, offset: __macro_local_16__bitmask_offsetfMu0_, count: 7)
                            __macro_local_16__bitmask_offsetfMu0_ += 7
                            // Skip 2 because of "skip", before parsing `flags`
                            try span.seek(toRelativeOffset: 2)
                            // Parse bitmask fields for `flags`
                            let __macro_local_19__bitmask_totalBitsfMu1_ = 4
                            let __macro_local_19__bitmask_byteCountfMu1_ = (__macro_local_19__bitmask_totalBitsfMu1_ + 7) / 8
                            let __macro_local_14__bitmask_datafMu1_ = Data(try span.slicing(first: __macro_local_19__bitmask_byteCountfMu1_))
                            try span.seek(toRelativeOffset: __macro_local_19__bitmask_byteCountfMu1_)
                            let __macro_local_14__bitmask_bitsfMu1_ = BinaryParseKit.RawBits(data: __macro_local_14__bitmask_datafMu1_, size: __macro_local_19__bitmask_totalBitsfMu1_)
                            var __macro_local_16__bitmask_offsetfMu1_ = 0
                            // Parse `__macro_local_16TestEnum_flags_4fMu_` of type UInt8 from bits
                            BinaryParseKit.__assertExpressibleByRawBits((UInt8).self)
                            let __macro_local_16TestEnum_flags_4fMu_ = try BinaryParseKit.__parseFromBits((UInt8).self, from: __macro_local_14__bitmask_bitsfMu1_, offset: __macro_local_16__bitmask_offsetfMu1_, count: 4)
                            __macro_local_16__bitmask_offsetfMu1_ += 4
                            // construct `flags` with above associated values
                            self = .flags(__macro_local_16TestEnum_flags_0fMu_, __macro_local_16TestEnum_flags_1fMu_, __macro_local_16TestEnum_flags_2fMu_, __macro_local_16TestEnum_flags_3fMu_, __macro_local_16TestEnum_flags_4fMu_)
                            return
                        }
                        throw BinaryParseKit.BinaryParserKitError.failedToParse("Failed to find a match for TestEnum, at \(span.startPosition)")
                    }
                }

                extension TestEnum: BinaryParseKit.Printable {
                    internal func printerIntel() throws -> PrinterIntel {
                        switch self {
                        case let .flags(__macro_local_13flags_index_0fMu_, __macro_local_13flags_index_1fMu_, __macro_local_13flags_index_2fMu_, __macro_local_13flags_index_3fMu_, __macro_local_13flags_index_5fMu_):
                            let __macro_local_20bytesTakenInMatchingfMu_: [UInt8] = [0x01]
                            return .enum(
                                .init(
                                    bytes: __macro_local_20bytesTakenInMatchingfMu_,
                                    parseType: .match,
                                    fields: [.init(byteCount: nil, endianness: nil, intel: try BinaryParseKit.__getPrinterIntel(__macro_local_13flags_index_2fMu_)), .init(byteCount: Swift.Int(2), endianness: nil, intel: .skip(.init(byteCount: Swift.Int(2))))],
                                )
                            )
                        }
                    }
                }
                """#
            }
        }
    }
}

// swiftlint:enable file_length line_length
