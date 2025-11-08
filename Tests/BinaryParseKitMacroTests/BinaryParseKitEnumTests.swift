//
//  BinaryParseKitEnumTests.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 7/26/25.
//

import Testing

extension BinaryParseKitMacroTests {
    @Suite
    struct `Test Parsing Enum` { // swiftlint:disable:this type_name
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
                        if BinaryParseKit.__match([TestEnum.a.rawValue], in: &span) {
                            self = .a
                            return
                        }
                        if BinaryParseKit.__match([TestEnum.b.rawValue], in: &span) {
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
        func `enum With Associated Value`() {
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
                            BinaryParseKit.__assertSizedParsable(SomeType.self)
                            let __macro_local_12TestEnum_a_0fMu_ = try SomeType(parsing: &span, byteCount: 1)
                            // construct `a` with above associated values
                            self = .a(__macro_local_12TestEnum_a_0fMu_)
                            return
                        }
                        if BinaryParseKit.__match([0x01, 0x02], in: &span) {
                            // Parse `__macro_local_12TestEnum_b_0fMu_` of type Int
                            BinaryParseKit.__assertParsable(Int.self)
                            let __macro_local_12TestEnum_b_0fMu_ = try Int(parsing: &span)
                            // Parse `value` of type SomeType with endianness
                            BinaryParseKit.__assertEndianParsable(SomeType.self)
                            let value = try SomeType(parsing: &span, endianness: .big)
                            // construct `b` with above associated values
                            self = .b(__macro_local_12TestEnum_b_0fMu_, value: value)
                            return
                        }
                        if BinaryParseKit.__match([0x09], in: &span) {
                            // Parse `code` of type UInt8 with endianness
                            BinaryParseKit.__assertEndianParsable(UInt8.self)
                            let code = try UInt8(parsing: &span, endianness: .little)
                            // Parse `value` of type SomeType with endianness
                            BinaryParseKit.__assertEndianParsable(SomeType.self)
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
    }
}
