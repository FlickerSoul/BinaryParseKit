//
//  BinaryParseKitEnumTests.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 7/26/25.
//
@testable import BinaryParseKitMacros
import SwiftSyntaxMacrosGenericTestSupport
import Testing

extension BinaryParseKitMacroTests {
    @Suite
    struct `Test Parsing Enum` { // swiftlint:disable:this type_name type_body_length
        @Test
        func `parse regular enum`() {
            assertMacroExpansion(
                """
                @ParseEnum
                public enum TestEnum {
                    @match(byte: 0x08)
                    case a

                    @match(bytes: [0x01, 0x02])
                    case b
                }
                """,
                expandedSource: #"""
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
                """#,
            )
        }

        @Test
        func `parse RawRepresentable enum by matching bytes`() {
            assertMacroExpansion(
                """
                @ParseEnum
                enum TestEnum: UInt8 {
                    @match(bytes: [0x02, 0x03])
                    case a

                    @match(byte: 0x01)
                    case b
                }
                """,
                expandedSource: #"""
                enum TestEnum: UInt8 {
                    case a
                    case b
                }

                extension TestEnum: BinaryParseKit.Parsable {
                    init(parsing span: inout BinaryParsing.ParserSpan) throws(BinaryParsing.ThrownParsingError) {
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
                """#,
            )
        }

        /// Test parsing RawRepresentable enum by matching raw value directly
        @Test
        func `parse RawRepresentable enum by matching types`() {
            assertMacroExpansion(
                """
                @ParseEnum
                enum TestEnum: UInt8 {
                    @match
                    case a

                    @match
                    case b
                }
                """,
                expandedSource: #"""
                enum TestEnum: UInt8 {
                    case a
                    case b
                }

                extension TestEnum: BinaryParseKit.Parsable {
                    init(parsing span: inout BinaryParsing.ParserSpan) throws(BinaryParsing.ThrownParsingError) {
                        if BinaryParseKit.__match((TestEnum.a as any MatchableRawRepresentable) .bytesToMatch(), in: &span) {
                            self = .a
                            return
                        }
                        if BinaryParseKit.__match((TestEnum.b as any MatchableRawRepresentable) .bytesToMatch(), in: &span) {
                            self = .b
                            return
                        }
                        throw BinaryParseKit.BinaryParserKitError.failedToParse("Failed to find a match for TestEnum, at \(span.startPosition)")
                    }
                }
                """#,
            )
        }

        @Test
        func `enum with associated value`() {
            assertMacroExpansion(
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
                    @parse(endianness: .little)
                    case c(code: UInt8, value: SomeType)
                }
                """,
                expandedSource: #"""
                enum TestEnum {
                    case a(SomeType)
                    case b(Int, value: SomeType)
                    case c(code: UInt8, value: SomeType)
                }

                extension TestEnum: BinaryParseKit.Parsable {
                    init(parsing span: inout BinaryParsing.ParserSpan) throws(BinaryParsing.ThrownParsingError) {
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
                """#,
            )
        }

        @Test
        func `enum with match and take`() {
            assertMacroExpansion(
                """
                @ParseEnum
                enum TestEnum {
                    @matchAndTake(byte: 0x01)
                    case a
                    @match(bytes: [0x02, 0x03])
                    case b
                }
                """,
                expandedSource: #"""
                enum TestEnum {
                    case a
                    case b
                }

                extension TestEnum: BinaryParseKit.Parsable {
                    init(parsing span: inout BinaryParsing.ParserSpan) throws(BinaryParsing.ThrownParsingError) {
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
                """#,
            )
        }

        @Test
        func `enum with match default`() {
            assertMacroExpansion(
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
                """,
                expandedSource: #"""
                enum TestEnum {
                    case a
                    case b
                    case c
                }

                extension TestEnum: BinaryParseKit.Parsable {
                    init(parsing span: inout BinaryParsing.ParserSpan) throws(BinaryParsing.ThrownParsingError) {
                        if BinaryParseKit.__match([0x01], in: &span) {
                            try span.seek(toRelativeOffset: [0x01].count)
                            self = .a
                            return
                        }
                        if BinaryParseKit.__match([0x02, 0x03], in: &span) {
                            self = .b
                            return
                        }
                        if BinaryParseKit.__match([], in: &span) {
                            self = .c
                            return
                        }
                        throw BinaryParseKit.BinaryParserKitError.failedToParse("Failed to find a match for TestEnum, at \(span.startPosition)")
                    }
                }
                """#,
            )
        }

        @Test
        func `enum with too many parse skip`() {
            assertMacroExpansion(
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
                """,
                expandedSource: """
                enum TestEnum {
                    case a
                    case b
                    case c(Int)
                    case d(Int)
                    case e(Int, Int), f(Int)
                }
                """,
                diagnostics: [
                    .init(
                        diagnostic: ParseEnumMacroError.macrosMoreThanCaseArguments,
                        line: 4,
                        column: 5,
                        notes: [
                            .init(
                                note: MacrosMoreThanCaseArgumentsNote(enumCase: "a"),
                                line: 6,
                                column: 10,
                            ),
                        ],
                    ),
                    .init(
                        diagnostic: ParseEnumMacroError.macrosMoreThanCaseArguments,
                        line: 5,
                        column: 5,
                        notes: [
                            .init(
                                note: MacrosMoreThanCaseArgumentsNote(enumCase: "a"),
                                line: 6,
                                column: 10,
                            ),
                        ],
                    ),
                    .init(
                        diagnostic: ParseEnumMacroError.macrosMoreThanCaseArguments,
                        line: 8,
                        column: 5,
                        notes: [
                            .init(
                                note: MacrosMoreThanCaseArgumentsNote(enumCase: "b"),
                                line: 9,
                                column: 10,
                            ),
                        ],
                    ),
                    .init(
                        diagnostic: ParseEnumMacroError.macrosMoreThanCaseArguments,
                        line: 12,
                        column: 5,
                        notes: [
                            .init(
                                note: MacrosMoreThanCaseArgumentsNote(enumCase: "c(Int)"),
                                line: 14,
                                column: 10,
                            ),
                        ],
                    ),
                    .init(
                        diagnostic: ParseEnumMacroError.macrosMoreThanCaseArguments,
                        line: 13,
                        column: 5,
                        notes: [
                            .init(
                                note: MacrosMoreThanCaseArgumentsNote(enumCase: "c(Int)"),
                                line: 14,
                                column: 10,
                            ),
                        ],
                    ),
                    .init(
                        diagnostic: ParseEnumMacroError.macrosMoreThanCaseArguments,
                        line: 21,
                        column: 5,
                        notes: [
                            .init(
                                note: MacrosMoreThanCaseArgumentsNote(enumCase: "f(Int)"),
                                line: 23,
                                column: 23,
                            ),
                        ],
                    ),
                    .init(
                        diagnostic: ParseEnumMacroError.macrosMoreThanCaseArguments,
                        line: 22,
                        column: 5,
                        notes: [
                            .init(
                                note: MacrosMoreThanCaseArgumentsNote(enumCase: "f(Int)"),
                                line: 23,
                                column: 23,
                            ),
                        ],
                    ),
                    validationFailedDiagnostic,
                ],
            )
        }

        @Test
        func `enum with too few parse and skip`() {
            assertMacroExpansion(
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
                """,
                expandedSource: """
                enum TestEnum {
                    case a(Int)
                    case b(Int)
                    case c(Int, value: SomeType)
                    case d(Int), e(Int, Int)
                }
                """,
                diagnostics: [
                    .init(
                        diagnostic: ParseEnumMacroError.caseArgumentsMoreThanMacros,
                        line: 5,
                        column: 12,
                    ),
                    .init(
                        diagnostic: ParseEnumMacroError.caseArgumentsMoreThanMacros,
                        line: 7,
                        column: 12,
                    ),
                    .init(
                        diagnostic: ParseEnumMacroError.caseArgumentsMoreThanMacros,
                        line: 10,
                        column: 17,
                    ),
                    .init(
                        diagnostic: ParseEnumMacroError.caseArgumentsMoreThanMacros,
                        line: 13,
                        column: 25,
                    ),
                    validationFailedDiagnostic,
                ],
            )
        }

        @Test
        func `enum with match(Default) after matchDefault`() {
            assertMacroExpansion(
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
                """,
                expandedSource: """
                enum TestEnum {
                    case a
                    case b
                    case c
                    case d
                }
                """,
                diagnostics: [
                    .init(
                        diagnostic: ParseEnumMacroError.defaultCaseMustBeLast,
                        line: 5,
                        column: 5,
                    ),
                    .init(
                        diagnostic: ParseEnumMacroError.defaultCaseMustBeLast,
                        line: 7,
                        column: 5,
                    ),
                    .init(
                        diagnostic: ParseEnumMacroError.onlyOneMatchDefaultAllowed,
                        line: 9,
                        column: 5,
                    ),
                    validationFailedDiagnostic,
                ],
            )
        }

        @Test
        func `enum with parse/skip before match`() {
            assertMacroExpansion(
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
                """,
                expandedSource: """
                enum TestEnum {
                    case a(Int, Int)
                    case b(Int, Int)
                    case c(Int)
                }
                """,
                diagnostics: [
                    .init(
                        diagnostic: ParseEnumMacroError.matchMustProceedParseAndSkip,
                        line: 4,
                        column: 5,
                    ),
                    .init(
                        diagnostic: ParseEnumMacroError.matchMustProceedParseAndSkip,
                        line: 10,
                        column: 5,
                    ),
                    .init(
                        diagnostic: ParseEnumMacroError.matchMustProceedParseAndSkip,
                        line: 15,
                        column: 5,
                    ),
                    validationFailedDiagnostic,
                ],
            )
        }

        @Test
        func `macro ParseEnum not used with enum`() {
            assertMacroExpansion(
                """
                @ParseEnum
                struct Test {
                }
                """,
                expandedSource: """
                struct Test {
                }
                """,
                diagnostics: [
                    .init(
                        diagnostic: ParseEnumMacroError.onlyEnumsAreSupported,
                        line: 1,
                        column: 1,
                    ),
                ],
            )
        }

        @Test
        func `enum case missing match macro`() {
            assertMacroExpansion(
                """
                @ParseEnum
                enum TestEnum {
                    case a
                    @match(byte: 0x01)
                    case b
                }
                """,
                expandedSource: """
                enum TestEnum {
                    case a
                    case b
                }
                """,
                diagnostics: [
                    .init(
                        diagnostic: ParseEnumMacroError.missingCaseMatchMacro,
                        line: 3,
                        column: 5,
                    ),
                    validationFailedDiagnostic,
                ],
            )
        }

        @Test
        func `no comments in code generation`() {
            assertMacroExpansion("""
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
            """, expandedSource: #"""
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
                init(parsing span: inout BinaryParsing.ParserSpan) throws(BinaryParsing.ThrownParsingError) {
                    if BinaryParseKit.__match((TestEnum.a as any MatchableRawRepresentable) .bytesToMatch(), in: &span) {
                        // Parse `value` of type Int
                        BinaryParseKit.__assertParsable((Int).self)
                        let value = try Int(parsing: &span)
                        // construct `a` with above associated values
                        self = .a(value: value)
                        return
                    }
                    if BinaryParseKit.__match((TestEnum.b as any MatchableRawRepresentable) .bytesToMatch(), in: &span) {
                        // Parse `value` of type Int
                        BinaryParseKit.__assertParsable((Int).self)
                        let value = try Int(parsing: &span)
                        // construct `b` with above associated values
                        self = .b(value: value)
                        return
                    }
                    if BinaryParseKit.__match((TestEnum.c as any MatchableRawRepresentable) .bytesToMatch(), in: &span) {
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
            """#)
        }
    }
}

// MARK: - Diagnostics

private let validationFailedDiagnosticMessage = ParseEnumMacroError
    .unexpectedError(description: "Enum macro parsing encountered errors")
private nonisolated(unsafe) let validationFailedDiagnostic = DiagnosticSpec(
    diagnostic: validationFailedDiagnosticMessage,
    line: 1,
    column: 1,
)
